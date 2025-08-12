from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import asyncpg
import logging
from db import get_db_pool

logger = logging.getLogger(__name__)

router = APIRouter()


class Order(BaseModel):
    order_id: int
    created_at: datetime
    order_date: Optional[datetime] = None
    status: Optional[str] = None
    user_id: Optional[int] = None


class OrderCreate(BaseModel):
    order_date: Optional[datetime] = None
    status: Optional[str] = None
    user_id: Optional[int] = None


@router.post("/", response_model=Order)
async def create_order(order: OrderCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as connection:
        try:
            new_order = await connection.fetchrow(
                "INSERT INTO public.orders (order_date, status, user_id) VALUES ($1, $2, $3) RETURNING *",
                order.order_date, order.status, order.user_id
            )
            if new_order:
                return dict(new_order)
        except Exception as e:
            logger.error(f"Error creating order: {e}")
            raise HTTPException(
                status_code=500, detail="Failed to create order")
    raise HTTPException(status_code=500, detail="Failed to create order")


@router.get("/", response_model=List[Order])
async def read_all_orders(pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as connection:
        try:
            orders = await connection.fetch("SELECT * FROM public.orders")
            return [dict(order) for order in orders]
        except Exception as e:
            logger.error(f"Error reading orders: {e}")
            raise HTTPException(
                status_code=500, detail="Failed to retrieve orders")


@router.get("/{order_id}", response_model=Order)
async def read_order(order_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as connection:
        try:
            order = await connection.fetchrow("SELECT * FROM public.orders WHERE order_id = $1", order_id)
            if order:
                return dict(order)
        except Exception as e:
            logger.error(f"Error reading order {order_id}: {e}")
            raise HTTPException(
                status_code=500, detail="Failed to retrieve order")
    raise HTTPException(status_code=404, detail="Order not found")


@router.put("/{order_id}", response_model=Order)
async def update_order(order_id: int, order: OrderCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as connection:
        try:
            updated_order = await connection.fetchrow(
                "UPDATE public.orders SET order_date = $1, status = $2, user_id = $3 WHERE order_id = $4 RETURNING *",
                order.order_date, order.status, order.user_id, order_id
            )
            if updated_order:
                return dict(updated_order)
        except Exception as e:
            logger.error(f"Error updating order {order_id}: {e}")
            raise HTTPException(
                status_code=500, detail="Failed to update order")
    raise HTTPException(status_code=404, detail="Order not found")


@router.delete("/{order_id}")
async def delete_order(order_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as connection:
        try:
            result = await connection.execute("DELETE FROM public.orders WHERE order_id = $1", order_id)
            if result == "DELETE 1":
                return {"message": "🗑️ Order deleted successfully"}
        except Exception as e:
            logger.error(f"Error deleting order {order_id}: {e}")
            raise HTTPException(
                status_code=500, detail="Failed to delete order")
    raise HTTPException(status_code=404, detail="Order not found")
