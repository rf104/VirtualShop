from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import asyncpg
from db import get_db_pool

router = APIRouter()

class Product(BaseModel):
    product_id: int
    created_at: datetime
    seller_id: Optional[int]
    category_id: Optional[int]
    product_name: Optional[str]
    description: Optional[str]
    price: Optional[float]
    is_refurbished: Optional[bool]

class ProductCreate(BaseModel):
    seller_id: Optional[int]
    category_id: Optional[int]
    product_name: Optional[str]
    description: Optional[str]
    price: Optional[float]
    is_refurbished: Optional[bool]

@router.post("/", response_model=Product)
async def create_product(product: ProductCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchrow(
                "INSERT INTO product (seller_id, category_id, product_name, description, price, is_refurbished) "
                "VALUES ($1, $2, $3, $4, $5, $6) RETURNING *",
                product.seller_id, product.category_id, product.product_name,
                product.description, product.price, product.is_refurbished
            )
            return dict(result)
        except asyncpg.exceptions.ForeignKeyViolationError:
            raise HTTPException(status_code=400, detail="Foreign key constraint failed")
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

@router.get("/", response_model=List[Product])
async def get_product(pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        rows = await conn.fetch("SELECT * FROM product")
        return [dict(row) for row in rows]

@router.get("/{product_id}", response_model=Product)
async def get_product(product_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        product = await conn.fetchrow("SELECT * FROM product WHERE product_id = $1", product_id)
        if product:
            return dict(product)
        raise HTTPException(status_code=404, detail="Product not found")

@router.put("/{product_id}", response_model=Product)
async def update_product(product_id: int, product: ProductCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        updated = await conn.fetchrow(
            "UPDATE product SET seller_id = $1, category_id = $2, product_name = $3, description = $4, price = $5, is_refurbished = $6 "
            "WHERE product_id = $7 RETURNING *",
            product.seller_id, product.category_id, product.product_name,
            product.description, product.price, product.is_refurbished, product_id
        )
        if updated:
            return dict(updated)
        raise HTTPException(status_code=404, detail="Product not found")

@router.delete("/{product_id}")
async def delete_product(product_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        result = await conn.execute("DELETE FROM product WHERE product_id = $1", product_id)
        if result == "DELETE 1":
            return {"message": "🗑️ Product deleted successfully"}
        raise HTTPException(status_code=404, detail="Product not found")
