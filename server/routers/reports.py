from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import asyncpg
from db import get_db_pool

router = APIRouter()

class Report(BaseModel):
    report_id: int
    created_at: datetime
    target_id: str
    reporter_id: Optional[int]
    target_type: Optional[str]
    reason: Optional[str]
    status: Optional[str]

class ReportCreate(BaseModel):
    target_id: str
    reporter_id: Optional[int]
    target_type: Optional[str]
    reason: Optional[str]
    status: Optional[str]

@router.post("/", response_model=Report)
async def create_report(report: ReportCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        try:
            result = await conn.fetchrow(
                "INSERT INTO reports (target_id, reporter_id, target_type, reason, status) VALUES ($1, $2, $3, $4, $5) RETURNING *",
                report.target_id, report.reporter_id, report.target_type, report.reason, report.status
            )
            return dict(result)
        except asyncpg.exceptions.ForeignKeyViolationError:
            raise HTTPException(status_code=400, detail="Foreign key constraint failed (reporter_id may not exist)")
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

@router.get("/", response_model=List[Report])
async def get_reports(pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        results = await conn.fetch("SELECT * FROM reports")
        return [dict(row) for row in results]

@router.get("/{report_id}", response_model=Report)
async def get_report(report_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        report = await conn.fetchrow("SELECT * FROM reports WHERE report_id = $1", report_id)
        if report:
            return dict(report)
        raise HTTPException(status_code=404, detail="Report not found")

@router.put("/{report_id}", response_model=Report)
async def update_report(report_id: int, report: ReportCreate, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        updated = await conn.fetchrow(
            "UPDATE reports SET target_id = $1, reporter_id = $2, target_type = $3, reason = $4, status = $5 WHERE report_id = $6 RETURNING *",
            report.target_id, report.reporter_id, report.target_type, report.reason, report.status, report_id
        )
        if updated:
            return dict(updated)
        raise HTTPException(status_code=404, detail="Report not found")

@router.delete("/{report_id}")
async def delete_report(report_id: int, pool: asyncpg.Pool = Depends(get_db_pool)):
    async with pool.acquire() as conn:
        result = await conn.execute("DELETE FROM reports WHERE report_id = $1", report_id)
        if result == "DELETE 1":
            return {"message": "🗑️ Report deleted successfully"}
        raise HTTPException(status_code=404, detail="Report not found")
