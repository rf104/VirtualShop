from typing import Optional, List
import io
import uuid
import os
import tempfile
from datetime import datetime, timedelta, timezone
from datetime import datetime
from decimal import Decimal, InvalidOperation

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
import requests as _requests

try:
    from gradio_client import Client as _GradioClient, handle_file as _handle_file
except Exception:
    _GradioClient = None
    _handle_file = None

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

    # Pre-create gradio client if possible to reduce cold start
    try:
        app.state.gradio_client = _GradioClient(
            "ayna-ai-org/ayna-1.0") if _GradioClient else None
    except Exception:
        app.state.gradio_client = None


# Register seller routes
app.include_router(seller_router)


@app.get("/")
def read_root():
    return {"status": "ok"}


@app.get("/ping")
def ping():
    return {"status": "ok"}


class _TryOnRequest(_json.JSONEncoder):
    pass


'''
curl -X POST "http://localhost:8000/process_image" -H "Content-Type: application/json" -d '{
  "person_img_url": "http://example.com/person.jpg",
  "garment_img_url": "http://example.com/garment.jpg",
  "garment_des": "A stylish garment",
  "is_checked": true,
  "is_checked_crop": false,
  "denoise_steps": 30,
  "seed": 42
}'
'''


@app.post("/process_image")
def process_image(payload: dict):
    """Virtual try-on using Hugging Face Space yisol/IDM-VTON.

    Body JSON:
      - person_img_url: http(s) URL for person (used as 'background')
      - garment_img_url: http(s) URL for garment (garm_img)
      - garment_des: short textual garment description (string)
      - is_checked: bool (default True)
      - is_checked_crop: bool (default False)
      - denoise_steps: int/float (default 30)
      - seed: int/float (default 42)

    Returns:
      If Supabase configured:
        { url: <primary_result_url>, masked_url: <masked_result_url|null> }
      Else (no Supabase):
        { data_uri: <base64>, masked_data_uri: <base64|null> }
    """
    # ---- 1) Validate inputs ----
    person_url = str(payload.get("person_img_url") or "").strip()
    garment_url = str(payload.get("garment_img_url") or "").strip()
    garment_des = str(payload.get("garment_des") or "").strip() or "garment"
    is_checked = bool(payload.get("is_checked", True))
    is_checked_crop = bool(payload.get("is_checked_crop", False))
    denoise_steps = payload.get("denoise_steps", 30)
    seed = payload.get("seed", 42)

    print(person_url, garment_url, garment_des)

    def _valid(u: str) -> bool:
        return u.startswith("http://") or u.startswith("https://")

    if not (_valid(person_url) and _valid(garment_url)):
        raise HTTPException(
            status_code=400, detail="person_img_url and garment_img_url must be http(s) URLs")

    # ---- 2) Init / cache Gradio client ----
    if _GradioClient is None:
        raise HTTPException(
            status_code=500, detail="gradio_client not installed on server")
    client = getattr(app.state, "idm_vton_client", None)
    if client is None:
        try:
            client = _GradioClient("yisol/IDM-VTON")
            app.state.idm_vton_client = client
        except Exception as e:
            raise HTTPException(
                status_code=500, detail=f"Failed to init IDM-VTON client: {e}")

    # ---- 3) Call Space ----
    try:
        result = client.predict(
            dict={"background": _handle_file(
                person_url), "layers": [], "composite": None},
            garm_img=_handle_file(garment_url),
            garment_des=garment_des,
            is_checked=is_checked,
            is_checked_crop=is_checked_crop,
            denoise_steps=denoise_steps,
            seed=seed,
            api_name="/tryon",
        )
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Try-on model error: {e}")

    # Expected tuple (primary, masked)
    if not isinstance(result, (list, tuple)) or len(result) == 0:
        raise HTTPException(
            status_code=500, detail="Unexpected model output format")

    primary_out = result[0]
    masked_out = result[1] if len(result) > 1 else None

    import mimetypes

    def _read_output(obj):
        """Return (bytes, mime, ext) or (None, None, None) if cannot read."""
        if obj is None:
            return None, None, None
        if isinstance(obj, str):
            if obj.startswith("http://") or obj.startswith("https://"):
                try:
                    r = _requests.get(obj, timeout=120)
                    r.raise_for_status()
                    ctype = r.headers.get("content-type") or ""
                    ext = ".png"
                    if "jpeg" in ctype:
                        ext = ".jpg"
                    elif "webp" in ctype:
                        ext = ".webp"
                    return r.content, ctype or "image/png", ext
                except Exception:
                    return None, None, None
            # Local path inside Space container (gradio_client downloads artifact)
            if os.path.exists(obj):
                try:
                    with open(obj, "rb") as f:
                        data = f.read()
                    guess, _ = mimetypes.guess_type(obj)
                    ext = os.path.splitext(obj)[1] or ".png"
                    return data, (guess or "image/png"), ext
                except Exception:
                    return None, None, None
        return None, None, None

    primary_bytes, primary_mime, primary_ext = _read_output(primary_out)
    if not primary_bytes:
        raise HTTPException(
            status_code=500, detail="Failed to retrieve primary output image")

    masked_bytes, masked_mime, masked_ext = _read_output(masked_out)

    # ---- 4) Upload (or return base64) ----
    sb = getattr(app.state, "supabase", None)
    if sb is None:
        # No Supabase: return data URIs
        b64_primary = base64.b64encode(primary_bytes).decode("utf-8")
        resp = {"data_uri": f"data:{primary_mime or 'image/png'};base64,{b64_primary}"}
        if masked_bytes:
            b64_masked = base64.b64encode(masked_bytes).decode("utf-8")
            resp["masked_data_uri"] = f"data:{masked_mime or 'image/png'};base64,{b64_masked}"
        return resp

    bucket = os.getenv("TRYON_BUCKET", "try-on")
    try:
        sb.storage.create_bucket(bucket, options={"public": True})
    except Exception:
        pass

    def _upload(content: bytes, mime: str, ext: str) -> str | None:
        key = f"results/{uuid.uuid4()}{ext}"
        tmp_path = None
        try:
            with tempfile.NamedTemporaryFile(delete=False, suffix=ext) as tmp:
                tmp.write(content)
                tmp.flush()
                tmp_path = tmp.name
            sb.storage.from_(bucket).upload(
                file=tmp_path,
                path=key,
                file_options={
                    "content-type": mime or "image/png",
                    "upsert": False,
                },
            )
        finally:
            if tmp_path and os.path.exists(tmp_path):
                try:
                    os.remove(tmp_path)
                except Exception:
                    pass
        url_resp = sb.storage.from_(bucket).get_public_url(key)
        if isinstance(url_resp, str):
            return url_resp
        if isinstance(url_resp, dict):
            return url_resp.get("publicUrl") or url_resp.get("public_url") or url_resp.get("url")
        return str(url_resp)

    primary_url = _upload(primary_bytes, primary_mime, primary_ext or ".png")
    masked_url = _upload(masked_bytes, masked_mime,
                         masked_ext or ".png") if masked_bytes else None
    print("Uploaded try-on results to:", primary_url, masked_url)
    return {"url": primary_url, "masked_url": masked_url}


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


@app.get("/products/by_ids")
def get_products_by_ids(ids: str):
    """Return multiple products by id, with first image_url, preserving given order when possible."""
    client = getattr(app.state, "supabase", None)
    if client is None:
        raise HTTPException(status_code=500, detail="Supabase not configured")
    raw = [x.strip() for x in (ids or "").split(",") if x.strip()]
    if not raw:
        return []
    res = client.table("products").select(
        "id,name,description,category,brand,price,stock,condition,dimensions,weight_kg,is_featured,is_in_stock,created_at,updated_at"
    ).in_("id", raw).execute()
    if getattr(res, "error", None):
        raise HTTPException(status_code=400, detail=str(res.error))
    prods = res.data or []
    by_id = {str(p["id"]): dict(p) for p in prods}
    # Fetch first image per product in one go
    img_res = client.table("product_images").select("product_id,image_url").in_(
        "product_id", list(by_id.keys())).order("created_at", desc=False).execute()
    if not getattr(img_res, "error", None):
        # Keep first seen per product
        seen = set()
        for row in (img_res.data or []):
            pid = str(row.get("product_id"))
            if pid in by_id and pid not in seen:
                by_id[pid]["image_url"] = row.get("image_url")
                seen.add(pid)
    # Preserve input order
    out = [by_id[i] for i in raw if i in by_id]
    return out


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


@app.get("/products/{product_id}")
def get_product(product_id: uuid.UUID):
    client = getattr(app.state, "supabase", None)
    if client is None:
        raise HTTPException(status_code=500, detail="Supabase not configured")
    res = client.table("products").select(
        "id,name,description,category,brand,price,stock,condition,dimensions,weight_kg,is_featured,is_in_stock,created_at,updated_at"
    ).eq("id", str(product_id)).limit(1).execute()
    if getattr(res, "error", None):
        raise HTTPException(status_code=400, detail=str(res.error))
    rows = res.data or []
    if not rows:
        raise HTTPException(status_code=404, detail="Product not found")
    p = rows[0]
    img_res = client.table("product_images").select("image_url").eq(
        "product_id", str(product_id)).order("created_at", desc=False).limit(1).execute()
    if not getattr(img_res, "error", None) and img_res.data:
        p = dict(p)
        p["image_url"] = img_res.data[0].get("image_url")
    return p


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


# @app.post("/cart/checkout")
# def checkout(authorization: str | None = Header(default=None)):
#     if not authorization or not authorization.lower().startswith("bearer "):
#         raise HTTPException(
#             status_code=401, detail="Missing Authorization bearer token")
#     try:
#         base = os.environ.get("SUPABASE_URL")
#         anon = os.environ.get("SUPABASE_ANON_KEY")
#         if not base or not anon:
#             raise HTTPException(
#                 status_code=500, detail="SUPABASE_URL/ANON_KEY missing on server")
#         url = base.rstrip("/") + "/rest/v1/rpc/checkout_self"
#         headers = {
#             "apikey": anon,
#             "Authorization": authorization,
#         }
#         with httpx.Client(timeout=30.0) as s:
#             r = s.post(url, headers=headers)
#         if r.status_code >= 400:
#             raise HTTPException(status_code=r.status_code, detail=r.text)
#         return r.json()
#     except Exception as e:
#         raise HTTPException(status_code=400, detail=str(e))

# /cart/checkout endpoint (handles multi-shop checkout)

@app.post("/cart/checkout")
def checkout(authorization: str | None = Header(default=None)):
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(
            status_code=401, detail="Missing Authorization bearer token")

    base = os.environ.get("SUPABASE_URL")
    anon = os.environ.get("SUPABASE_ANON_KEY")
    if not base or not anon:
        raise HTTPException(
            status_code=500, detail="SUPABASE_URL/ANON_KEY missing on server")

    rpc_url = base.rstrip("/") + "/rest/v1/rpc/checkout_self"
    headers = {"apikey": anon, "Authorization": authorization}

    # 1) call checkout RPC
    try:
        with httpx.Client(timeout=30.0) as s:
            r = s.post(rpc_url, headers=headers)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"RPC call failed: {e}")

    if r.status_code >= 400:
        raise HTTPException(status_code=r.status_code,
                            detail=f"Checkout RPC error: {r.text}")

    try:
        checkout_resp = r.json()
    except ValueError:
        raise HTTPException(
            status_code=500, detail=f"Invalid JSON from checkout RPC: {r.text}")

    # normalize into a list of shop-orders (orders may already be per-shop)
    if isinstance(checkout_resp, dict):
        orders = [checkout_resp]
    elif isinstance(checkout_resp, list):
        orders = checkout_resp
    else:
        orders = [checkout_resp]

    # build payments payload for each returned order (extract order_id, shop info, amount)
    payments_payload_by_order = []
    skipped = []
    now_iso = datetime.utcnow().isoformat() + "Z"
    total_amount = Decimal("0.00")

    for o in orders:
        if not isinstance(o, dict):
            skipped.append(o)
            continue

        # Try common id/amount keys
        order_id = o.get("id") or o.get("order_id") or o.get("orderId")
        amount = (o.get("total") or o.get("amount") or o.get("grand_total")
                  or o.get("total_amount") or o.get("gross_price"))
        shop_id = o.get("shop_id") or o.get("seller_id") or o.get(
            "vendor_id")  # optional, if returned

        if not order_id:
            skipped.append(o)
            continue

        try:
            if amount is None:
                amt = Decimal("0.00")
            else:
                amt = Decimal(str(amount))
        except (InvalidOperation, TypeError):
            amt = Decimal("0.00")

        total_amount += amt

        payments_payload_by_order.append({
            "order_id": order_id,
            "payer_auth_id": None,               # fill if you decode JWT or have user id
            "amount": str(amt),
            "payment_method": "unknown",
            "payment_status": "completed",
            "transaction_id": str(uuid.uuid4()),
            "paid_at": now_iso,
            # optional metadata to help debugging / bookkeeping
            "meta_shop_id": shop_id
        })

    # If nothing to do
    if not payments_payload_by_order:
        return {
            "checkout": checkout_resp,
            "payments": {"inserted": [], "skipped": skipped, "note": "no valid order ids returned"}
        }

    # --- OPTION B: try to create a master (parent) order and attach payments to that master id ---
    # This creates a single top-level order record (id = master_order_id) so all payments reference same order_id.
    # If creation of the master order fails (schema/constraints/RLS), we fall back to Option A (per-shop payments).
    master_order_id = str(uuid.uuid4())
    master_order_payload = {
        "id": master_order_id,
        # best-effort minimal fields; adjust according to your orders schema
        "created_at": now_iso,
        # if your orders table does not have this column, insertion may fail
        "order_status": "grouped",
        # optionally include totals for bookkeeping
        "total_amount": str(total_amount) if total_amount is not None else None
    }

    orders_url = base.rstrip("/") + "/rest/v1/orders"
    insert_headers = {
        "apikey": anon,
        "Authorization": authorization,
        "Content-Type": "application/json",
        "Prefer": "return=minimal",
    }

    master_created = False
    try:
        with httpx.Client(timeout=30.0) as s:
            # try creating the master order
            mo_r = s.post(orders_url, headers=insert_headers,
                          json=master_order_payload)
    except Exception as e:
        # network/timeout while creating master order -> fallback to Option A
        mo_r = None

    if mo_r and mo_r.status_code < 300:
        master_created = True
    else:
        # If Supabase returned an error, we capture it for debug but keep going with Option A
        master_err = mo_r.text if mo_r is not None else "no-response"
        master_created = False

    payments_url = base.rstrip("/") + "/rest/v1/payments"
    insert_headers["Prefer"] = "return=representation"

    if master_created:
        # prepare payments payload: reference master_order_id for all payments (single order id for whole checkout)
        payments_payload = []
        for p in payments_payload_by_order:
            payments_payload.append({
                "order_id": master_order_id,
                "payer_auth_id": p["payer_auth_id"],
                "amount": p["amount"],
                "payment_method": p["payment_method"],
                "payment_status": p["payment_status"],
                "transaction_id": p["transaction_id"],
                "paid_at": p["paid_at"],
            })
        used_path = "grouped_master_order"
    else:
        # fallback: create a payment row per returned order (keeps order_id as each shop-order's id)
        payments_payload = [
            {
                "order_id": p["order_id"],
                "payer_auth_id": p["payer_auth_id"],
                "amount": p["amount"],
                "payment_method": p["payment_method"],
                "payment_status": p["payment_status"],
                "transaction_id": p["transaction_id"],
                "paid_at": p["paid_at"],
            }
            for p in payments_payload_by_order
        ]
        used_path = "per_shop_orders"

    # Insert payments
    try:
        with httpx.Client(timeout=30.0) as s:
            p_r = s.post(payments_url, headers=insert_headers,
                         json=payments_payload)
    except Exception as e:
        raise HTTPException(
            status_code=400, detail=f"Payments insert failed: {e}")

    if p_r.status_code >= 400:
        # show Supabase body so you can debug RLS/constraint issues
        raise HTTPException(status_code=p_r.status_code,
                            detail=f"Payments insert error: {p_r.text}")

    try:
        payments_result = p_r.json()
    except ValueError:
        payments_result = p_r.text

    response = {
        "checkout": checkout_resp,
        "payments": {
            "inserted": payments_result,
            "path": used_path,
            "master_order_id": master_order_id if master_created else None,
            "master_creation_error": (master_err if not master_created else None),
            "skipped": skipped
        }
    }
    return response


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


# ---------------------- STORIES API ----------------------

@app.get("/stories")
def list_stories(limit: int = 50):
    """List recent stories (most recent first), enriched with user profile info.

    Returns an array of story objects with shape:
      {
        id, user_auth_id, product_id, media_url, caption, created_at, expires_at,
        user: { name, profile_image },
        user_name, user_avatar
      }
    """
    client = getattr(app.state, "supabase", None)
    if client is None:
        raise HTTPException(status_code=500, detail="Supabase not configured")

    # Fetch recent stories; we don't filter by expires_at to avoid server-side timestamp formatting issues.
    # Client/UI can ignore expired if necessary; most importantly, we provide a stable feed.
    q = client.table("stories").select(
        "id,user_auth_id,product_id,media_url,caption,created_at,expires_at"
    ).order("created_at", desc=True).limit(max(1, int(limit)))
    res = q.execute()
    if getattr(res, "error", None):
        raise HTTPException(status_code=400, detail=str(res.error))
    rows = res.data or []

    # Enrich with public.users info (by auth_id)
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
        # Convenience fields for clients that expect name/avatar at top level
        obj["user_name"] = uinfo.get(
            "name") if isinstance(uinfo, dict) else None
        obj["user_avatar"] = uinfo.get(
            "profile_image") if isinstance(uinfo, dict) else None
        out.append(obj)

    return out


@app.post("/stories")
async def create_story(
    authorization: str | None = Header(default=None),
    file: UploadFile = File(...),
    caption: Optional[str] = Form(None),
    product_id: Optional[str] = Form(None),
    expires_in_hours: int = Form(24),
):
    """Create a story for the authenticated user by uploading an image.

    Multipart form fields:
      - file: image file (required)
      - caption: optional text
      - product_id: optional associated product id
      - expires_in_hours: optional TTL (default 24)
    """
    # Require auth
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(
            status_code=401, detail="Missing Authorization bearer token")

    user_id = _get_user_from_authorization(authorization)
    if not user_id:
        raise HTTPException(
            status_code=401, detail="Invalid Authorization token")

    client = getattr(app.state, "supabase", None)
    if client is None:
        raise HTTPException(status_code=500, detail="Supabase not configured")

    # Ensure storage bucket exists
    bucket = os.getenv("STORIES_BUCKET", "stories")
    try:
        app.state.supabase.storage.create_bucket(
            bucket, options={"public": True})
    except Exception:
        # Already exists -> ignore
        pass

    # Read file
    content = await file.read()
    if not content:
        raise HTTPException(status_code=400, detail="Empty file upload")

    # Generate key under user namespace
    ext = (file.filename.split(".")
           [-1] if file.filename and "." in file.filename else "jpg").lower()
    key = f"{user_id}/{uuid.uuid4()}.{ext}"

    # Upload using temp file path
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
                "content-type": file.content_type or "image/jpeg",
                "upsert": False,
            },
        )
    finally:
        if tmp_path and os.path.exists(tmp_path):
            try:
                os.remove(tmp_path)
            except Exception:
                pass

    # Public URL (works regardless; for private bucket this returns signed-style path requiring Authorization)
    url_resp = app.state.supabase.storage.from_(bucket).get_public_url(key)
    if isinstance(url_resp, str):
        media_url = url_resp
    elif isinstance(url_resp, dict):
        media_url = url_resp.get("publicUrl") or url_resp.get(
            "public_url") or url_resp.get("url")
    else:
        media_url = str(url_resp)

    # Insert into stories
    try:
        hours = int(expires_in_hours)
    except Exception:
        hours = 24
    expires_at = datetime.now(timezone.utc) + timedelta(hours=max(1, hours))

    row = {
        "user_auth_id": user_id,
        "product_id": product_id,
        "media_url": media_url,
        "caption": (caption or "").strip(),
        "expires_at": expires_at.isoformat(),
    }
    ins = client.table("stories").insert(row).execute()
    if getattr(ins, "error", None):
        raise HTTPException(status_code=400, detail=str(ins.error))
    data = ins.data
    if isinstance(data, list) and data:
        created = data[0]
    elif isinstance(data, dict):
        created = data
    else:
        created = {"media_url": media_url}

    # Enrich with user info to match GET /stories shape
    try:
        prof = client.table("users").select("auth_id,name,profile_image").eq(
            "auth_id", user_id).limit(1).execute()
        user = {}
        if not getattr(prof, "error", None) and prof.data:
            u = prof.data[0]
            user = {"name": u.get("name") or "", "profile_image": u.get(
                "profile_image") or ""}
        created = dict(created)
        created["user"] = user
        created["user_name"] = user.get(
            "name") if isinstance(user, dict) else None
        created["user_avatar"] = user.get(
            "profile_image") if isinstance(user, dict) else None
    except Exception:
        pass

    return created


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

# user profile test endpoint


@app.get('/userprofile')
def test():
    return {"message": "User Profile Service is up and running."}


# all user profiles
@app.get("/users")
def get_users():
    """
    Fetch all users from Supabase 'users' table.
    """
    # Get supabase client from app state
    client = getattr(app.state, "supabase", None)
    if client is None:
        raise HTTPException(status_code=500, detail="Supabase not configured")

    # Fetch all users
    try:
        user_res = client.table("users").select("*").execute()
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Supabase query failed: {str(e)}")

    # Check for query errors
    if getattr(user_res, "error", None):
        raise HTTPException(status_code=400, detail=str(user_res.error))

    # Extract user data
    users = user_res.data or []
    return users

# All sellers profile


@app.get("/sellers")
def get_sellers():
    """
    Fetch all sellers from Supabase 'users' table.
    Only returns rows where user_type = 'Seller'.
    """
    # Get supabase client
    client = getattr(app.state, "supabase", None)
    if client is None:
        raise HTTPException(status_code=500, detail="Supabase not configured")

    try:
        seller_res = (
            client.table("users")
            .select("*")
            .eq("user_type", "Seller")
            .execute()
        )
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Supabase query failed: {str(e)}")

    if getattr(seller_res, "error", None):
        raise HTTPException(status_code=400, detail=str(seller_res.error))

    sellers = seller_res.data or []
    return sellers


@app.get("/users/{user_id}")
def get_user_profile(user_id: str, authorization: str | None = Header(default=None)):
    """
    Fetch all info of a specific user by auth_id from Supabase 'users' table.
    """
    # Verify the user is accessing their own profile
    auth_user_id = _get_user_from_authorization(authorization)
    if not auth_user_id or auth_user_id != user_id:
        raise HTTPException(
            status_code=401, detail="Unauthorized: can only access your own profile")

    client = getattr(app.state, "supabase", None)
    if client is None:
        raise HTTPException(status_code=500, detail="Supabase not configured")

    try:
        user_res = (
            client.table("users")
            .select("*")
            .eq("auth_id", user_id)   # filter by auth_id
            .single()            # expect exactly one row
            .execute()
        )
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Supabase query failed: {str(e)}")

    if getattr(user_res, "error", None):
        raise HTTPException(status_code=404, detail="User not found")

    return user_res.data

# Update User Profile Info


@app.put("/users/{user_id}")
async def update_user_profile(
    user_id: str,
    authorization: str | None = Header(default=None),
    name: Optional[str] = Form(None),
    email: Optional[str] = Form(None),
    phone: Optional[str] = Form(None),
    dob: Optional[str] = Form(None),
    address: Optional[str] = Form(None),
    profile_image: UploadFile | None = File(None),
):
    """
    Update user profile information for a specific user by user_id.
    Accepts multipart form data with optional profile image upload.
    """
    # Verify the user is updating their own profile
    auth_user_id = _get_user_from_authorization(authorization)
    if not auth_user_id or auth_user_id != user_id:
        raise HTTPException(
            status_code=401, detail="Unauthorized: can only update your own profile")

    client = getattr(app.state, "supabase", None)
    if client is None:
        raise HTTPException(status_code=500, detail="Supabase not configured")

    # Prepare update data
    update_data = {}
    if name is not None:
        update_data["name"] = name
    if email is not None:
        update_data["email"] = email
    if phone is not None:
        update_data["phone"] = phone
    if dob is not None:
        update_data["dob"] = dob
    if address is not None:
        update_data["address"] = address

    # Handle profile image upload
    if profile_image is not None:
        content = await profile_image.read()
        if content:
            bucket = os.getenv("PROFILE_BUCKET", "profile-images")
            _ensure_bucket(client, bucket)
            ext = (profile_image.filename.split(".")[-1] or "jpg").lower()
            key = f"{user_id}/{uuid.uuid4()}.{ext}"
            tmp_path = None
            try:
                with tempfile.NamedTemporaryFile(delete=False, suffix=f".{ext}") as tmp:
                    tmp.write(content)
                    tmp.flush()
                    tmp_path = tmp.name
                client.storage.from_(bucket).upload(
                    file=tmp_path,
                    path=key,
                    file_options={
                        "content-type": profile_image.content_type or "image/jpeg",
                        "upsert": True,
                    },
                )
            finally:
                if tmp_path and os.path.exists(tmp_path):
                    try:
                        os.remove(tmp_path)
                    except Exception:
                        pass
            url_resp = client.storage.from_(bucket).get_public_url(key)
            if isinstance(url_resp, str):
                url = url_resp
            elif isinstance(url_resp, dict):
                url = url_resp.get("publicUrl") or url_resp.get(
                    "public_url") or url_resp.get("url")
            else:
                url = str(url_resp)
            if url:
                update_data["profile_image"] = url

    if not update_data:
        return {"ok": True, "message": "No changes to update"}

    try:
        update_res = (
            client.table("users")
            .update(update_data)
            .eq("auth_id", user_id)  # Use auth_id instead of user_id
            .execute()
        )
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Supabase query failed: {str(e)}")

    if getattr(update_res, "error", None):
        raise HTTPException(status_code=400, detail=str(update_res.error))

    return {"ok": True, "data": update_res.data}
    if url:
        update_data["profile_image"] = url

    if not update_data:
        return {"ok": True, "message": "No changes to update"}

    try:
        update_res = (
            client.table("users")
            .update(update_data)
            .eq("auth_id", user_id)  # Use auth_id instead of user_id
            .execute()
        )
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Supabase query failed: {str(e)}")

    if getattr(update_res, "error", None):
        raise HTTPException(status_code=400, detail=str(update_res.error))

    return {"ok": True, "data": update_res.data}
