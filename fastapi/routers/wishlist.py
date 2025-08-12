from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import asyncpg
from db import get_db_pool

router = APIRouter()

class WishlistItem(BaseModel):
    wishlist_id: int
    created_at: datetime
    product_id: Optional[int]
    user_id: Optional[int]

class WishlistCreate(BaseModel):
    product_id: Optional[int]
    user_id: Optional[int]

@router.post("/", response_model=WishlistItem)
async def create_wishlist_item(item: WishlistCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchrow(
                "INSERT INTO wishlist (product_id, user_id) VALUES ($1, $2) RETURNING *",
                item.product_id, item.user_id
            )
            return dict(result)
        except asyncpg.exceptions.ForeignKeyViolationError:
            raise HTTPException(status_code=400, detail="Foreign key constraint failed (product_id or user_id may not exist)")
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

@router.get("/", response_model=List[WishlistItem])
async def get_wishlist(pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        rows = await conn.fetch("SELECT * FROM wishlist")
        return [dict(row) for row in rows]

@router.get("/{wishlist_id}", response_model=WishlistItem)
async def get_wishlist_item(wishlist_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        item = await conn.fetchrow("SELECT * FROM wishlist WHERE wishlist_id = $1", wishlist_id)
        if item:
            return dict(item)
        raise HTTPException(status_code=404, detail="Wishlist item not found")

@router.put("/{wishlist_id}", response_model=WishlistItem)
async def update_wishlist_item(wishlist_id: int, item: WishlistCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        updated = await conn.fetchrow(
            "UPDATE wishlist SET product_id = $1, user_id = $2 WHERE wishlist_id = $3 RETURNING *",
            item.product_id, item.user_id, wishlist_id
        )
        if updated:
            return dict(updated)
        raise HTTPException(status_code=404, detail="Wishlist item not found")

@router.delete("/{wishlist_id}")
async def delete_wishlist_item(wishlist_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        result = await conn.execute("DELETE FROM wishlist WHERE wishlist_id = $1", wishlist_id)
        if result == "DELETE 1":
            return {"message": "🗑️ Wishlist item deleted successfully"}
        raise HTTPException(status_code=404, detail="Wishlist item not found")
