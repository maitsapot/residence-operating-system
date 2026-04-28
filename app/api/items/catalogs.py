from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.core.database import get_db
from app.core.logger import get_logger

from app.models.catalog import Catalog
from app.models.category import Category
from app.schemas.catalog import CatalogCreate, CatalogResponse

logger = get_logger(__name__)

router = APIRouter(prefix="/catalogs", tags=["Catalogs"])


@router.post("/", response_model=CatalogResponse)
def create_catalog(payload: CatalogCreate, db: Session = Depends(get_db)):
    logger.info(f"Creating catalog item: {payload.name}")

    category = db.query(Category).filter(
        Category.id == payload.category_id
    ).first()

    if not category:
        logger.warning(f"Invalid category_id: {payload.category_id}")
        raise HTTPException(400, "Category does not exist")

    existing = db.query(Catalog).filter(
        Catalog.name == payload.name
    ).first()

    if existing:
        logger.warning(f"Catalog already exists: {payload.name}")
        raise HTTPException(400, "Catalog already exists")

    catalog = Catalog(**payload.dict())

    try:
        db.add(catalog)
        db.commit()
        db.refresh(catalog)

        logger.info(f"Catalog created: {catalog.id}")
        return catalog

    except IntegrityError as e:
        db.rollback()
        logger.error(f"Integrity error: {e}")

        raise HTTPException(400, "Constraint violation")


@router.get("/", response_model=list[CatalogResponse])
def get_catalogs(db: Session = Depends(get_db)):
    logger.info("Fetching catalogs")

    data = db.query(Catalog).order_by(Catalog.name).all()

    logger.info(f"Returned {len(data)} catalogs")
    return data