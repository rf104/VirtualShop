from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import asyncpg
from db import get_db_pool

router = APIRouter()

class Payment(BaseModel):
    payment_id: int
    created_at: datetime
    order_id: Optional[int]
    method: Optional[str]
    amount: Optional[float]
    status: Optional[str]

class PaymentCreate(BaseModel):
    order_id: Optional[int]
    method: Optional[str]
    amount: Optional[float]
    status: Optional[str]

@router.post("/", response_model=Payment)
async def create_payment(payment: PaymentCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchrow(
                "INSERT INTO payments (order_id, method, amount, status) VALUES ($1, $2, $3, $4) RETURNING *",
                payment.order_id, payment.method, payment.amount, payment.status
            )
            return dict(result)
        except asyncpg.exceptions.ForeignKeyViolationError:
            raise HTTPException(status_code=400, detail="Foreign key constraint failed (e.g., order_id does not exist)")
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

@router.get("/", response_model=List[Payment])
async def get_payments(pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        rows = await conn.fetch("SELECT * FROM payments")
        return [dict(row) for row in rows]

@router.get("/{payment_id}", response_model=Payment)
async def get_payment(payment_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        payment = await conn.fetchrow("SELECT * FROM payments WHERE payment_id = $1", payment_id)
        if payment:
            return dict(payment)
        raise HTTPException(status_code=404, detail="Payment not found")

@router.put("/{payment_id}", response_model=Payment)
async def update_payment(payment_id: int, payment: PaymentCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        updated = await conn.fetchrow(
            "UPDATE payments SET order_id = $1, method = $2, amount = $3, status = $4 WHERE payment_id = $5 RETURNING *",
            payment.order_id, payment.method, payment.amount, payment.status, payment_id
        )
        if updated:
            return dict(updated)
        raise HTTPException(status_code=404, detail="Payment not found")

@router.delete("/{payment_id}")
async def delete_payment(payment_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        result = await conn.execute("DELETE FROM payments WHERE payment_id = $1", payment_id)
        if result == "DELETE 1":
            return {"message": "🗑️ Payment deleted successfully"}
        raise HTTPException(status_code=404, detail="Payment not found")
