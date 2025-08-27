from fastapi import APIRouter, HTTPException, Depends, Header
from typing import Optional
import os
import base64
import json
import httpx
from datetime import datetime
from decimal import Decimal

router = APIRouter(
    prefix="/sellers",
    tags=["Sellers"],
)

def get_supabase_client():
    """Dependency to get the Supabase client from the app state."""
    from server.main import app  # Import here to avoid circular import
    client = getattr(app.state, "supabase", None)
    if client is None:
        raise HTTPException(status_code=500, detail="Supabase not configured")
    return client

@router.get("/{seller_id}")
def get_seller(seller_id: str, client = Depends(get_supabase_client)):
  """
  Get seller details.
  """
  print(f"Debug: Fetching seller with id={seller_id}")  # Debug print
  res = client.table("sellers").select("*").eq("id", seller_id).single().execute()
  if getattr(res, "error", None):
    print(f"Error fetching seller: {res.error}")  # Debug print
    raise HTTPException(status_code=400, detail=str(res.error))

  print(f"Seller data: {res.data}")  # Debug print
  return res.data or {}

@router.get("/{seller_id}/products")
def get_seller_products(seller_id: str, client = Depends(get_supabase_client)):
    """
    Get all products belonging to a seller.
    """
    # Use auth_id instead of seller_id to match the product model
    prod_res = client.table("products").select(
        "id,auth_id,name,description,category,brand,price,stock,condition,dimensions,weight_kg,is_featured,is_in_stock,created_at,updated_at,rating"
    ).eq("auth_id", seller_id).execute()
    
    if getattr(prod_res, "error", None):
        raise HTTPException(status_code=400, detail=str(prod_res.error))
    
    prods = prod_res.data or []
    out = []
    
    # For each product, fetch the first image URL like in the main products endpoint
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

    return {"seller_id": seller_id, "products": out}


def _get_sub_from_jwt(token: str) -> Optional[str]:
    """
    Extract `sub` (user id) from JWT without verifying signature.
    Works for Supabase JWTs when you only need the user id.
    """
    try:
        parts = token.split(".")
        if len(parts) < 2:
            return None
        payload_b64 = parts[1]
        padding = "=" * (-len(payload_b64) % 4)
        payload_b64 += padding
        payload_bytes = base64.urlsafe_b64decode(payload_b64)
        payload = json.loads(payload_bytes)
        return payload.get("sub") or payload.get("user_id") or payload.get("uid")
    except Exception:
        return None


@router.get("/transactions")
def seller_transactions(
    authorization: Optional[str] = Header(default=None),
    limit: int = 50,
    offset: int = 0,
    payment_status: Optional[str] = None,
    start_date: Optional[str] = None,   # ISO date e.g. "2025-08-01"
    end_date: Optional[str] = None      # ISO date e.g. "2025-08-31"
):
    """
    Returns transactions for the authenticated seller (extracted from JWT sub).
    Aggregates order_items -> parent order -> order.payments, groups by payment id.
    Client-side filtering: payment_status, start_date, end_date, pagination.
    """
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Missing Authorization bearer token")

    token = authorization.split(None, 1)[1].strip()
    seller_auth_id = _get_sub_from_jwt(token)
    if not seller_auth_id:
        raise HTTPException(status_code=401, detail="Unable to extract seller id from token")

    base = os.environ.get("SUPABASE_URL")
    anon = os.environ.get("SUPABASE_ANON_KEY")
    if not base or not anon:
        raise HTTPException(status_code=500, detail="SUPABASE_URL/ANON_KEY missing on server")

    # request order_items, include parent order (and its payments) and product
    order_items_url = base.rstrip("/") + "/rest/v1/order_items"
    select_clause = "*,order:order_id(id,created_at,order_status,payments(*)),product:product_id(id,name,auth_id,price)"
    params = {"select": select_clause, "product.auth_id": f"eq.{seller_auth_id}"}

    headers = {"apikey": anon, "Authorization": authorization, "Accept": "application/json"}

    try:
        with httpx.Client(timeout=30.0) as s:
            r = s.get(order_items_url, headers=headers, params=params)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Supabase request failed: {e}")

    if r.status_code >= 400:
        raise HTTPException(status_code=r.status_code, detail=f"Supabase error: {r.text}")

    try:
        items = r.json()
    except ValueError:
        raise HTTPException(status_code=500, detail=f"Invalid JSON from Supabase: {r.text}")

    # Aggregate payments and attach seller's items under each payment
    transactions_by_payment = {}
    for item in items:
        product = item.get("product") or {}
        order = item.get("order") or {}
        payments = order.get("payments") or []

        item_entry = {
            "order_item_id": item.get("id"),
            "product_id": product.get("id"),
            "product_name": product.get("name"),
            "quantity": item.get("quantity"),
            "unit_price": item.get("unit_price"),
        }

        for p in payments:
            payment_id = p.get("id")
            if not payment_id:
                continue
            if payment_id not in transactions_by_payment:
                transactions_by_payment[payment_id] = {
                    "payment": {
                        "id": p.get("id"),
                        "order_id": p.get("order_id"),
                        "amount": p.get("amount"),
                        "payment_method": p.get("payment_method"),
                        "payment_status": p.get("payment_status"),
                        "transaction_id": p.get("transaction_id"),
                        "paid_at": p.get("paid_at"),
                        "created_at": p.get("created_at"),
                    },
                    "items": [],
                    "order_meta": {
                        "id": order.get("id"),
                        "created_at": order.get("created_at"),
                        "order_status": order.get("order_status"),
                    }
                }
            transactions_by_payment[payment_id]["items"].append(item_entry)

    # Convert to list and apply optional filters (status/date)
    transactions = list(transactions_by_payment.values())

    def _in_date_range(paid_at_str: Optional[str]) -> bool:
        if not paid_at_str:
            return False
        try:
            paid_dt = datetime.fromisoformat(paid_at_str.replace("Z", "+00:00"))
        except Exception:
            return False
        if start_date:
            try:
                sd = datetime.fromisoformat(start_date)
                if paid_dt < sd:
                    return False
            except Exception:
                pass
        if end_date:
            try:
                ed = datetime.fromisoformat(end_date)
                if paid_dt > ed:
                    return False
            except Exception:
                pass
        return True

    filtered = []
    for tx in transactions:
        p = tx["payment"]
        # filter by status
        if payment_status and (p.get("payment_status") != payment_status):
            continue
        # filter by date range
        if start_date or end_date:
            if not _in_date_range(p.get("paid_at")):
                continue
        filtered.append(tx)

    total_count = len(filtered)
    # pagination
    paged = filtered[offset: offset + limit]

    return {
        "seller_auth_id": seller_auth_id,
        "total_transactions": total_count,
        "returned": len(paged),
        "transactions": paged
    }
