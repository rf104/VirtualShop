from fastapi import APIRouter, HTTPException, Depends, Header
from typing import Optional
import os
import base64
import json
import httpx
from datetime import datetime
from decimal import Decimal
import re

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


@router.get("/health")
def health_check():
    """Simple health check endpoint."""
    return {"status": "ok", "message": "Seller API is running"}


@router.get("/{seller_id}")
def get_seller(seller_id: str, client=Depends(get_supabase_client)):
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
def get_seller_products(seller_id: str, client=Depends(get_supabase_client)):
    """
    Get all products belonging to a seller.
    """
    # Use auth_id instead of seller_id to match the product model
    prod_res = (
        client.table("products")
        .select(
            "id,auth_id,name,description,category,brand,price,stock,condition,dimensions,weight_kg,is_featured,is_in_stock,created_at,updated_at,rating"
        )
        .eq("auth_id", seller_id)
        .execute()
    )

    if getattr(prod_res, "error", None):
        raise HTTPException(status_code=400, detail=str(prod_res.error))

    prods = prod_res.data or []
    out = []

    # For each product, fetch the first image URL like in the main products endpoint
    for p in prods:
        img_res = (
            client.table("product_images")
            .select("image_url")
            .eq("product_id", p["id"])
            .order("created_at", desc=False)
            .limit(1)
            .execute()
        )
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


def _short_code_from_uuid(uuid_str: Optional[str], prefix: str) -> Optional[str]:
    """Create a short human-friendly code from a UUID.

    Takes last 6 hex chars (excluding hyphens) and uppercases.
    Example: 550e8400-e29b-41d4-a716-446655440000 -> 440000 -> ORD-440000
    Returns None if input invalid.
    """
    if not uuid_str:
        return None
    try:
        # strip non-hex
        compact = re.sub(r"[^0-9a-fA-F]", "", uuid_str)
        if len(compact) < 6:
            return None
        return f"{prefix}-{compact[-6:]}".upper()
    except Exception:
        return None


def _short_txn_id(raw: Optional[str]) -> Optional[str]:
    """Shorten an arbitrary transaction id (could already be short).
    If looks like a UUID reuse _short_code_from_uuid. Otherwise take first 4 and last 4 chars.
    """
    if not raw:
        return None
    if re.match(r"^[0-9a-fA-F-]{30,}$", raw):  # likely UUID-like
        sc = _short_code_from_uuid(raw, "TXN")
        if sc:
            return sc
    raw = raw.strip()
    if len(raw) <= 12:
        return raw.upper()
    return f"TXN-{raw[:4]}...{raw[-4:]}".upper()


def _fetch_buyer_info(client, auth_ref: Optional[str]):
    """Attempt to fetch buyer info from available tables without raising on missing table.

    Returns (buyer_info_dict, display_name or None)
    Priority:
      1. profiles(full_name,email,profile_image) if table exists
      2. users(name,email,profile_image) custom table
    Swallows table-not-exist errors (42P01) and proceeds to fallback.
    """
    if not auth_ref:
        return {}, None

    # Try profiles
    try:
        prof = (
            client.table("profiles")
            .select("id, full_name, email, profile_image")
            .eq("id", auth_ref)
            .single()
            .execute()
        )
        if not getattr(prof, "error", None) and prof.data:
            data = prof.data
            dn = data.get("full_name") or data.get("email")
            return data, dn
        # If explicit error other than table missing, just move to fallback
    except Exception as e:
        # Detect table missing pattern if Supabase returns dict error
        if isinstance(e, dict) and e.get("code") == "42P01":
            pass
        else:
            # Log and continue
            print(f"Debug: profiles lookup exception (ignored): {e}")

    # Fallback to users table
    try:
        usr = (
            client.table("users")
            .select("auth_id, name, email, profile_image")
            .eq("auth_id", auth_ref)
            .single()
            .execute()
        )
        if not getattr(usr, "error", None) and usr.data:
            row = usr.data
            info = {
                "id": row.get("auth_id"),
                "full_name": row.get("name"),
                "email": row.get("email"),
                "profile_image": row.get("profile_image"),
            }
            dn = info.get("full_name") or info.get("email")
            return info, dn
    except Exception as e:
        print(f"Debug: users fallback lookup exception (ignored): {e}")
    return {}, None


@router.get("/{seller_id}/transactions")
def get_seller_transactions(seller_id: str, client=Depends(get_supabase_client)):
    """
    Get all transactions (payments) for a seller's orders.
    """
    print(
        f"🔄 API CALL: Fetching transactions for seller with id={seller_id}"
    )  # Debug print
    try:
        # 1. Seller products
        products_res = (
            client.table("products").select("id").eq("auth_id", seller_id).execute()
        )
        if getattr(products_res, "error", None):
            raise HTTPException(
                status_code=400, detail=f"Error fetching products: {products_res.error}"
            )
        products = products_res.data or []
        if not products:
            return {"seller_id": seller_id, "transactions": []}

        product_ids = [p["id"] for p in products]

        # 2. Order items for those products
        order_items_res = (
            client.table("order_items")
            .select("id, order_id, product_id, quantity, unit_price, created_at")
            .in_("product_id", product_ids)
            .execute()
        )
        if getattr(order_items_res, "error", None):
            raise HTTPException(
                status_code=400,
                detail=f"Error fetching order items: {order_items_res.error}",
            )
        order_items = order_items_res.data or []
        if not order_items:
            return {"seller_id": seller_id, "transactions": []}

        order_ids = list({oi["order_id"] for oi in order_items})

        # 3. Payments for those orders
        payments_res = (
            client.table("payments")
            .select(
                """
                id, order_id, payer_auth_id, amount, payment_method, payment_status,
                transaction_id, paid_at, refunded, refunded_at, refund_reason, created_at, updated_at
                """
            )
            .in_("order_id", order_ids)
            .order("created_at", desc=True)
            .execute()
        )
        if getattr(payments_res, "error", None):
            raise HTTPException(
                status_code=400, detail=f"Error fetching payments: {payments_res.error}"
            )
        payments = payments_res.data or []

        enriched = []
        for pay in payments:
            # Order info
            order_res = (
                client.table("orders")
                .select("id, user_auth_id, status, subtotal, total, created_at")
                .eq("id", pay["order_id"])
                .single()
                .execute()
            )
            order_info = (
                order_res.data
                if (not getattr(order_res, "error", None) and order_res.data)
                else {}
            )

            # Seller items for this order
            seller_order_items = [
                oi for oi in order_items if oi["order_id"] == pay["order_id"]
            ]
            seller_item_total = sum(
                Decimal(str(oi["unit_price"])) * oi["quantity"]
                for oi in seller_order_items
            )

            # Buyer info resolution
            auth_ref = pay.get("payer_auth_id") or order_info.get("user_auth_id")
            buyer_info, buyer_display_name = _fetch_buyer_info(client, auth_ref)
            if not buyer_display_name:
                buyer_display_name = "Unknown Buyer"

            # Product details for seller items
            seller_products = []
            for oi in seller_order_items:
                prod_res = (
                    client.table("products")
                    .select("id, name, price")
                    .eq("id", oi["product_id"])
                    .single()
                    .execute()
                )
                if not getattr(prod_res, "error", None) and prod_res.data:
                    info = prod_res.data
                    info.update(
                        {
                            "quantity": oi["quantity"],
                            "unit_price": oi["unit_price"],
                            "item_total": str(
                                Decimal(str(oi["unit_price"])) * oi["quantity"]
                            ),
                        }
                    )
                    seller_products.append(info)

            order_code = (
                _short_code_from_uuid(order_info.get("id"), "ORD")
                if order_info
                else None
            )
            txn_code = _short_txn_id(pay.get("transaction_id") or pay.get("id"))

            enriched.append(
                {
                    **pay,
                    "order_info": order_info,
                    "buyer_info": buyer_info,
                    "buyer_display_name": buyer_display_name,
                    "order_code": order_code,
                    "transaction_code": txn_code,
                    "seller_items": seller_products,
                    "seller_item_total": str(seller_item_total),
                    "seller_item_count": len(seller_order_items),
                }
            )

        return {
            "seller_id": seller_id,
            "total_transactions": len(enriched),
            "transactions": enriched,
        }
    except HTTPException:
        raise
    except Exception as e:
        print(f"Debug: Exception in get_seller_transactions: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {e}")


@router.get("/{seller_id}/reviews")
def get_seller_reviews(seller_id: str, client=Depends(get_supabase_client)):
    """
    Get all reviews for a seller's products.
    """
    print(f"🔄 API CALL: Fetching reviews for seller with id={seller_id}")

    try:
        # 1. Get seller's products
        products_res = (
            client.table("products")
            .select("id, name, category, price")
            .eq("auth_id", seller_id)
            .execute()
        )
        if getattr(products_res, "error", None):
            raise HTTPException(
                status_code=400, detail=f"Error fetching products: {products_res.error}"
            )
        products = products_res.data or []
        if not products:
            return {
                "seller_id": seller_id,
                "total_reviews": 0,
                "average_rating": 0.0,
                "rating_counts": {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
                "reviews": [],
            }

        product_ids = [p["id"] for p in products]
        product_map = {p["id"]: p for p in products}

        # 2. Get reviews for these products
        reviews_res = (
            client.table("reviews")
            .select("id, product_id, user_auth_id, rating, review, created_at")
            .in_("product_id", product_ids)
            .order("created_at", desc=True)
            .execute()
        )
        if getattr(reviews_res, "error", None):
            raise HTTPException(
                status_code=400, detail=f"Error fetching reviews: {reviews_res.error}"
            )
        reviews = reviews_res.data or []

        # 3. Enrich reviews with user and product info & accumulate stats
        enriched_reviews = []
        rating_counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
        rating_sum = 0
        for review in reviews:
            # Get reviewer info
            reviewer_info, reviewer_name = _fetch_buyer_info(
                client, review["user_auth_id"]
            )
            if not reviewer_name:
                reviewer_name = "Anonymous"

            # Get product info
            product = product_map.get(review["product_id"], {})

            # Format the review data
            enriched_review = {
                "id": review["id"],
                "rating": review["rating"],
                "review": review["review"],
                "date": review["created_at"],
                "name": reviewer_name,
                "email": reviewer_info.get("email"),
                "phone": reviewer_info.get("phone"),
                # Provide both profile_image and avatar for compatibility; frontend will prefer profile_image
                "profile_image": reviewer_info.get("profile_image")
                or reviewer_info.get("avatar"),
                "avatar": reviewer_info.get("profile_image")
                or reviewer_info.get("avatar"),
                "verified": True,  # Assuming all reviews from verified purchases
                "product": {
                    "id": product.get("id"),
                    "name": product.get("name"),
                    "category": product.get("category"),
                    "price": str(product.get("price", 0)),
                },
                "reviewer_info": reviewer_info,
            }
            # Stats accumulation
            try:
                r_val = int(review.get("rating") or 0)
                if r_val in rating_counts:
                    rating_counts[r_val] += 1
                    rating_sum += r_val
            except Exception:
                pass

            enriched_reviews.append(enriched_review)

        total_reviews = len(enriched_reviews)
        average_rating = round(rating_sum / total_reviews, 2) if total_reviews else 0.0

        return {
            "seller_id": seller_id,
            "total_reviews": total_reviews,
            "average_rating": average_rating,
            "rating_counts": rating_counts,
            "reviews": enriched_reviews,
        }

    except HTTPException:
        raise
    except Exception as e:
        print(f"Debug: Exception in get_seller_reviews: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {e}")
