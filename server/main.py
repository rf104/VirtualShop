from typing import Optional, List
import io
import uuid
import os
import tempfile

from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
from sentence_transformers import SentenceTransformer
import numpy as np
import json
from ast import literal_eval

from server.supabase_client import get_supabase, SupabaseNotConfigured

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
        "id,name,description,category,brand,price,stock,condition,dimensions,weight_kg,is_featured,is_in_stock").execute()
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
        "id,name,description,category,brand,price,stock,condition,dimensions,weight_kg,is_featured,is_in_stock,created_at,updated_at"
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
