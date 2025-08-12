from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import asyncpg
from db import get_db_pool

router = APIRouter()

class Promotion(BaseModel):
    promo_id: int
    created_at: datetime
    seller_id: Optional[int]
    discount_percent: Optional[str]
    valid_until: Optional[datetime]

class PromotionCreate(BaseModel):
    seller_id: Optional[int]
    discount_percent: Optional[str]
    valid_until: Optional[datetime]

@router.post("/", response_model=Promotion)
async def create_promotion(promo: PromotionCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchrow(
                """
                INSERT INTO promotions (seller_id, discount_percent, valid_until)
                VALUES ($1, $2, $3) RETURNING *
                """,
                promo.seller_id, promo.discount_percent, promo.valid_until
            )
            return dict(result)
        except asyncpg.exceptions.ForeignKeyViolationError:
            raise HTTPException(status_code=400, detail="Foreign key constraint failed (seller_id may not exist)")
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

@router.get("/", response_model=List[Promotion])
async def get_promotions(pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        rows = await conn.fetch("SELECT * FROM promotions")
        return [dict(row) for row in rows]

@router.get("/{promo_id}", response_model=Promotion)
async def get_promotion(promo_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        promo = await conn.fetchrow("SELECT * FROM promotions WHERE promo_id = $1", promo_id)
        if promo:
            return dict(promo)
        raise HTTPException(status_code=404, detail="Promotion not found")

@router.put("/{promo_id}", response_model=Promotion)
async def update_promotion(promo_id: int, promo: PromotionCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        updated = await conn.fetchrow(
            """
            UPDATE promotions SET seller_id = $1, discount_percent = $2, valid_until = $3
            WHERE promo_id = $4 RETURNING *
            """,
            promo.seller_id, promo.discount_percent, promo.valid_until, promo_id
        )
        if updated:
            return dict(updated)
        raise HTTPException(status_code=404, detail="Promotion not found")

@router.delete("/{promo_id}")
async def delete_promotion(promo_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        result = await conn.execute("DELETE FROM promotions WHERE promo_id = $1", promo_id)
        if result == "DELETE 1":
            return {"message": "🗑️ Promotion deleted successfully"}
        raise HTTPException(status_code=404, detail="Promotion not found")
