from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import asyncpg
from db import get_db_pool

router = APIRouter()

class Seller(BaseModel):
    seller_id: int
    created_at: datetime
    user_id: Optional[int]
    shop_name: Optional[str]
    shop_email: Optional[str]
    shop_contact: Optional[str]

class SellerCreate(BaseModel):
    user_id: Optional[int]
    shop_name: Optional[str]
    shop_email: Optional[str]
    shop_contact: Optional[str]

@router.post("/", response_model=Seller)
async def create_seller(seller: SellerCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchrow(
                "INSERT INTO sellers (user_id, shop_name, shop_email, shop_contact) VALUES ($1, $2, $3, $4) RETURNING *",
                seller.user_id, seller.shop_name, seller.shop_email, seller.shop_contact
            )
            return dict(result)
        except asyncpg.exceptions.ForeignKeyViolationError:
            raise HTTPException(status_code=400, detail="Foreign key constraint failed (user_id may not exist)")
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

@router.get("/", response_model=List[Seller])
async def get_sellers(pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        rows = await conn.fetch("SELECT * FROM sellers")
        return [dict(row) for row in rows]

@router.get("/{seller_id}", response_model=Seller)
async def get_seller(seller_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        seller = await conn.fetchrow("SELECT * FROM sellers WHERE seller_id = $1", seller_id)
        if seller:
            return dict(seller)
        raise HTTPException(status_code=404, detail="Seller not found")

@router.put("/{seller_id}", response_model=Seller)
async def update_seller(seller_id: int, seller: SellerCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        updated = await conn.fetchrow(
            "UPDATE sellers SET user_id = $1, shop_name = $2, shop_email = $3, shop_contact = $4 WHERE seller_id = $5 RETURNING *",
            seller.user_id, seller.shop_name, seller.shop_email, seller.shop_contact, seller_id
        )
        if updated:
            return dict(updated)
        raise HTTPException(status_code=404, detail="Seller not found")

@router.delete("/{seller_id}")
async def delete_seller(seller_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        result = await conn.execute("DELETE FROM sellers WHERE seller_id = $1", seller_id)
        if result == "DELETE 1":
            return {"message": "🗑️ Seller deleted successfully"}
        raise HTTPException(status_code=404, detail="Seller not found")
