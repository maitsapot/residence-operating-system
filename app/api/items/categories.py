from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.core.database import get_db
from app.core.logger import get_logger

from app.models.category import Category
from app.schemas.category import CategoryCreate, CategoryResponse

# Initialize logger for this module
logger = get_logger(__name__)

router = APIRouter(prefix="/categories", tags=["Categories"])


@router.post("/", response_model=CategoryResponse)
def create_category(payload: CategoryCreate, db: Session = Depends(get_db)):
    """
    Create a new category.

    - Enforces uniqueness
    - Validates against allowed values (DB constraint)
    """

    logger.info(f"Creating category: {payload.category_name}")

    # Check if category already exists
    existing = db.query(Category).filter(
        Category.category_name == payload.category_name
    ).first()

    if existing:
        logger.warning(f"Category already exists: {payload.category_name}")
        raise HTTPException(
            status_code=400,
            detail="Category already exists"
        )

    # Create new category instance
    category = Category(
        category_name=payload.category_name,
        is_trackable=payload.is_trackable,
        is_active=payload.is_active
    )

    try:
        db.add(category)
        db.commit()
        db.refresh(category)

        logger.info(f"Category created successfully: {category.id}")

        return category

    except IntegrityError as e:
        db.rollback()

        logger.error(f"Integrity error creating category: {e}")

        raise HTTPException(
            status_code=400,
            detail="Invalid category value"
        )


@router.get("/", response_model=list[CategoryResponse])
def get_categories(db: Session = Depends(get_db)):
    """
    Retrieve all categories (sorted alphabetically)
    """

    logger.info("Fetching all categories")

    categories = db.query(Category).order_by(Category.category_name).all()

    logger.info(f"Returned {len(categories)} categories")

    return categories


@router.get("/{category_id}", response_model=CategoryResponse)
def get_category(category_id: str, db: Session = Depends(get_db)):
    """
    Retrieve a single category by ID
    """

    logger.info(f"Fetching category: {category_id}")

    category = db.query(Category).filter(
        Category.id == category_id
    ).first()

    if not category:
        logger.warning(f"Category not found: {category_id}")
        raise HTTPException(
            status_code=404,
            detail="Category not found"
        )

    return category