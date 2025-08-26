from typing import Optional, List
import io
import uuid
import os
import tempfile

from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi import Header
from fastapi.middleware.cors import CORSMiddleware
from server.seller import router as seller_router
from PIL import Image
from sentence_transformers import SentenceTransformer
import numpy as np
import json
from ast import literal_eval
import os as _os

from server.supabase_client import get_supabase, SupabaseNotConfigured
import httpx
import base64
import json as _json

app = FastAPI()

# Allow local dev frontend and Flutter Web to hit this API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)



class Models:
    clip: Optional[SentenceTransformer] = None


@app.on_event("startup")
def _startup() -> None:
    # Initialize Supabase client at startup so later requests are fast
    try:
        app.state.supabase = get_supabase()
    except SupabaseNotConfigured:
        app.state.supabase = None

    # Lazy load CLIP on first use; here we just assign placeholder
    Models.clip = None


# Register seller routes
app.include_router(seller_router)

@app.get("/")
def read_root():
    return {"status": "ok"}


@app.get("/items/{item_id}")
def read_item(item_id: int, q: Optional[str] = None):
    return {"item_id": item_id, "q": q}


@app.get("/supabase/health")
def supabase_health():
    """Light-weight health endpoint for Supabase client configuration.

    It does not make a network call; it only checks if env is set and client created.
    """
    try:
        client = get_supabase()
        # expose minimal non-sensitive info
        return {"configured": True, "url": client.rest_url}
    except SupabaseNotConfigured as e:
        return {"configured": False, "error": str(e)}


@app.get("/products/")
def list_products():
    client = getattr(app.state, "supabase", None)
    if client is None:
        raise HTTPException(status_code=500, detail="Supabase not configured")
    # Fetch products and left join first image per product via nested select
    # Note: PostgREST doesn't do arbitrary joins; we rely on a view or nested select
    # Here we select products and then fetch first image per product in a second query
    prod_res = client.table("products").select(
        "id,auth_id,name,description,category,brand,price,stock,condition,dimensions,weight_kg,is_featured,is_in_stock,created_at,updated_at,rating").execute()
    if getattr(prod_res, "error", None):
        raise HTTPException(status_code=400, detail=str(prod_res.error))
    prods = prod_res.data or []
    out = []
    for p in prods:
        img_res = client.table("product_images").select("image_url").eq(
            "product_id", p["id"]).order("created_at", desc=False).limit(1).execute()
        image_url = None
        if not getattr(img_res, "error", None) and img_res.data:
            image_url = img_res.data[0].get("image_url")
        obj = dict(p)
        if image_url:
            obj["image_url"] = image_url
        out.append(obj)
    return out


def _get_clip() -> SentenceTransformer:
    if Models.clip is None:
        # OpenAI CLIP ViT-B/32. SentenceTransformers handles image+text.
        Models.clip = SentenceTransformer("clip-ViT-B-32")
    return Models.clip


def _normalize_embedding(vec) -> list:
    # Ensure python list of floats for pgvector insertion
    if hasattr(vec, "tolist"):
        return [float(x) for x in vec.tolist()]
    return [float(x) for x in vec]


def _decode_jwt_sub(authorization: str | None) -> str | None:
    """Best-effort decode of JWT `sub` (user id) from Authorization header.

    This does not verify signature; the server only uses it to associate
    the review with the requester while still requiring a valid-looking token.
    """
    if not authorization or not authorization.lower().startswith("bearer "):
        return None
    token = authorization.split(" ", 1)[1].strip()
    parts = token.split(".")
    if len(parts) < 2:
        return None
    payload_b64 = parts[1]
    # base64url decode with padding
    pad = '=' * (-len(payload_b64) % 4)
    try:
        payload_bytes = base64.urlsafe_b64decode(payload_b64 + pad)
        payload = _json.loads(payload_bytes.decode("utf-8"))
        # Supabase places the user id in `sub`
        sub = payload.get("sub") or payload.get("user_id")
        if isinstance(sub, str) and sub:
            return sub
    except Exception:
        return None
    return None


def _get_user_from_authorization(authorization: str | None) -> str | None:
    """Verify JWT using Supabase and return `sub` if valid; fallback to decode.

    Returns the user id (auth.users.id) or None.
    """
    if not authorization or not authorization.lower().startswith("bearer "):
        return None
    token = authorization.split(" ", 1)[1].strip()
    client = getattr(app.state, "supabase", None)
    if client is not None:
        try:
            claims = client.auth.get_claims(jwt=token)
            # supabase-py may return dict or object with .claims
            data = claims if isinstance(
                claims, dict) else getattr(claims, "claims", None)
            if isinstance(data, dict):
                sub = data.get("sub") or data.get("user_id")
                if isinstance(sub, str) and sub:
                    return sub
        except Exception:
            pass
    # Fallback to insecure local decode
    return _decode_jwt_sub(authorization)


@app.get("/products/search")
def search_products(q: str, limit: int = 24):
    """Vector-based text search over product images.

    - Encodes text `q` using CLIP text encoder
    - Computes cosine similarity vs `product_images.image_vectors`
    - Aggregates by product, keeping the best image score per product
    - Returns product rows with an attached representative `image_url` and `score`
    """
    client = getattr(app.state, "supabase", None)
    if client is None:
        raise HTTPException(status_code=500, detail="Supabase not configured")

    q = (q or "").strip()
    if not q:
        return {"results": []}

    model = _get_clip()
    try:
        qvec = model.encode(q)
    except Exception as e:
        raise HTTPException(
            status_code=400, detail=f"Failed to encode query: {e}")

    import numpy as np  # local import to keep top clean
    q = np.array(qvec, dtype=np.float32)
    q = q / (np.linalg.norm(q) + 1e-9)

    # Fetch all image vectors with product mapping
    res = client.table("product_images").select(
        "product_id,image_url,image_vectors"
    ).execute()
    if getattr(res, "error", None):
        raise HTTPException(status_code=400, detail=str(res.error))
    items = res.data or []

    best_by_product = {}
    for it in items:
        pid = it.get("product_id")
        vec = it.get("image_vectors")
        if not pid or vec is None:
            continue
        if isinstance(vec, str):
            try:
                vec = json.loads(vec)
            except Exception:
                try:
                    vec = literal_eval(vec)
                except Exception:
                    continue
        v = np.array(vec, dtype=np.float32)
        v = v / (np.linalg.norm(v) + 1e-9)
        score = float(np.dot(q, v))
        cur = best_by_product.get(pid)
        if cur is None or score > cur["score"]:
            best_by_product[pid] = {
                "score": score,
                "image_url": it.get("image_url"),
            }

    ranked = sorted(best_by_product.items(),
                    key=lambda kv: kv[1]["score"], reverse=True)
    ranked = ranked[: max(0, int(limit))]
    top_ids = [pid for pid, _ in ranked]
    if not top_ids:
        return {"results": []}

    prod_res = client.table("products").select(
        "id,auth_id,name,description,category,brand,price,stock,condition,dimensions,weight_kg,is_featured,is_in_stock,created_at,updated_at,rating"
    ).in_("id", top_ids).execute()
    if getattr(prod_res, "error", None):
        raise HTTPException(status_code=400, detail=str(prod_res.error))
    prods = prod_res.data or []
    by_id = {str(p["id"]): p for p in prods}

    results = []
    for pid, meta in ranked:
        p = by_id.get(str(pid))
        if not p:
            continue
        obj = dict(p)
        if meta.get("image_url"):
            obj["image_url"] = meta["image_url"]
        obj["score"] = meta["score"]
        results.append(obj)

    return {"results": results}


# ---------------------- REVIEWS API ----------------------

@app.get("/products/{product_id}/reviews")
def get_product_reviews(product_id: str, limit: int | None = None):
    """Return reviews for a product, enriched with basic user profile info and a summary.

    Response:
      {
        "reviews": [
          {"id": ..., "product_id": ..., "user_auth_id": ..., "rating": 5,
           "review": "...", "created_at": "...", "user": {"name": "...", "profile_image": "..."}}
        ],
        "summary": {"count": N, "avg": 4.3}
      }
    """
    client = getattr(app.state, "supabase", None)
    if client is None:
        raise HTTPException(status_code=500, detail="Supabase not configured")

    q = client.table("reviews").select(
        "id,product_id,user_auth_id,rating,review,created_at"
    ).eq("product_id", product_id).order("created_at", desc=True)
    if limit is not None and int(limit) > 0:
        q = q.limit(int(limit))
    res = q.execute()
    if getattr(res, "error", None):
        raise HTTPException(status_code=400, detail=str(res.error))
    rows = res.data or []

    # Summary across ALL reviews for this product (unbounded)
    sum_cnt = client.table("reviews").select(
        "rating").eq("product_id", product_id).execute()
    cnt = 0
    avg = 0.0
    if not getattr(sum_cnt, "error", None):
        ratings = sum_cnt.data or []
        cnt = len(ratings)
        if cnt:
            s = 0
            for r in ratings:
                try:
                    s += int(r.get("rating") or 0)
                except Exception:
                    pass
            avg = float(s) / float(cnt) if cnt else 0.0

    # Enrich with user info from public.users by auth_id
    auth_ids = list({r.get("user_auth_id")
                    for r in rows if r.get("user_auth_id")})
    by_auth: dict[str, dict] = {}
    if auth_ids:
        prof = client.table("users").select(
            "auth_id,name,profile_image").in_("auth_id", auth_ids).execute()
        if not getattr(prof, "error", None):
            for u in (prof.data or []):
                aid = u.get("auth_id")
                if aid:
                    by_auth[str(aid)] = {
                        "name": u.get("name") or "",
                        "profile_image": u.get("profile_image") or "",
                    }

    out = []
    for r in rows:
        uinfo = by_auth.get(str(r.get("user_auth_id")) or "", {})
        obj = dict(r)
        obj["user"] = uinfo
        out.append(obj)

    return {"reviews": out, "summary": {"count": cnt, "avg": avg}}


@app.post("/products/{product_id}/reviews")
def submit_product_review(product_id: str, payload: dict, authorization: str | None = Header(default=None)):
    """Create a review for a product. Requires Authorization bearer token.

    Body: { rating: 1..5, review: string }
    """
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(
            status_code=401, detail="Missing Authorization bearer token")

    rating = payload.get("rating")
    review_text = (payload.get("review") or "").strip()
    try:
        rating = int(rating)
    except Exception:
        raise HTTPException(
            status_code=400, detail="rating must be an integer 1-5")
    if rating < 1 or rating > 5:
        raise HTTPException(
            status_code=400, detail="rating must be between 1 and 5")
    if not review_text:
        raise HTTPException(status_code=400, detail="review text is required")

    user_id = _get_user_from_authorization(authorization)
    if not user_id:
        raise HTTPException(
            status_code=401, detail="Invalid Authorization token")

    client = getattr(app.state, "supabase", None)
    if client is None:
        raise HTTPException(status_code=500, detail="Supabase not configured")

    row = {
        "product_id": product_id,
        "user_auth_id": user_id,
        "rating": rating,
        "review": review_text,
    }
    res = client.table("reviews").insert(row).execute()
    if getattr(res, "error", None):
        raise HTTPException(status_code=400, detail=str(res.error))
    data = res.data
    # Return the inserted row id if available
    rid = None
    if isinstance(data, list) and data:
        rid = data[0].get("id")
    elif isinstance(data, dict):
        rid = data.get("id")
    return {"ok": True, "id": rid}


# ---------------------- CART API (bridges to Supabase RPC) ----------------------

@app.get("/cart")
def get_cart(authorization: str | None = Header(default=None)):
    # Use authenticated context; if no JWT, reject
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(
            status_code=401, detail="Missing Authorization bearer token")
    try:
        base = os.environ.get("SUPABASE_URL")
        anon = os.environ.get("SUPABASE_ANON_KEY")
        if not base or not anon:
            raise HTTPException(
                status_code=500, detail="SUPABASE_URL/ANON_KEY missing on server")
        url = base.rstrip("/") + "/rest/v1/cart_items"
        headers = {
            "apikey": anon,
            "Authorization": authorization,
        }
        params = {"select": "id,product_id,quantity,unit_price,updated_at"}
        with httpx.Client(timeout=15.0) as s:
            r = s.get(url, headers=headers, params=params)
        if r.status_code >= 400:
            raise HTTPException(status_code=r.status_code, detail=r.text)
        return {"items": r.json()}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.post("/cart/add")
def add_to_cart(payload: dict, authorization: str | None = Header(default=None)):
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(
            status_code=401, detail="Missing Authorization bearer token")
    product_id = payload.get("product_id")
    quantity = int(payload.get("quantity") or 1)
    if not product_id:
        raise HTTPException(status_code=400, detail="product_id is required")
    if quantity <= 0:
        raise HTTPException(status_code=400, detail="quantity must be > 0")
    try:
        base = os.environ.get("SUPABASE_URL")
        anon = os.environ.get("SUPABASE_ANON_KEY")
        if not base or not anon:
            raise HTTPException(
                status_code=500, detail="SUPABASE_URL/ANON_KEY missing on server")
        url = base.rstrip("/") + "/rest/v1/rpc/add_to_cart_self"
        headers = {
            "apikey": anon,
            "Authorization": authorization,
            "Content-Type": "application/json",
        }
        body = {"p_product_id": product_id, "p_quantity": quantity}
        with httpx.Client(timeout=20.0) as s:
            r = s.post(url, headers=headers, json=body)
        if r.status_code >= 400:
            raise HTTPException(status_code=r.status_code, detail=r.text)
        return r.json()
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.post("/cart/checkout")
def checkout(authorization: str | None = Header(default=None)):
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(
            status_code=401, detail="Missing Authorization bearer token")
    try:
        base = os.environ.get("SUPABASE_URL")
        anon = os.environ.get("SUPABASE_ANON_KEY")
        if not base or not anon:
            raise HTTPException(
                status_code=500, detail="SUPABASE_URL/ANON_KEY missing on server")
        url = base.rstrip("/") + "/rest/v1/rpc/checkout_self"
        headers = {
            "apikey": anon,
            "Authorization": authorization,
        }
        with httpx.Client(timeout=30.0) as s:
            r = s.post(url, headers=headers)
        if r.status_code >= 400:
            raise HTTPException(status_code=r.status_code, detail=r.text)
        return r.json()
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/suggest")
def suggest_tokens(q: str):
    q = (q or "").strip()
    if not q:
        return {"color": None, "category": None}

    # Heuristic fallback lists (used only if Gemini unavailable/errors)
    colors = [
        'black', 'white', 'red', 'green', 'blue', 'yellow', 'orange', 'purple',
        'pink', 'brown', 'gray', 'grey', 'beige', 'maroon', 'navy', 'teal'
    ]
    styles = [
        'oversized', 'slim', 'regular', 'relaxed', 'vintage', 'streetwear',
        'casual', 'formal', 'sport', 'retro', 'minimal', 'cozy'
    ]

    # Try Gemini structured output if configured
    if _os.environ.get("GEMINI_API_KEY"):
        try:
            from google import genai
            from pydantic import BaseModel
            from typing import Optional, List as _List

            class Facet(BaseModel):
                title: str
                options: _List[str] = []

            class Suggestions(BaseModel):
                primary: Optional[str] = None
                facets: _List[Facet] = []

            client_g = genai.Client(api_key=_os.environ.get("GEMINI_API_KEY"))
            resp = client_g.models.generate_content(
                model="gemini-2.5-flash",
                contents=[
                    {
                        "role": "user",
                        "parts": [
                            (
                                "Analyze the shopping query and return structured facets for refinement. "
                                "Return JSON with: primary (main product category term as a string or null), "
                                "facets (array). Each facet has title (e.g., 'category', 'color', 'taste', 'brand', 'material', 'fit', 'season', 'occasion') "
                                "and options (array of short strings). Include a 'taste' facet if relevant (e.g., streetwear, minimal, cozy). "
                                "For each facet, provide 5 to 10 distinct, relevant options when possible, ordered by relevance. "
                                "Options must be concise (1-2 words). If the query is narrow, propose closely related alternatives to reach at least 5. "
                                "Use null/empty when unknown.\n"
                                f"Query: {q}"
                            )
                        ],
                    }
                ],
                config={
                    "response_mime_type": "application/json",
                    "response_schema": Suggestions,
                },
            )
            parsed = getattr(resp, "parsed", None)
            if parsed is not None:
                # Extract normalized dict
                primary = getattr(parsed, "primary", None)
                facets = []
                for f in getattr(parsed, "facets", []) or []:
                    facets.append({"title": getattr(f, "title", "").strip(
                    ), "options": list(getattr(f, "options", []) or [])})
                return {"primary": primary, "facets": facets}

            # Fallback: try to parse response.text as JSON
            text = getattr(resp, "text", None) or ""
            import json as _json
            try:
                data = _json.loads(text)
                primary = data.get("primary") if isinstance(
                    data, dict) else None
                facets = data.get("facets") if isinstance(data, dict) else None
                return {"primary": primary, "facets": facets or []}
            except Exception:
                pass
        except Exception:
            # Fall through to heuristic
            pass

    # Heuristic fallback if Gemini not configured or failed
    ql = q.lower()
    tokens = ql.split()
    tokset = set(tokens)
    color = next((c for c in colors if c in tokset), None)
    # naive category guess: first non-color token
    category = next((t for t in tokens if t not in colors), None)

    # Build richer fallback facet options (5-10 each where possible)
    # Category candidates from DB or common list
    common_categories = [
        'hoodie', 't-shirt', 'shirt', 'sweatshirt', 'jacket', 'coat', 'jeans', 'pants', 'shorts',
        'dress', 'skirt', 'shoes', 'sneakers', 'boots', 'sandals', 'hat', 'cap', 'bag', 'sweater', 'cardigan'
    ]
    try:
        client = getattr(app.state, "supabase", None)
        if client is not None:
            res = client.table("products").select("category").execute()
            if not getattr(res, "error", None):
                db_cats = [str(r.get("category") or "").lower()
                           for r in (res.data or []) if r.get("category")]
                # De-dup preserving order
                seen = set()
                merged = []
                for x in db_cats + common_categories:
                    if x and x not in seen:
                        seen.add(x)
                        merged.append(x)
                common_categories = merged
    except Exception:
        pass

    cat_opts = []
    if category:
        cat_opts.append(category)
    # Add similar categories containing token substrings
    for c in common_categories:
        if len(cat_opts) >= 10:
            break
        if category and c == category:
            continue
        if not tokens or any(t in c for t in tokens):
            cat_opts.append(c)
    # Pad up to 5-10 with top categories
    if len(cat_opts) < 5:
        for c in common_categories:
            if len(cat_opts) >= 5:
                break
            if c not in cat_opts:
                cat_opts.append(c)
    cat_opts = cat_opts[:10]

    # Color options: include detected plus common palette
    palette = [
        'black', 'white', 'gray', 'grey', 'navy', 'green', 'red', 'blue', 'beige', 'brown', 'purple', 'pink', 'orange', 'yellow', 'teal'
    ]
    col_opts = []
    if color:
        col_opts.append(color)
    for c in palette:
        if len(col_opts) >= 10:
            break
        if c not in col_opts:
            col_opts.append(c)
    if len(col_opts) < 5:
        # ensure at least 5
        while len(col_opts) < 5:
            col_opts.append('black')
    col_opts = col_opts[:10]

    # Taste/style options: include detected tokens and pad with common styles
    found_styles = [s for s in styles if s in tokset]
    taste_opts = []
    taste_opts.extend(found_styles)
    for s in styles:
        if len(taste_opts) >= 10:
            break
        if s not in taste_opts:
            taste_opts.append(s)
    taste_opts = taste_opts[:10]

    facet_list = []
    if cat_opts:
        facet_list.append({"title": "category", "options": cat_opts})
    if col_opts:
        facet_list.append({"title": "color", "options": col_opts})
    if taste_opts:
        facet_list.append({"title": "taste", "options": taste_opts})
    return {"primary": category, "facets": facet_list}


@app.post("/image-search/search")
async def image_search(payload: dict):
    """Search similar images by a base64 image or text query.

    Payload:
      - base64_image: data URI string
      - query_text: optional, used if no image
      - limit: optional int
    Returns (backward compatible):
      {
        image_ids: ["basename1", ...],  # deprecated, kept for compatibility
        results: [
          { "product_id": "...", "image_url": "...", "score": 0.87, "image_id": "basename" },
          ...
        ]
      }
    """
    client = getattr(app.state, "supabase", None)
    if client is None:
        raise HTTPException(status_code=500, detail="Supabase not configured")
    limit = int(payload.get("limit") or 3)
    model = _get_clip()

    if "base64_image" in payload and isinstance(payload["base64_image"], str):
        import base64
        data_uri = payload["base64_image"]
        try:
            b64 = data_uri.split(",", 1)[1] if "," in data_uri else data_uri
            content = base64.b64decode(b64)
            image = Image.open(io.BytesIO(content)).convert("RGB")
            qvec = model.encode(image)
        except Exception as e:
            raise HTTPException(
                status_code=400, detail=f"Invalid base64 image: {e}")
    elif "query_text" in payload and isinstance(payload["query_text"], str):
        qvec = model.encode(payload["query_text"])
    else:
        raise HTTPException(
            status_code=400, detail="Provide base64_image or query_text")

    q = np.array(qvec, dtype=np.float32)
    q_norm = q / (np.linalg.norm(q) + 1e-9)

    # Fetch candidate vectors and urls
    # Include product_id with vectors for robust mapping client-side
    res = client.table("product_images").select(
        "product_id,image_url,image_vectors").execute()
    if getattr(res, "error", None):
        raise HTTPException(status_code=400, detail=str(res.error))
    items = res.data or []

    scored = []
    for it in items:
        vec = it.get("image_vectors")
        url = it.get("image_url")
        pid = it.get("product_id")
        if not vec or not url:
            continue
        # Some databases may return vector as a JSON-string; parse if needed
        if isinstance(vec, str):
            try:
                vec = json.loads(vec)
            except Exception:
                try:
                    vec = literal_eval(vec)
                except Exception:
                    # Skip if cannot parse
                    continue
        v = np.array(vec, dtype=np.float32)
        v = v / (np.linalg.norm(v) + 1e-9)
        score = float(np.dot(q_norm, v))
        scored.append((score, url, pid))

    scored.sort(key=lambda x: x[0], reverse=True)
    top = scored[:limit]

    def basename_no_ext(u: str) -> str:
        base = u.rsplit("/", 1)[-1]
        if "." in base:
            base = base[: base.rfind(".")]
        return base

    results = [
        {
            "product_id": pid,
            "image_url": u,
            "score": s,
            "image_id": basename_no_ext(u),
        }
        for (s, u, pid) in top
    ]

    return {
        "image_ids": [r["image_id"] for r in results],
        "results": results,
    }


@app.get("/products/{product_id}/related")
def related_products(product_id: str, limit: int = 6):

    client = getattr(app.state, "supabase", None)
    if client is None:
        raise HTTPException(status_code=500, detail="Supabase not configured")

    piv = client.table("product_images").select(
        "product_id,image_vectors,image_url"
    ).eq("product_id", product_id).execute()
    if getattr(piv, "error", None):
        raise HTTPException(status_code=400, detail=str(piv.error))
    anchors_raw = piv.data or []
    if not anchors_raw:
        prod = client.table("products").select(
            "id,name,description"
        ).eq("id", product_id).limit(1).execute()
        if getattr(prod, "error", None):
            raise HTTPException(status_code=400, detail=str(prod.error))
        rows = prod.data or []
        if not rows:
            return {"results": []}
        model = _get_clip()
        qvec = model.encode(
            f"{rows[0].get('name', '')}. {rows[0].get('description', '')}")
        q = np.array(qvec, dtype=np.float32)
        q = q / (np.linalg.norm(q) + 1e-9)
    else:
        acc = None
        count = 0
        for it in anchors_raw:
            vec = it.get("image_vectors")
            if vec is None:
                continue
            if isinstance(vec, str):
                try:
                    vec = json.loads(vec)
                except Exception:
                    try:
                        vec = literal_eval(vec)
                    except Exception:
                        continue
            v = np.array(vec, dtype=np.float32)
            n = np.linalg.norm(v) + 1e-9
            v = v / n
            if acc is None:
                acc = v
            else:
                acc = acc + v
            count += 1
        if acc is None or count == 0:
            return {"results": []}
        q = acc / (np.linalg.norm(acc) + 1e-9)

    res = client.table("product_images").select(
        "product_id,image_url,image_vectors"
    ).neq("product_id", product_id).execute()
    if getattr(res, "error", None):
        raise HTTPException(status_code=400, detail=str(res.error))
    items = res.data or []

    best_by_product = {}
    for it in items:
        pid = it.get("product_id")
        vec = it.get("image_vectors")
        if not pid or vec is None:
            continue
        if isinstance(vec, str):
            try:
                vec = json.loads(vec)
            except Exception:
                try:
                    vec = literal_eval(vec)
                except Exception:
                    continue
        v = np.array(vec, dtype=np.float32)
        v = v / (np.linalg.norm(v) + 1e-9)
        score = float(np.dot(q, v))
        cur = best_by_product.get(pid)
        if cur is None or score > cur["score"]:
            best_by_product[pid] = {
                "score": score,
                "image_url": it.get("image_url"),
            }

    # 3) Sort by score and pick top product ids
    ranked = sorted(best_by_product.items(),
                    key=lambda kv: kv[1]["score"], reverse=True)
    ranked = ranked[: max(0, int(limit))]
    top_ids = [pid for pid, _ in ranked]
    if not top_ids:
        return {"results": []}

    # 4) Fetch product rows in a single query
    prod_res = client.table("products").select(
        "id,auth_id,name,description,category,brand,price,stock,condition,dimensions,weight_kg,is_featured,is_in_stock,created_at,updated_at,rating"
    ).in_("id", top_ids).execute()
    if getattr(prod_res, "error", None):
        raise HTTPException(status_code=400, detail=str(prod_res.error))
    prods = prod_res.data or []
    by_id = {str(p["id"]): p for p in prods}

    # 5) Attach image_url from earlier best record and score
    results = []
    for pid, meta in ranked:
        p = by_id.get(str(pid))
        if not p:
            # In rare cases, the image row exists without its product
            # Skip gracefully
            continue
        obj = dict(p)
        if meta.get("image_url"):
            obj["image_url"] = meta["image_url"]
        obj["score"] = meta["score"]
        results.append(obj)

    return {"results": results}


@app.post("/products")
async def create_product(
    auth_id: str = Form(...),
    name: str = Form(...),
    description: str = Form(...),
    category: str = Form(...),
    brand: Optional[str] = Form(None),
    price: float = Form(...),
    stock: int = Form(...),
    condition: str = Form("New"),
    weight_kg: Optional[float] = Form(None),
    dimensions: Optional[str] = Form(None),
    is_featured: bool = Form(False),
    is_in_stock: bool = Form(True),
    # Comma-separated optional custom tags for each image in same order
    image_tags: Optional[str] = Form(None),
    files: List[UploadFile] = File(...),
):
    """Create a product with images.

    - Uploads images to Supabase Storage bucket `product-images`.
    - Inserts into `products` then `product_images` with URL and vector.
    - Generates CLIP embeddings for text (name+description) and each image.
    """

    client = getattr(app.state, "supabase", None)
    if client is None:
        raise HTTPException(status_code=500, detail="Supabase not configured")

    # 1) Insert product row
    prod_payload = {
        "auth_id": auth_id,
        "name": name,
        "description": description,
        "category": category,
        "brand": brand,
        "price": price,
        "stock": stock,
        "condition": condition,
        "weight_kg": weight_kg,
        "dimensions": dimensions,
        "is_featured": is_featured,
        "is_in_stock": is_in_stock,
    }
    # In supabase-py v2, insert() does not support chaining .select().single().
    # It returns the inserted row(s) by default (representation), typically as a list.
    prod_res = client.table("products").insert(prod_payload).execute()
    if getattr(prod_res, "error", None):
        raise HTTPException(status_code=400, detail=str(prod_res.error))
    # prod_res.data can be a list (most common) or dict depending on client behavior
    if isinstance(prod_res.data, list) and prod_res.data:
        product_id = prod_res.data[0].get("id")
    elif isinstance(prod_res.data, dict):
        product_id = prod_res.data.get("id")
    else:
        product_id = None
    if not product_id:
        raise HTTPException(
            status_code=500, detail="Failed to retrieve inserted product id")

    # Prepare CLIP model
    model = _get_clip()
    # Encode combined title+description as a single text vector for reuse
    text_embedding = _normalize_embedding(
        model.encode(f"{name}. {description}"))

    # 2) Ensure storage bucket exists (no-op if exists)
    bucket = os.getenv("STORAGE_BUCKET", "product-images")
    try:
        # If it already exists, this will throw; ignore errors from duplicate
        app.state.supabase.storage.create_bucket(
            bucket, options={"public": True})
    except Exception:
        pass

    # Parse tags
    tag_list: List[str] = []
    if image_tags:
        tag_list = [t.strip() for t in image_tags.split(",")]

    # 3) Upload each image and insert product_images with vectors
    inserted_images = []
    for idx, up in enumerate(files):
        # Read file bytes
        content = await up.read()
        if not content:
            continue
        # Generate a unique path
        ext = (up.filename.split(".")[-1] or "jpg").lower()
        key = f"{product_id}/{uuid.uuid4()}.{ext}"

        # Upload to Storage (storage3 sync API expects a file path)
        tmp_path = None
        try:
            with tempfile.NamedTemporaryFile(delete=False, suffix=f".{ext}") as tmp:
                tmp.write(content)
                tmp.flush()
                tmp_path = tmp.name
            app.state.supabase.storage.from_(bucket).upload(
                file=tmp_path,
                path=key,
                file_options={
                    "content-type": up.content_type or "image/jpeg",
                    "upsert": False,
                },
            )
        finally:
            if tmp_path and os.path.exists(tmp_path):
                try:
                    os.remove(tmp_path)
                except Exception:
                    pass
        # Public URL
        url_resp = app.state.supabase.storage.from_(bucket).get_public_url(key)
        if isinstance(url_resp, str):
            url = url_resp
        elif isinstance(url_resp, dict):
            url = url_resp.get("publicUrl") or url_resp.get(
                "public_url") or url_resp.get("url")
        else:
            url = str(url_resp)

        # Build image embedding with CLIP
        try:
            image = Image.open(io.BytesIO(content)).convert("RGB")
        except Exception as e:
            raise HTTPException(
                status_code=400, detail=f"Invalid image: {up.filename}: {e}")
        img_vec = _normalize_embedding(model.encode(image))
        # Combine with text to reflect title+description context
        if len(img_vec) == len(text_embedding):
            combined = [(img_vec[i] + text_embedding[i]) /
                        2.0 for i in range(len(img_vec))]
        else:
            combined = img_vec

        # Optionally combine with text by simple concatenation or averaging.
        # Here, we store pure image vector in image_vectors, and use 'Tag' column for user tag.
        tag = tag_list[idx] if idx < len(tag_list) else ""

        row = {
            "product_id": product_id,
            "image_url": url,
            "image_vectors": combined,
            "Tag": tag,
        }
        ins = client.table("product_images").insert(row).execute()
        if getattr(ins, "error", None):
            raise HTTPException(status_code=400, detail=str(ins.error))
        inserted_images.append({"url": url, "tag": tag})

    return {
        "product_id": product_id,
        "images": inserted_images,
        "text_embedding_dim": len(text_embedding),
    }
