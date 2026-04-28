from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

from app.core.database import get_db
from app.core.logger import get_logger

from app.models.manager import Manager
from app.models.user import User

from app.schemas.manager import ManagerCreate, ManagerResponse

logger = get_logger(__name__)

router = APIRouter(prefix="/managers", tags=["Managers"])

@router.post("/", response_model=ManagerResponse)
def create_manager(payload: ManagerCreate, db: Session = Depends(get_db)):

    logger.info(f"[START] Create manager | user_id={payload.user_id}")

    try:
        user = db.query(User).filter(User.id == payload.user_id).first()

        if not user:
            logger.warning("User not found")
            raise HTTPException(404, "User not found")

        existing = db.query(Manager).filter(
            Manager.user_id == payload.user_id
        ).first()

        if existing:
            logger.warning("Already manager")
            raise HTTPException(400, "User is already a manager")

        manager = Manager(**payload.model_dump())

        db.add(manager)
        db.commit()
        db.refresh(manager)

        logger.info(f"[SUCCESS] Manager created: {manager.user_id}")

        return manager

    except HTTPException as e:
        db.rollback()
        logger.warning(e.detail)
        raise

    except Exception:
        db.rollback()
        logger.error("Manager creation failed", exc_info=True)
        raise HTTPException(500, "Internal server error")
    
@router.get("/", response_model=List[ManagerResponse])
def get_managers(db: Session = Depends(get_db)):

    logger.info("[START] Fetch managers")

    managers = db.query(Manager).all()

    logger.info(f"[SUCCESS] {len(managers)} managers")

    return managers


@router.get("/{user_id}", response_model=ManagerResponse)
def get_manager(user_id: UUID, db: Session = Depends(get_db)):

    logger.info(f"[START] Fetch manager: {user_id}")

    manager = db.query(Manager).filter(
        Manager.user_id == user_id
    ).first()

    if not manager:
        logger.warning("Manager not found")
        raise HTTPException(404, "Manager not found")

    logger.info("[SUCCESS] Manager found")

    return manager