from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import asyncpg
from db import get_db_pool

router = APIRouter()

class OrderItem(BaseModel):
    item_id: int
    created_at: datetime
    order_id: Optional[int]
    poduct_id: Optional[int]
    quantity: Optional[int]
    price: Optional[str]

class OrderItemCreate(BaseModel):
    order_id: Optional[int]
    poduct_id: Optional[int]
    quantity: Optional[int]
    price: Optional[str]

@router.post("/", response_model=OrderItem)
async def create_order_item(item: OrderItemCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchrow(
                "INSERT INTO order_items (order_id, poduct_id, quantity, price) VALUES ($1, $2, $3, $4) RETURNING *",
                item.order_id, item.poduct_id, item.quantity, item.price
            )
            return dict(result)
        except asyncpg.exceptions.ForeignKeyViolationError:
            raise HTTPException(status_code=400, detail="Foreign key constraint failed (order_id or poduct_id may not exist)")
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

@router.get("/", response_model=List[OrderItem])
async def get_order_items(pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        rows = await conn.fetch("SELECT * FROM order_items")
        return [dict(row) for row in rows]

@router.get("/{item_id}", response_model=OrderItem)
async def get_order_item(item_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        item = await conn.fetchrow("SELECT * FROM order_items WHERE item_id = $1", item_id)
        if item:
            return dict(item)
        raise HTTPException(status_code=404, detail="Order item not found")

@router.put("/{item_id}", response_model=OrderItem)
async def update_order_item(item_id: int, item: OrderItemCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        updated = await conn.fetchrow(
            "UPDATE order_items SET order_id = $1, poduct_id = $2, quantity = $3, price = $4 WHERE item_id = $5 RETURNING *",
            item.order_id, item.poduct_id, item.quantity, item.price, item_id
        )
        if updated:
            return dict(updated)
        raise HTTPException(status_code=404, detail="Order item not found")

@router.delete("/{item_id}")
async def delete_order_item(item_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        result = await conn.execute("DELETE FROM order_items WHERE item_id = $1", item_id)
        if result == "DELETE 1":
            return {"message": "🗑️ Order item deleted successfully"}
        raise HTTPException(status_code=404, detail="Order item not found")
