from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from sqlalchemy.sql import func

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
def get_items(
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    category_id: UUID | None = None,
    search: str | None = None,
    is_active: bool | None = None,
    include_archived: bool = False,
    db: Session = Depends(get_db),
):
    logger.info("Fetching all items")

    query = db.query(Item)
    if not include_archived:
        query = query.filter(Item.archived_at.is_(None))
    if category_id:
        query = query.filter(Item.category_id == category_id)
    if search:
        query = query.filter(Item.name.ilike(f"%{search}%"))
    if is_active is not None:
        query = query.filter(Item.is_active == is_active)

    items = query.order_by(Item.name).offset(offset).limit(limit).all()

    logger.info(f"Returned {len(items)} items")
    return items


@router.delete("/{item_id}", response_model=ItemResponse)
def archive_item(item_id: UUID, db: Session = Depends(get_db)):
    item = db.query(Item).filter(Item.id == item_id).first()
    if not item:
        raise HTTPException(404, "Item not found")

    item.is_active = False
    item.archived_at = func.now()
    db.commit()
    db.refresh(item)
    return item


@router.post("/{item_id}/restore", response_model=ItemResponse)
def restore_item(item_id: UUID, db: Session = Depends(get_db)):
    item = db.query(Item).filter(Item.id == item_id).first()
    if not item:
        raise HTTPException(404, "Item not found")

    item.is_active = True
    item.archived_at = None
    db.commit()
    db.refresh(item)
    return item
