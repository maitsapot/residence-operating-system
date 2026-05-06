from typing import List
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.core.database import get_db
from app.core.logger import get_logger

from app.models.space_item import SpaceItem
from app.models.item import Item
from app.models.space import Space

from app.schemas.space_item import (
    SpaceItemCreate,
    SpaceItemInventoryResponse,
    SpaceItemResponse,
)

logger = get_logger(__name__)

router = APIRouter(prefix="/space-items", tags=["Space Items"])


@router.get("/by-space/{space_id}", response_model=List[SpaceItemInventoryResponse])
def get_space_items_by_space(space_id: UUID, db: Session = Depends(get_db)):
    """
    Return inventory items for a space with item display names.
    """

    logger.info(f"Fetching space inventory: {space_id}")

    space = db.query(Space).filter(Space.id == space_id).first()
    if not space:
        raise HTTPException(404, "Space not found")

    rows = (
        db.query(SpaceItem, Item.name.label("item_name"))
        .join(Item, Item.id == SpaceItem.item_id)
        .filter(SpaceItem.space_id == space_id)
        .order_by(Item.name)
        .all()
    )

    return [
        SpaceItemInventoryResponse(
            id=space_item.id,
            space_id=space_item.space_id,
            item_id=space_item.item_id,
            item_name=item_name,
            quantity=space_item.quantity,
            is_required=space_item.is_required,
            condition=space_item.condition,
            status=space_item.status,
        )
        for space_item, item_name in rows
    ]


@router.post("/", response_model=SpaceItemResponse)
def create_space_item(
    payload: SpaceItemCreate,
    db: Session = Depends(get_db)
):
    """
    Create expected item for a space.

    Enforces:
    - one item per space
    """

    logger.info(f"Creating space item for space: {payload.space_id}")

    try:
        # 🔷 Validate space
        space = db.query(Space).filter(
            Space.id == payload.space_id
        ).first()

        if not space:
            logger.warning(f"Space not found: {payload.space_id}")
            raise HTTPException(400, "Space not found")

        # 🔷 Validate item
        item_definition = db.query(Item).filter(
            Item.id == payload.item_id
        ).first()

        if not item_definition:
            logger.warning(f"Item not found: {payload.item_id}")
            raise HTTPException(400, "Item not found")

        # 🔷 Prevent duplicates (also backed by DB unique constraint)
        existing = db.query(SpaceItem).filter(
            SpaceItem.space_id == payload.space_id,
            SpaceItem.item_id == payload.item_id
        ).first()

        if existing:
            logger.warning(
                f"Duplicate space_item for space {payload.space_id} and item {payload.item_id}"
            )
            raise HTTPException(400, "Space item already exists")

        # 🔷 Create record
        item = SpaceItem(**payload.dict())

        db.add(item)
        db.commit()
        db.refresh(item)

        logger.info(f"Space item created successfully: {item.id}")

        return item

    except IntegrityError as e:
        db.rollback()
        logger.error(f"Integrity error creating space item: {e}")

        raise HTTPException(400, "Constraint violation")

    except HTTPException:
        raise

    except Exception as e:
        db.rollback()
        logger.error(f"Unexpected error creating space item: {e}")

        raise HTTPException(500, "Internal server error")
