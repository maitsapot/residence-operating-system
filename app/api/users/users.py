from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session, joinedload
from typing import List
from uuid import UUID

from app.core.database import get_db
from app.models.user import User
from app.models.location import Location
from app.schemas.user import UserCreate, UserResponse,UserFullNameResponse

from app.core.logger import get_logger


# ===============================
# EARLY LOGGING
# ===============================

logger = get_logger(__name__)

# ===============================
# ROUTER CONFIGURATION
# ===============================
router = APIRouter(prefix="/users", tags=["Users"])


# ===============================
# CREATE USER (WITH NESTED LOCATION)
# ===============================
@router.post("/", response_model=UserResponse)
def create_user(payload: UserCreate, db: Session = Depends(get_db)):
    """
    Creates a new user along with a nested location.

    Flow:
    1. Validate duplicates (cellphone, email)
    2. Create location
    3. Create user linked to location
    4. Commit as one transaction
    """

    try:
        # -------------------------------
        # DUPLICATE CHECKS
        # -------------------------------
        existing_user = db.query(User).filter(User.cellphone == payload.cellphone).first()
        if existing_user:
            logger.warning(f"Duplicate cellphone attempt: {payload.cellphone}")
            raise HTTPException(status_code=400, detail="Cellphone already exists")

        if payload.email:
            existing_email = db.query(User).filter(User.email == payload.email).first()
            if existing_email:
                raise HTTPException(status_code=400, detail="Email already exists")

        # -------------------------------
        # CREATE LOCATION FIRST
        # -------------------------------
        location = Location(**payload.location.model_dump())

        db.add(location)
        db.flush()  # 🔥 ensures location.id is generated before user insert
        
        logger.info("Location created with ID: {location.id}")

        # -------------------------------
        # CREATE USER
        # -------------------------------
        user_data = payload.model_dump(exclude={"location"})

        user = User(
            **user_data,
            location_id=location.id
        )

        db.add(user)

        # -------------------------------
        # COMMIT TRANSACTION
        # -------------------------------
        db.commit()
        db.refresh(user)
        
        logger.info(f"User created successfully: {user.id}")
        return user

    except HTTPException as e:
        db.rollback()
        logger.warning(f"Business error: {e.detail}")
        raise

    except Exception as e:
        db.rollback()
        logger.error("Unexpected error while creating user", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))
    
# ===============================
# GET USERS FULLNAME LIST
# ===============================
@router.get("/fullname", response_model=List[UserFullNameResponse])
def get_users_fullname(db: Session = Depends(get_db)):
    """
    Returns users with computed full_name.

    Only selects required fields for efficiency.
    """

    try:
        users = (
            db.query(
                User.id,
                User.first_name,
                User.middle_name,
                User.last_name
            )
            .order_by(User.first_name, User.last_name)
            .all()
        )

        result = [
            {
                "id": user.id,
                "full_name": " ".join(
                    [p for p in [user.first_name, user.middle_name, user.last_name] if p]
                )
            }
            for user in users
        ]

        logger.info(f"Fetched {len(result)} users for fullname list")

        return result

    except Exception:
        logger.error("Error fetching users fullname list", exc_info=True)
        raise HTTPException(status_code=500, detail="Failed to fetch users")


# ===============================
# GET ALL USERS
# ===============================
@router.get("/", response_model=List[UserResponse])
def get_users(db: Session = Depends(get_db)):
    """
    Returns all users with their associated location.

    Uses joinedload to avoid N+1 query problem.
    """
    users = db.query(User).options(joinedload(User.location)).all()
    return users


# ===============================
# GET SINGLE USER BY ID
# ===============================
@router.get("/{user_id}", response_model=UserResponse)
def get_user(user_id: UUID, db: Session = Depends(get_db)):
    """
    Returns a single user by ID with location details.
    """
    user = (
        db.query(User)
        .options(joinedload(User.location))
        .filter(User.id == user_id)
        .first()
    )

    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        logger.error("Unexpected error while creating user", exc_info=True)

    return user

