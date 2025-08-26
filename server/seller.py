from fastapi import APIRouter, HTTPException, Depends

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