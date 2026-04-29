from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.core.database import get_db
from app.core.logger import get_logger

from app.models.item import Item
from app.models.category import Category

from app.schemas.item import ItemCreate, ItemResponse

logger = get_logger(__name__)

router = APIRouter(prefix="/items", tags=["Items"])


@router.post("/", response_model=ItemResponse)
def create_item(payload: ItemCreate, db: Session = Depends(get_db)):
    logger.info(f"Creating item: {payload.name}")

    category = db.query(Category).filter(
        Category.id == payload.category_id
    ).first()

    if not category:
        logger.warning(f"Invalid category_id: {payload.category_id}")
        raise HTTPException(400, "Category does not exist")

    existing = db.query(Item).filter(
        Item.name == payload.name
    ).first()

    if existing:
        logger.warning(f"Item already exists: {payload.name}")
        raise HTTPException(400, "Item already exists")

    try:
        item = Item(**payload.dict())
        db.add(item)
        db.commit()
        db.refresh(item)

        logger.info(f"Item created: {item.id}")
        return item

    except IntegrityError as e:
        db.rollback()
        logger.error(f"Integrity error: {e}")

        raise HTTPException(400, "Constraint violation")


@router.get("/", response_model=list[ItemResponse])
def get_items(db: Session = Depends(get_db)):
    logger.info("Fetching all items")

    items = db.query(Item).order_by(Item.name).all()

    logger.info(f"Returned {len(items)} items")
    return items
