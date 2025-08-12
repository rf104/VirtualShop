from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import asyncpg
from db import get_db_pool

router = APIRouter()

# 🔧 Response model
class User(BaseModel):
    user_id: int
    created_at: datetime
    name: Optional[str]
    email: Optional[str]
    phone: Optional[str]
    user_type: Optional[str]

# 🔧 Request model
class UserCreate(BaseModel):
    name: Optional[str]
    email: Optional[str]
    phone: Optional[str]
    user_type: Optional[str]

# ✅ Create user
@router.post("/", response_model=User)
async def create_user(user: UserCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        result = await conn.fetchrow(
            "INSERT INTO users (name, email, phone, user_type) VALUES ($1, $2, $3, $4) RETURNING *",
            user.name, user.email, user.phone, user.user_type
        )
        return User(**dict(result))  # ✅ Convert to dict → Pydantic model

# ✅ Get all users
@router.get("/", response_model=List[User])
async def get_users(pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        users = await conn.fetch("SELECT * FROM users")
        return [User(**dict(user)) for user in users]  # ✅ Convert each record

# ✅ Get single user
@router.get("/{user_id}", response_model=User)
async def get_user(user_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        user = await conn.fetchrow("SELECT * FROM users WHERE user_id = $1", user_id)
        if user:
            return User(**dict(user))  # ✅ Convert to dict
        raise HTTPException(status_code=404, detail="User not found")

# ✅ Update user
@router.put("/{user_id}", response_model=User)
async def update_user(user_id: int, user: UserCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        updated = await conn.fetchrow(
            "UPDATE users SET name = $1, email = $2, phone = $3, user_type = $4 WHERE user_id = $5 RETURNING *",
            user.name, user.email, user.phone, user.user_type, user_id
        )
        if updated:
            return User(**dict(updated))  # ✅ Convert to dict
        raise HTTPException(status_code=404, detail="User not found")

# ✅ Delete user
@router.delete("/{user_id}")
async def delete_user(user_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        result = await conn.execute("DELETE FROM users WHERE user_id = $1", user_id)
        if result == "DELETE 1":
            return {"message": "🗑️ User deleted successfully"}
        raise HTTPException(status_code=404, detail="User not found")
