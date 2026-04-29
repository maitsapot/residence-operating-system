from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text

from app.core.database import get_db

router = APIRouter(prefix="/debug", tags=["Debug"])


@router.get("/db")
def test_db(db: Session = Depends(get_db)):
    result = db.execute(text("SELECT 1")).fetchone()
    return {"status": "ok", "result": result[0]}


@router.get("/tables")
def list_tables(db: Session = Depends(get_db)):
    result = db.execute(text("""
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
    """)).fetchall()

    return {"tables": [r[0] for r in result]}