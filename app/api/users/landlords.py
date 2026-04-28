from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

from app.core.database import get_db
from app.core.logger import get_logger

from app.models.landlord import Landlord
from app.models.user import User

from app.schemas.landlord import LandlordCreate, LandlordResponse

logger = get_logger(__name__)

router = APIRouter(prefix="/landlords", tags=["Landlords"])

@router.post("/", response_model=LandlordResponse)
def create_landlord(payload: LandlordCreate, db: Session = Depends(get_db)):

    logger.info(f"[START] Create landlord | user_id={payload.user_id}")

    try:
        # ===============================
        # VALIDATION
        # ===============================
        logger.info("[VALIDATION] Checking user exists")

        user = db.query(User).filter(User.id == payload.user_id).first()
        if not user:
            logger.warning(f"[BUSINESS ERROR] User not found: {payload.user_id}")
            raise HTTPException(404, "User not found")

        logger.info("[VALIDATION] Checking duplicate landlord")

        existing = db.query(Landlord).filter(
            Landlord.user_id == payload.user_id
        ).first()

        if existing:
            logger.warning(f"[BUSINESS ERROR] Already landlord: {payload.user_id}")
            raise HTTPException(400, "User is already a landlord")

        # ===============================
        # CREATE
        # ===============================
        logger.info("[DB] Creating landlord record")

        landlord = Landlord(**payload.model_dump())
        db.add(landlord)

        logger.info("[DB] Committing transaction")
        db.commit()
        db.refresh(landlord)

        logger.info(f"[SUCCESS] Landlord created | user_id={landlord.user_id}")

        return landlord

    except HTTPException as e:
        db.rollback()
        logger.warning(f"[BUSINESS ERROR] {e.detail}")
        raise

    except Exception:
        db.rollback()
        logger.error("[SYSTEM ERROR] Failed to create landlord", exc_info=True)
        raise HTTPException(500, "Internal server error")
    
    
@router.get("/", response_model=List[LandlordResponse])
def get_landlords(db: Session = Depends(get_db)):

    logger.info("[START] Fetch all landlords")

    landlords = db.query(Landlord).all()

    logger.info(f"[SUCCESS] Retrieved {len(landlords)} landlords")

    return landlords


@router.get("/{user_id}", response_model=LandlordResponse)
def get_landlord(user_id: UUID, db: Session = Depends(get_db)):

    logger.info(f"[START] Fetch landlord | user_id={user_id}")

    landlord = db.query(Landlord).filter(
        Landlord.user_id == user_id
    ).first()

    if not landlord:
        logger.warning(f"[BUSINESS ERROR] Landlord not found: {user_id}")
        raise HTTPException(404, "Landlord not found")

    logger.info(f"[SUCCESS] Landlord found | user_id={user_id}")

    return landlord