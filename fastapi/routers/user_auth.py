from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional
from passlib.context import CryptContext
from jose import JWTError, jwt
from datetime import datetime, timedelta
import asyncpg
from db import get_db_pool

router = APIRouter()

# 🔐 Security settings
SECRET_KEY = "your-strong-secret-key"  # Replace securely
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

class UserCreate(BaseModel):
    name: Optional[str]
    email: str
    phone: Optional[str]
    user_type: Optional[str]
    password: str

class UserLogin(BaseModel):
    email: str
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

@router.post("/register")
async def register_user(user: UserCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        existing = await conn.fetchrow("SELECT * FROM users WHERE email = $1", user.email)
        if existing:
            raise HTTPException(status_code=400, detail="Email already registered")

        # Insert into users
        user_row = await conn.fetchrow(
            "INSERT INTO users (name, email, phone, user_type) VALUES ($1, $2, $3, $4) RETURNING user_id",
            user.name, user.email, user.phone, user.user_type
        )

        # Insert into user_auth
        hashed_password = get_password_hash(user.password)
        await conn.execute(
            "INSERT INTO user_auth (user_id, password_hash) VALUES ($1, $2)",
            user_row["user_id"], hashed_password
        )

        return {"message": "✅ User registered successfully"}

@router.post("/login", response_model=Token)
async def login_user(user: UserLogin, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        # Get user_id from users
        user_row = await conn.fetchrow("SELECT user_id FROM users WHERE email = $1", user.email)
        if not user_row:
            raise HTTPException(status_code=401, detail="Invalid credentials")

        # Get password_hash from user_auth
        auth_row = await conn.fetchrow("SELECT password_hash FROM user_auth WHERE user_id = $1", user_row["user_id"])
        if not auth_row or not verify_password(user.password, auth_row["password_hash"]):
            raise HTTPException(status_code=401, detail="Invalid credentials")

        # Update last_login
        await conn.execute("UPDATE user_auth SET last_login = now() WHERE user_id = $1", user_row["user_id"])

        access_token = create_access_token(data={"sub": str(user_row["user_id"])})
        return {"access_token": access_token, "token_type": "bearer"}
