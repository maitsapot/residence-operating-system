from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.core.database import get_db
from app.core.logger import get_logger

from app.models.item import Item
from app.models.catalog import Catalog
from app.models.space import Space

from app.schemas.item import ItemCreate, ItemResponse

# Logger instance
logger = get_logger(__name__)

router = APIRouter(prefix="/items", tags=["Items"])


@router.post("/", response_model=ItemResponse)
def create_item(payload: ItemCreate, db: Session = Depends(get_db)):
    """
    Create a physical item.

    Enforces:
    - catalog exists
    - space exists
    - QR uniqueness
    - QR requires trackable = true
    - inherits trackable from catalog if not provided
    """

    logger.info(f"Creating item for catalog: {payload.catalog_id}")

    # 🔷 Validate catalog exists
    catalog = db.query(Catalog).filter(
        Catalog.id == payload.catalog_id
    ).first()

    if not catalog:
        logger.warning(f"Invalid catalog_id: {payload.catalog_id}")
        raise HTTPException(400, "Catalog does not exist")

    # 🔷 Validate space exists
    space = db.query(Space).filter(
        Space.id == payload.space_id
    ).first()

    if not space:
        logger.warning(f"Invalid space_id: {payload.space_id}")
        raise HTTPException(400, "Space does not exist")

    # 🔷 Resolve trackable (inherit from catalog if not explicitly set)
    is_trackable = payload.is_trackable
    if is_trackable is None:
        is_trackable = catalog.is_trackable

    # 🔷 Enforce QR rule (matches DB constraint)
    if payload.qr_code and not is_trackable:
        logger.warning("QR code provided but item is not trackable")
        raise HTTPException(400, "QR code requires trackable item")

    # 🔷 Ensure QR uniqueness (pre-check for clarity)
    if payload.qr_code:
        existing = db.query(Item).filter(
            Item.qr_code == payload.qr_code
        ).first()

        if existing:
            logger.warning(f"Duplicate QR code: {payload.qr_code}")
            raise HTTPException(400, "QR code already exists")

    # 🔷 Create item
    item = Item(
        space_id=payload.space_id,
        catalog_id=payload.catalog_id,
        name=payload.name,
        is_trackable=is_trackable,
        qr_code=payload.qr_code,
        condition=payload.condition,
        status=payload.status,
        notes=payload.notes
    )

    try:
        db.add(item)
        db.commit()
        db.refresh(item)

        logger.info(f"Item created successfully: {item.id}")
        return item

    except IntegrityError as e:
        db.rollback()
        logger.error(f"Integrity error creating item: {e}")

        raise HTTPException(400, "Constraint violation")


@router.get("/", response_model=list[ItemResponse])
def get_items(db: Session = Depends(get_db)):
    """
    Retrieve all items
    """

    logger.info("Fetching all items")

    items = db.query(Item).all()

    logger.info(f"Returned {len(items)} items")
    return items


@router.get("/space/{space_id}", response_model=list[ItemResponse])
def get_items_by_space(space_id: str, db: Session = Depends(get_db)):
    """
    Retrieve items for a specific space
    """

    logger.info(f"Fetching items for space: {space_id}")

    items = db.query(Item).filter(
        Item.space_id == space_id
    ).all()

    return items