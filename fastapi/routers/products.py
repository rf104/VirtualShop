from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import asyncpg
from db import get_db_pool

router = APIRouter()

class Products(BaseModel):
    id: int
    name: str
    description: Optional[str]
    price: float
    category: str
    image_url: str
    weather: Optional[str]
    temp: Optional[str]
    event: Optional[str]
    rating: Optional[float]
    created_at: datetime
    updated_at: datetime

class ProductsCreate(BaseModel):
    name: str
    description: Optional[str]
    price: float
    category: str
    image_url: str
    weather: Optional[str]
    temp: Optional[str]
    event: Optional[str]
    rating: Optional[float]

@router.post("/", response_model=Products)
async def create_products(product: ProductsCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        result = await conn.fetchrow(
            "INSERT INTO products (name, description, price, category, image_url, weather, temp, event, rating) "
            "VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING *",
            product.name, product.description, product.price, product.category,
            product.image_url, product.weather, product.temp, product.event, product.rating
        )
        return dict(result)

@router.get("/", response_model=List[Products])
async def get_all_products(pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        results = await conn.fetch("SELECT * FROM products")
        return [dict(row) for row in results]

@router.get("/{id}", response_model=Products)
async def get_product_by_id(id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        product = await conn.fetchrow("SELECT * FROM products WHERE id = $1", id)
        if product:
            return dict(product)
        raise HTTPException(status_code=404, detail="Product not found")

@router.put("/{id}", response_model=Products)
async def update_product(id: int, product: ProductsCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        updated = await conn.fetchrow(
            "UPDATE products SET name = $1, description = $2, price = $3, category = $4, image_url = $5, "
            "weather = $6, temp = $7, event = $8, rating = $9, updated_at = timezone('utc', now()) WHERE id = $10 RETURNING *",
            product.name, product.description, product.price, product.category,
            product.image_url, product.weather, product.temp, product.event, product.rating, id
        )
        if updated:
            return dict(updated)
        raise HTTPException(status_code=404, detail="Product not found")

@router.delete("/{id}")
async def delete_product(id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        result = await conn.execute("DELETE FROM products WHERE id = $1", id)
        if result == "DELETE 1":
            return {"message": "🗑️ Product deleted successfully"}
        raise HTTPException(status_code=404, detail="Product not found")
