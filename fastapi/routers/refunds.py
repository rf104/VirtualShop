from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import asyncpg
from db import get_db_pool

router = APIRouter()

class Refund(BaseModel):
    refund_id: int
    created_at: datetime
    order_id: int
    reason: Optional[str]
    status: Optional[str]
    requested_at: Optional[datetime]

class RefundCreate(BaseModel):
    order_id: int
    reason: Optional[str]
    status: Optional[str]

@router.post("/", response_model=Refund)
async def create_refund(refund: RefundCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchrow(
                "INSERT INTO refunds (order_id, reason, status) VALUES ($1, $2, $3) RETURNING *",
                refund.order_id, refund.reason, refund.status
            )
            return dict(result)
        except asyncpg.exceptions.ForeignKeyViolationError:
            raise HTTPException(status_code=400, detail="Foreign key constraint failed (order_id may not exist)")
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

@router.get("/", response_model=List[Refund])
async def get_refunds(pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        rows = await conn.fetch("SELECT * FROM refunds")
        return [dict(row) for row in rows]

@router.get("/{refund_id}", response_model=Refund)
async def get_refund(refund_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        refund = await conn.fetchrow("SELECT * FROM refunds WHERE refund_id = $1", refund_id)
        if refund:
            return dict(refund)
        raise HTTPException(status_code=404, detail="Refund not found")

@router.put("/{refund_id}", response_model=Refund)
async def update_refund(refund_id: int, refund: RefundCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        updated = await conn.fetchrow(
            "UPDATE refunds SET order_id = $1, reason = $2, status = $3 WHERE refund_id = $4 RETURNING *",
            refund.order_id, refund.reason, refund.status, refund_id
        )
        if updated:
            return dict(updated)
        raise HTTPException(status_code=404, detail="Refund not found")

@router.delete("/{refund_id}")
async def delete_refund(refund_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        result = await conn.execute("DELETE FROM refunds WHERE refund_id = $1", refund_id)
        if result == "DELETE 1":
            return {"message": "✅ Refund deleted successfully"}
        raise HTTPException(status_code=404, detail="Refund not found")
