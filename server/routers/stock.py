from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import asyncpg
from db import get_db_pool

router = APIRouter()

class Stock(BaseModel):
    stock_id: int
    created_at: datetime
    product_id: Optional[int]
    quantity: Optional[int]
    availability: Optional[bool]

class StockCreate(BaseModel):
    product_id: Optional[int]
    quantity: Optional[int]
    availability: Optional[bool]

@router.post("/", response_model=Stock)
async def create_stock(stock: StockCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchrow(
                "INSERT INTO stock (product_id, quantity, availability) VALUES ($1, $2, $3) RETURNING *",
                stock.product_id, stock.quantity, stock.availability
            )
            return dict(result)
        except asyncpg.exceptions.ForeignKeyViolationError:
            raise HTTPException(status_code=400, detail="Foreign key constraint failed (product_id may not exist)")
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

@router.get("/", response_model=List[Stock])
async def get_stock(pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        rows = await conn.fetch("SELECT * FROM stock")
        return [dict(row) for row in rows]

@router.get("/{stock_id}", response_model=Stock)
async def get_stock_item(stock_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        stock = await conn.fetchrow("SELECT * FROM stock WHERE stock_id = $1", stock_id)
        if stock:
            return dict(stock)
        raise HTTPException(status_code=404, detail="Stock item not found")

@router.put("/{stock_id}", response_model=Stock)
async def update_stock(stock_id: int, stock: StockCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        updated = await conn.fetchrow(
            "UPDATE stock SET product_id = $1, quantity = $2, availability = $3 WHERE stock_id = $4 RETURNING *",
            stock.product_id, stock.quantity, stock.availability, stock_id
        )
        if updated:
            return dict(updated)
        raise HTTPException(status_code=404, detail="Stock item not found")

@router.delete("/{stock_id}")
async def delete_stock(stock_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        result = await conn.execute("DELETE FROM stock WHERE stock_id = $1", stock_id)
        if result == "DELETE 1":
            return {"message": "🗑️ Stock item deleted successfully"}
        raise HTTPException(status_code=404, detail="Stock item not found")
