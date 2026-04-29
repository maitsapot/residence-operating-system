from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.sql import func
from typing import List
from datetime import date
from uuid import UUID

from app.core.database import get_db
from app.models.space import Space
from app.models.tenant import Tenant as TenantProfile
from app.models.tenancy import Tenancy
from app.models.user import User
from app.core.enums import TenancyStatus
from app.schemas.tenancy import (
    TenancyCreate,
    TenancyLifecycleUpdate,
    TenancyResponse,
)
from app.core.logger import get_logger

logger = get_logger(__name__)

router = APIRouter(prefix="/tenancies", tags=["Tenancies"])


def _validate_date_range(start_date: date, end_date: date | None):
    if end_date and end_date < start_date:
        raise HTTPException(400, "end_date cannot be before start_date")


def _ranges_overlap(
    first_start: date,
    first_end: date | None,
    second_start: date,
    second_end: date | None,
) -> bool:
    first_end_value = first_end or date.max
    second_end_value = second_end or date.max
    return first_start <= second_end_value and second_start <= first_end_value


def _find_overlapping_active_tenancy(
    db: Session,
    *,
    user_id: UUID,
    space_id: UUID,
    start_date: date,
    end_date: date | None,
):
    active_tenancies = db.query(Tenancy).filter(
        Tenancy.status == "active",
        (
            (Tenancy.space_id == space_id)
            | (Tenancy.user_id == user_id)
        )
    ).all()

    for tenancy in active_tenancies:
        if _ranges_overlap(
            tenancy.start_date,
            tenancy.end_date,
            start_date,
            end_date,
        ):
            return tenancy

    return None


def _close_tenancy(
    tenancy: Tenancy,
    status: TenancyStatus,
    end_date: date | None,
):
    if tenancy.status != "active":
        raise HTTPException(400, "Only active tenancies can be closed")

    close_date = end_date or date.today()
    if close_date < tenancy.start_date:
        raise HTTPException(400, "end_date cannot be before start_date")

    tenancy.status = status
    tenancy.end_date = close_date
    tenancy.updated_at = func.now()


# ===============================
# CREATE TENANCY
# ===============================
@router.post("/", response_model=TenancyResponse)
def create_tenancy(payload: TenancyCreate, db: Session = Depends(get_db)):
    try:
        _validate_date_range(payload.start_date, payload.end_date)

        user = db.query(User).filter(User.id == payload.user_id).first()
        if not user:
            raise HTTPException(404, "User not found")

        tenant = db.query(TenantProfile).filter(
            TenantProfile.user_id == payload.user_id
        ).first()
        if not tenant:
            raise HTTPException(400, "User is not registered as a tenant")

        space = db.query(Space).filter(Space.id == payload.space_id).first()
        if not space:
            raise HTTPException(404, "Space not found")

        if not space.is_rentable:
            raise HTTPException(400, "Space is not rentable")

        overlap = _find_overlapping_active_tenancy(
            db,
            user_id=payload.user_id,
            space_id=payload.space_id,
            start_date=payload.start_date,
            end_date=payload.end_date,
        )
        if overlap:
            if overlap.space_id == payload.space_id:
                raise HTTPException(
                    400,
                    "Space already has an overlapping active tenancy"
                )

            raise HTTPException(
                400,
                "Tenant already has an overlapping active tenancy"
            )

        tenancy = Tenancy(**payload.model_dump())

        db.add(tenancy)
        db.commit()
        db.refresh(tenancy)

        logger.info(f"Tenancy created: {tenancy.id}")

        return tenancy

    except HTTPException:
        db.rollback()
        raise

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


# ===============================
# TERMINATE TENANCY
# ===============================
@router.post("/{tenancy_id}/terminate", response_model=TenancyResponse)
def terminate_tenancy(
    tenancy_id: UUID,
    payload: TenancyLifecycleUpdate | None = None,
    db: Session = Depends(get_db)
):
    tenancy = db.query(Tenancy).filter(Tenancy.id == tenancy_id).first()

    if not tenancy:
        raise HTTPException(status_code=404, detail="Tenancy not found")

    try:
        _close_tenancy(
            tenancy=tenancy,
            status="terminated",
            end_date=payload.end_date if payload else None,
        )

        db.commit()
        db.refresh(tenancy)

        return tenancy

    except HTTPException:
        db.rollback()
        raise

    except Exception:
        db.rollback()
        logger.error("Error terminating tenancy", exc_info=True)
        raise HTTPException(500, "Failed to terminate tenancy")


# ===============================
# COMPLETE TENANCY
# ===============================
@router.post("/{tenancy_id}/complete", response_model=TenancyResponse)
def complete_tenancy(
    tenancy_id: UUID,
    payload: TenancyLifecycleUpdate | None = None,
    db: Session = Depends(get_db)
):
    tenancy = db.query(Tenancy).filter(Tenancy.id == tenancy_id).first()

    if not tenancy:
        raise HTTPException(status_code=404, detail="Tenancy not found")

    try:
        _close_tenancy(
            tenancy=tenancy,
            status="completed",
            end_date=payload.end_date if payload else None,
        )

        db.commit()
        db.refresh(tenancy)

        return tenancy

    except HTTPException:
        db.rollback()
        raise

    except Exception:
        db.rollback()
        logger.error("Error completing tenancy", exc_info=True)
        raise HTTPException(500, "Failed to complete tenancy")
