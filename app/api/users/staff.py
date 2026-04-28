from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

from app.core.database import get_db
from app.core.logger import get_logger

from app.models.staff import Staff
from app.models.user import User

from app.schemas.staff import StaffCreate, StaffResponse

logger = get_logger(__name__)

router = APIRouter(prefix="/staff", tags=["Staff"])




@router.post("/", response_model=StaffResponse)
def create_staff(payload: StaffCreate, db: Session = Depends(get_db)):

    logger.info(f"[START] Create staff | user_id={payload.user_id}, role={payload.role}")

    try:
        # ===============================
        # VALIDATION
        # ===============================
        user = db.query(User).filter(User.id == payload.user_id).first()

        if not user:
            logger.warning("[BUSINESS ERROR] User not found")
            raise HTTPException(404, "User not found")

        # optional: prevent duplicate same role
        existing = db.query(Staff).filter(
            Staff.user_id == payload.user_id,
            Staff.role == payload.role
        ).first()

        if existing:
            logger.warning("[BUSINESS ERROR] Staff role already exists")
            raise HTTPException(400, "User already has this staff role")

        # ===============================
        # CREATE
        # ===============================
        logger.info("[DB] Creating staff record")

        staff = Staff(**payload.model_dump())

        db.add(staff)
        db.commit()
        db.refresh(staff)

        logger.info(f"[SUCCESS] Staff created | id={staff.id}")

        return staff

    except HTTPException as e:
        db.rollback()
        logger.warning(e.detail)
        raise

    except Exception:
        db.rollback()
        logger.error("[SYSTEM ERROR] Failed to create staff", exc_info=True)
        raise HTTPException(500, "Internal server error")
    
    
@router.get("/", response_model=List[StaffResponse])
def get_staff(db: Session = Depends(get_db)):

    logger.info("[START] Fetch staff")

    staff = db.query(Staff).all()

    logger.info(f"[SUCCESS] {len(staff)} staff records")

    return staff

@router.get("/{staff_id}", response_model=StaffResponse)
def get_staff_member(staff_id: UUID, db: Session = Depends(get_db)):

    logger.info(f"[START] Fetch staff | id={staff_id}")

    staff = db.query(Staff).filter(Staff.id == staff_id).first()

    if not staff:
        logger.warning("[BUSINESS ERROR] Staff not found")
        raise HTTPException(404, "Staff not found")

    logger.info("[SUCCESS] Staff found")

    return staff