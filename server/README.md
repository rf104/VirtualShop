# Server (FastAPI + Supabase)

This service initializes the Supabase Python SDK and exposes a small FastAPI app.

## Quick start

1. Create an environment file:

```bash
cp server/.env.example server/.env
# set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY (or SUPABASE_ANON_KEY)
```

2. Install dependencies (prefer a venv):

```bash
python -m venv .venv && source .venv/bin/activate
pip install -r server/requirements.txt
```

3. Run the API:

```bash
uvicorn server.main:app --reload --host 0.0.0.0 --port 8000
```

4. Check endpoints:
- Root: `GET /` → `{ "status": "ok" }`
- Supabase health: `GET /supabase/health` → `{ configured: true|false, url?: string }`

## Product API

- Create product with images and vectors: `POST /products`
	- Content-Type: `multipart/form-data`
	- Fields (Form):
		- `auth_id` (uuid string of `auth.users.id`)
		- `name`, `description`, `category`, `brand?`, `price` (float), `stock` (int), `condition?`, `weight_kg?`, `dimensions?`, `is_featured?`, `is_in_stock?`
		- `image_tags?` optional comma-separated tags for images in the same order
	- Files: `files` (repeatable images up to your UI cap)
	- Behavior:
		- Uploads each image to Storage bucket `product-images` (public)
		- Inserts product into `products`
		- Inserts rows into `product_images` with `image_url`, `image_vectors` (CLIP 512-d), and `Tag`

Notes
- Requires Postgres vector type on `product_images.image_vectors` compatible with CLIP (512 dims) and Storage bucket access.
- Model used: `sentence-transformers` `clip-ViT-B-32`.

## Cart API

These endpoints forward to Supabase PostgREST/RPC using the caller's Supabase JWT. Pass your Supabase access token in the `Authorization: Bearer <jwt>` header.

- Get cart items (current user): `GET /cart`
- Add to cart: `POST /cart/add` with JSON body `{ "product_id": "<uuid>", "quantity": 1 }`
- Checkout: `POST /cart/checkout`

Prerequisites (run on your Supabase project):

1. Enable extension and type
	- `create extension if not exists pgcrypto;`
	- `create type order_status as enum ('pending','paid','failed','cancelled');`
2. Create tables: `cart_items`, `orders`, `order_items`
3. Create functions: `add_to_cart_self(p_product_id uuid, p_quantity int)` and `checkout_self()`
4. Add grants + RLS policies so users can only access their own rows.

See the SQL block in the parent conversation for full definitions.

## Notes
- On servers, prefer `SUPABASE_SERVICE_ROLE_KEY` for admin operations. Never expose it to browsers.
- For public, read-only use, set `SUPABASE_ANON_KEY`.