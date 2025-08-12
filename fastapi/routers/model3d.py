from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import asyncpg
from db import get_db_pool

router = APIRouter()

class Model3D(BaseModel):
    model_id: int
    created_at: datetime
    product_id: Optional[int]
    file_format: Optional[str]
    url: Optional[str]

class Model3DCreate(BaseModel):
    product_id: Optional[int]
    file_format: Optional[str]
    url: Optional[str]

@router.post("/", response_model=Model3D)
async def create_model(model: Model3DCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchrow(
                'INSERT INTO "3dmodels" (product_id, file_format, url) VALUES ($1, $2, $3) RETURNING *',
                model.product_id, model.file_format, model.url
            )
            return dict(result)
        except asyncpg.exceptions.ForeignKeyViolationError:
            raise HTTPException(status_code=400, detail="Foreign key constraint failed (product_id may not exist)")
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

@router.get("/", response_model=List[Model3D])
async def get_models(pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        rows = await conn.fetch('SELECT * FROM "3dmodels"')
        return [dict(row) for row in rows]

@router.get("/{model_id}", response_model=Model3D)
async def get_model(model_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        model = await conn.fetchrow('SELECT * FROM "3dmodels" WHERE model_id = $1', model_id)
        if model:
            return dict(model)
        raise HTTPException(status_code=404, detail="3D model not found")

@router.put("/{model_id}", response_model=Model3D)
async def update_model(model_id: int, model: Model3DCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        updated = await conn.fetchrow(
            'UPDATE "3dmodels" SET product_id = $1, file_format = $2, url = $3 WHERE model_id = $4 RETURNING *',
            model.product_id, model.file_format, model.url, model_id
        )
        if updated:
            return dict(updated)
        raise HTTPException(status_code=404, detail="3D model not found")

@router.delete("/{model_id}")
async def delete_model(model_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        result = await conn.execute('DELETE FROM "3dmodels" WHERE model_id = $1', model_id)
        if result == "DELETE 1":
            return {"message": "🗑️ 3D model deleted successfully"}
        raise HTTPException(status_code=404, detail="3D model not found")
