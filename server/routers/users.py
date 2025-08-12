from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from datetime import datetime
import asyncpg
from db import get_db_pool
from uuid import UUID
import json

router = APIRouter()

# 🔧 Response model


class User(BaseModel):
    user_id: int
    created_at: datetime
    name: Optional[str]
    email: Optional[str]
    phone: Optional[str]
    user_type: Optional[str]
    profile_image: Optional[str] = None
    dob: Optional[datetime] = None


class AuthUser(BaseModel):
    user_id: Optional[int] = None
    name: Optional[str] = None
    user_type: Optional[str] = None

    instance_id: Optional[UUID]
    id: UUID
    aud: Optional[str]
    role: Optional[str]
    email: Optional[str]
    encrypted_password: Optional[str]
    email_confirmed_at: Optional[datetime]
    invited_at: Optional[datetime]
    confirmation_token: Optional[str]
    confirmation_sent_at: Optional[datetime]
    recovery_token: Optional[str]
    recovery_sent_at: Optional[datetime]
    email_change_token_new: Optional[str]
    email_change: Optional[str]
    email_change_sent_at: Optional[datetime]
    last_sign_in_at: Optional[datetime]
    raw_app_meta_data: Optional[Dict[str, Any]]
    raw_user_meta_data: Optional[Dict[str, Any]]
    is_super_admin: Optional[bool]
    created_at: datetime
    updated_at: datetime
    phone: Optional[str]
    phone_confirmed_at: Optional[datetime]
    phone_change: Optional[str]
    phone_change_token: Optional[str]
    phone_change_sent_at: Optional[datetime]
    confirmed_at: Optional[datetime]
    email_change_token_current: Optional[str]
    email_change_confirm_status: Optional[int]
    banned_until: Optional[datetime]
    reauthentication_token: Optional[str]
    reauthentication_sent_at: Optional[datetime]
    is_sso_user: Optional[bool]
    deleted_at: Optional[datetime]
    is_anonymous: Optional[bool]


class UserCreate(BaseModel):
    name: Optional[str]
    email: Optional[str]
    phone: Optional[str]
    user_type: Optional[str]
    profile_image: Optional[str] = None
    dob: Optional[datetime] = None


@router.post("/", response_model=User)
async def create_user(user: UserCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        result = await conn.fetchrow(
            "INSERT INTO users (name, email, phone, user_type) VALUES ($1, $2, $3, $4) RETURNING *",
            user.name, user.email, user.phone, user.user_type
        )
        return User(**dict(result))


@router.get("/", response_model=List[User])
async def get_users(pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        users = await conn.fetch("SELECT * FROM users")
        return [User(**dict(user)) for user in users]


@router.get("/{user_id}", response_model=User)
async def get_user(user_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        user = await conn.fetchrow("SELECT * FROM users WHERE user_id = $1", user_id)
        if user:
            return User(**dict(user))  # ✅ Convert to dict
        raise HTTPException(status_code=404, detail="User not found")


@router.get("/auth/{auth_id}", response_model=List[AuthUser])
async def get_user_by_auth_id(auth_id: str, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        user = await conn.fetchrow("SELECT * FROM auth.users as a,users as b WHERE a.id = $1::uuid and a.id = b.auth_id", auth_id)
        if user:
            data = dict(user)
            for key in ("raw_app_meta_data", "raw_user_meta_data"):
                val = data.get(key)
                if isinstance(val, str):
                    try:
                        data[key] = json.loads(val)
                    except json.JSONDecodeError:
                        data[key] = None
            return [AuthUser(**data)]
        raise HTTPException(status_code=404, detail="User not found")


@router.put("/{auth_id}", response_model=User)
async def update_user(auth_id: str, user: UserCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        updated = await conn.fetchrow(
            """
            UPDATE users
            SET name = $1,
                email = $2,
                phone = $3,
                user_type = $4,
                profile_image = $5,
                dob = $6
            WHERE auth_id = $7::uuid
            RETURNING *
            """,
            user.name, user.email, user.phone, user.user_type, user.profile_image, user.dob, auth_id
        )
        if updated:
            return User(**dict(updated))
        raise HTTPException(status_code=404, detail="User not found")


@router.delete("/{user_id}")
async def delete_user(user_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        result = await conn.execute("DELETE FROM users WHERE user_id = $1", user_id)
        if result == "DELETE 1":
            return {"message": "🗑️ User deleted successfully"}
        raise HTTPException(status_code=404, detail="User not found")
