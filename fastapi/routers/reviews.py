from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional, List
import asyncpg
from db import get_db_pool

router = APIRouter()

class Review(BaseModel):
    review_id: int
    product_id: int
    rating: Optional[int]
    content: Optional[str]
    media_url: Optional[str]
    user_id: Optional[int]

class ReviewCreate(BaseModel):
    product_id: int
    rating: Optional[int]
    content: Optional[str]
    media_url: Optional[str]
    user_id: Optional[int]

@router.post("/", response_model=Review)
async def create_review(review: ReviewCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchrow(
                "INSERT INTO reviews (product_id, rating, content, media_url, user_id) VALUES ($1, $2, $3, $4, $5) RETURNING *",
                review.product_id, review.rating, review.content, review.media_url, review.user_id
            )
            return dict(result)
        except asyncpg.exceptions.ForeignKeyViolationError:
            raise HTTPException(status_code=400, detail="Foreign key constraint failed (product_id or user_id may not exist)")
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

@router.get("/", response_model=List[Review])
async def get_reviews(pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        rows = await conn.fetch("SELECT * FROM reviews")
        return [dict(row) for row in rows]

@router.get("/{review_id}", response_model=Review)
async def get_review(review_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        review = await conn.fetchrow("SELECT * FROM reviews WHERE review_id = $1", review_id)
        if review:
            return dict(review)
        raise HTTPException(status_code=404, detail="Review not found")

@router.put("/{review_id}", response_model=Review)
async def update_review(review_id: int, review: ReviewCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        updated = await conn.fetchrow(
            "UPDATE reviews SET product_id = $1, rating = $2, content = $3, media_url = $4, user_id = $5 WHERE review_id = $6 RETURNING *",
            review.product_id, review.rating, review.content, review.media_url, review.user_id, review_id
        )
        if updated:
            return dict(updated)
        raise HTTPException(status_code=404, detail="Review not found")

@router.delete("/{review_id}")
async def delete_review(review_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        result = await conn.execute("DELETE FROM reviews WHERE review_id = $1", review_id)
        if result == "DELETE 1":
            return {"message": "🗑️ Review deleted successfully"}
        raise HTTPException(status_code=404, detail="Review not found")
