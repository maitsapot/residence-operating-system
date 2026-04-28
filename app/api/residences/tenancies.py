from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

from app.core.database import get_db
from app.models.tenancy import Tenancy
from app.schemas.tenancy import TenancyCreate, TenancyResponse
from app.core.logger import get_logger

logger = get_logger(__name__)

router = APIRouter(prefix="/tenancies", tags=["Tenancies"])


# ===============================
# CREATE TENANCY
# ===============================
@router.post("/", response_model=TenancyResponse)
def create_tenancy(payload: TenancyCreate, db: Session = Depends(get_db)):
    try:
        tenancy = Tenancy(**payload.model_dump())

        db.add(tenancy)
        db.commit()
        db.refresh(tenancy)

        logger.info(f"Tenancy created: {tenancy.id}")

        return tenancy

    except Exception:
        db.rollback()
        logger.error("Error creating tenancy", exc_info=True)
        raise HTTPException(status_code=500, detail="Failed to create tenancy")


# ===============================
# GET ALL TENANCIES
# ===============================
@router.get("/", response_model=List[TenancyResponse])
def get_tenancies(db: Session = Depends(get_db)):
    return db.query(Tenancy).all()


# ===============================
# GET TENANCY BY ID
# ===============================
@router.get("/{tenancy_id}", response_model=TenancyResponse)
def get_tenancy(tenancy_id: UUID, db: Session = Depends(get_db)):
    tenancy = db.query(Tenancy).filter(Tenancy.id == tenancy_id).first()

    if not tenancy:
        raise HTTPException(status_code=404, detail="Tenancy not found")

    return tenancy