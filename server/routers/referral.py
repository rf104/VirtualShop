from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import asyncpg
from db import get_db_pool

router = APIRouter()


class Referral(BaseModel):
    referral_id: int
    created_at: datetime
    status: Optional[str]


class ReferralCreate(BaseModel):
    referral_id: int
    status: Optional[str]


@router.post("/", response_model=Referral)
async def create_referral(referral: ReferralCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchrow(
                "INSERT INTO referral (referral_id, status) VALUES ($1, $2) RETURNING *",
                referral.referral_id, referral.status
            )
            return dict(result)
        except asyncpg.exceptions.ForeignKeyViolationError:
            raise HTTPException(
                status_code=400, detail="Foreign key constraint failed (referral_id must match user_id)")
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))


@router.get("/", response_model=List[Referral])
async def get_referrals(pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        results = await conn.fetch("SELECT * FROM referral")
        return [dict(row) for row in results]


@router.get("/{referral_id}", response_model=Referral)
async def get_referral(referral_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        referral = await conn.fetchrow("SELECT * FROM referral WHERE referral_id = $1", referral_id)
        if referral:
            return dict(referral)
        raise HTTPException(status_code=404, detail="Referral not found")


@router.put("/{referral_id}", response_model=Referral)
async def update_referral(referral_id: int, referral: ReferralCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        updated = await conn.fetchrow(
            "UPDATE referral SET status = $1 WHERE referral_id = $2 RETURNING *",
            referral.status, referral_id
        )
        if updated:
            return dict(updated)
        raise HTTPException(status_code=404, detail="Referral not found")


@router.delete("/{referral_id}")
async def delete_referral(referral_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        result = await conn.execute("DELETE FROM referral WHERE referral_id = $1", referral_id)
        if result == "DELETE 1":
            return {"message": "🗑️ Referral deleted successfully"}
        raise HTTPException(status_code=404, detail="Referral not found")
