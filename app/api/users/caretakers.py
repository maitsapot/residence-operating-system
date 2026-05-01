from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

from app.core.database import get_db
from app.core.logger import get_logger

from app.models.caretaker import Caretaker
from app.models.user import User

from app.schemas.caretaker import CaretakerCreate, CaretakerResponse

logger = get_logger(__name__)

router = APIRouter(prefix="/caretakers", tags=["Caretakers"])


@router.post("/", response_model=CaretakerResponse)
def create_caretaker(payload: CaretakerCreate, db: Session = Depends(get_db)):

    logger.info(f"[START] Create caretaker | user_id={payload.user_id}")

    try:
        # ===============================
        # VALIDATION
        # ===============================
        logger.info("[VALIDATION] Checking user exists")

        user = db.query(User).filter(User.id == payload.user_id).first()
        if not user:
            logger.warning(f"[BUSINESS ERROR] User not found: {payload.user_id}")
            raise HTTPException(404, "User not found")

        logger.info("[VALIDATION] Checking duplicate caretaker")

        existing = db.query(Caretaker).filter(
            Caretaker.user_id == payload.user_id
        ).first()

        if existing:
            logger.warning(f"[BUSINESS ERROR] Already caretaker: {payload.user_id}")
            raise HTTPException(400, "User is already a caretaker")

        # ===============================
        # CREATE
        # ===============================
        logger.info("[DB] Creating caretaker record")

        caretaker = Caretaker(**payload.model_dump())
        db.add(caretaker)

        logger.info("[DB] Committing transaction")
        db.commit()
        db.refresh(caretaker)

        logger.info(f"[SUCCESS] Caretaker created | user_id={caretaker.user_id}")

        return caretaker

    except HTTPException as e:
        db.rollback()
        logger.warning(f"[BUSINESS ERROR] {e.detail}")
        raise

    except Exception:
        db.rollback()
        logger.error("[SYSTEM ERROR] Failed to create caretaker", exc_info=True)
        raise HTTPException(500, "Internal server error")
    
@router.get("/", response_model=List[CaretakerResponse])
def get_caretakers(db: Session = Depends(get_db)):

    logger.info("[START] Fetch all caretakers")

    caretakers = db.query(Caretaker).all()

    logger.info(f"[SUCCESS] Retrieved {len(caretakers)} caretakers")

    return caretakers


@router.get("/{user_id}", response_model=CaretakerResponse)
def get_caretaker(user_id: UUID, db: Session = Depends(get_db)):

    logger.info(f"[START] Fetch caretaker | user_id={user_id}")

    caretaker = db.query(Caretaker).filter(
        Caretaker.user_id == user_id
    ).first()

    if not caretaker:
        logger.warning(f"[BUSINESS ERROR] Caretaker not found: {user_id}")
        raise HTTPException(404, "Caretaker not found")

    logger.info(f"[SUCCESS] Caretaker found | user_id={user_id}")

    return caretaker