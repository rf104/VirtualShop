from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import asyncpg
from db import get_db_pool

router = APIRouter()

class TryOnHistory(BaseModel):
    tryon_id: int
    user_id: Optional[int]
    product_id: Optional[int]
    tried_at: datetime
    img_url: Optional[str]

class TryOnCreate(BaseModel):
    user_id: Optional[int]
    product_id: Optional[int]
    img_url: Optional[str]

@router.post("/", response_model=TryOnHistory)
async def create_try_on(entry: TryOnCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchrow(
                "INSERT INTO try_on_history (user_id, product_id, img_url, tried_at) VALUES ($1, $2, $3, NOW()) RETURNING *",
                entry.user_id, entry.product_id, entry.img_url
            )
            return dict(result)
        except asyncpg.exceptions.ForeignKeyViolationError:
            raise HTTPException(status_code=400, detail="Foreign key constraint failed (user_id or product_id may not exist)")
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

@router.get("/", response_model=List[TryOnHistory])
async def get_all_try_ons(pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        rows = await conn.fetch("SELECT * FROM try_on_history")
        return [dict(row) for row in rows]

@router.get("/{tryon_id}", response_model=TryOnHistory)
async def get_try_on(tryon_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        result = await conn.fetchrow("SELECT * FROM try_on_history WHERE tryon_id = $1", tryon_id)
        if result:
            return dict(result)
        raise HTTPException(status_code=404, detail="Try-on record not found")

@router.delete("/{tryon_id}")
async def delete_try_on(tryon_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        result = await conn.execute("DELETE FROM try_on_history WHERE tryon_id = $1", tryon_id)
        if result == "DELETE 1":
            return {"message": "🗑️ Try-on record deleted successfully"}
        raise HTTPException(status_code=404, detail="Try-on record not found")
