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

## MCP (Model Context Protocol)

This server mounts a FastMCP instance under `/llm/mcp`:

- Auto-generated tools from all FastAPI routes (via `FastMCP.from_fastapi`).
- A curated `assistant_chat` tool that proxies chat to Gemini 2.5 Pro when `GEMINI_API_KEY` is set.

Run locally:

```bash
uvicorn server.main:app --reload --host 0.0.0.0 --port 8000
```

Endpoints:
- MCP manifest and RPC entrypoint: `http://localhost:8000/llm/mcp/`
- Assistant REST bridge (for non-MCP clients): `POST /assistant/chat`

Environment variables:
- `GEMINI_API_KEY` (optional): enables Gemini-based responses for `assistant_chat`.

Gemini tool-calling example (optional)

```python
# run this separately to test tool-calling
import asyncio
from google import genai
from google.genai import types
from fastmcp import Client as MCPClient

async def main():
	# Connect to the mounted MCP server
	async with MCPClient("http://localhost:8000/llm/mcp/") as mcp_client:
		gclient = genai.Client()
		resp = await gclient.aio.models.generate_content(
			model="gemini-2.5-pro",
			contents="List products and then fetch details for the first one.",
			config=types.GenerateContentConfig(tools=[mcp_client.session]),
		)
		print(resp.text)

asyncio.run(main())
```