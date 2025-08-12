# main.py
from fastapi import FastAPI
import logging
from db import get_db_connection_pool, pool
from routers import (
    users, product, products, orders, payments, referral,
    refunds, reports, reviews, sellers, wishlist,
    stock, promotions, product_img, order_items,
    try_on_history, model3d, image_search
)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="🛒 E-Commerce API")


@app.on_event("startup")
async def startup_event():
    await get_db_connection_pool()


@app.on_event("shutdown")
async def shutdown_event():
    if pool:
        await pool.close()
        logger.info("🔒 Database connection pool closed.")


@app.get("/")
async def read_root():
    return {"message": "🚀 FastAPI is running and connected to Supabase"}

app.include_router(users.router, prefix="/users", tags=["Users"])
app.include_router(product.router, prefix="/product", tags=["Product"])
app.include_router(products.router, prefix="/products",
                   tags=["Products with Embeddings"])
app.include_router(orders.router, prefix="/orders", tags=["Orders"])
app.include_router(order_items.router,
                   prefix="/order-items", tags=["Order Items"])
app.include_router(payments.router, prefix="/payments", tags=["Payments"])
app.include_router(referral.router, prefix="/referral", tags=["Referral"])
app.include_router(refunds.router, prefix="/refunds", tags=["Refunds"])
app.include_router(reports.router, prefix="/reports", tags=["Reports"])
app.include_router(reviews.router, prefix="/reviews", tags=["Reviews"])
app.include_router(sellers.router, prefix="/sellers", tags=["Sellers"])
app.include_router(wishlist.router, prefix="/wishlist", tags=["Wishlist"])
app.include_router(stock.router, prefix="/stock", tags=["Stock"])
app.include_router(promotions.router, prefix="/promotions",
                   tags=["Promotions"])
app.include_router(product_img.router,
                   prefix="/product-images", tags=["Product Images"])
app.include_router(try_on_history.router, prefix="/try-on",
                   tags=["Try-On History"])
app.include_router(model3d.router, prefix="/model3d", tags=["3D Models"])
app.include_router(image_search.router,
                   prefix="/image-search", tags=["Image Search"])
