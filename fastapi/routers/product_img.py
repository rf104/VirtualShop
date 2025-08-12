from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import asyncpg
from db import get_db_pool

router = APIRouter()

class ProductImage(BaseModel):
    img_id: int
    product_id: Optional[int]
    img_url: Optional[str]
    type: Optional[str]
    created_at: datetime

class ProductImageCreate(BaseModel):
    product_id: Optional[int]
    img_url: Optional[str]
    type: Optional[str]

@router.post("/", response_model=ProductImage)
async def create_image(image: ProductImageCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchrow(
                "INSERT INTO product_img (product_id, img_url, type) VALUES ($1, $2, $3) RETURNING *",
                image.product_id, image.img_url, image.type
            )
            return dict(result)
        except asyncpg.exceptions.ForeignKeyViolationError:
            raise HTTPException(status_code=400, detail="Foreign key constraint failed (product_id may not exist)")
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

@router.get("/", response_model=List[ProductImage])
async def get_images(pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        rows = await conn.fetch("SELECT * FROM product_img")
        return [dict(row) for row in rows]

@router.get("/{img_id}", response_model=ProductImage)
async def get_image(img_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        image = await conn.fetchrow("SELECT * FROM product_img WHERE img_id = $1", img_id)
        if image:
            return dict(image)
        raise HTTPException(status_code=404, detail="Product image not found")

@router.put("/{img_id}", response_model=ProductImage)
async def update_image(img_id: int, image: ProductImageCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        updated = await conn.fetchrow(
            "UPDATE product_img SET product_id = $1, img_url = $2, type = $3 WHERE img_id = $4 RETURNING *",
            image.product_id, image.img_url, image.type, img_id
        )
        if updated:
            return dict(updated)
        raise HTTPException(status_code=404, detail="Product image not found")

@router.delete("/{img_id}")
async def delete_image(img_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        result = await conn.execute("DELETE FROM product_img WHERE img_id = $1", img_id)
        if result == "DELETE 1":
            return {"message": "🗑️ Product image deleted successfully"}
        raise HTTPException(status_code=404, detail="Product image not found")
