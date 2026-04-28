from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.core.database import get_db
from app.core.logger import get_logger

from app.models.space_item import SpaceItem
from app.models.catalog import Catalog
from app.models.space import Space

from app.schemas.space_item import SpaceItemCreate, SpaceItemResponse

logger = get_logger(__name__)

router = APIRouter(prefix="/space-items", tags=["Space Items"])


@router.post("/", response_model=SpaceItemResponse)
def create_space_item(
    payload: SpaceItemCreate,
    db: Session = Depends(get_db)
):
    """
    Create expected item for a space.

    Enforces:
    - one catalog per space
    - catalog allowed_space_type matches space
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

        # 🔷 Validate catalog
        catalog = db.query(Catalog).filter(
            Catalog.id == payload.catalog_id
        ).first()

        if not catalog:
            logger.warning(f"Catalog not found: {payload.catalog_id}")
            raise HTTPException(400, "Catalog not found")

        # 🔥 CRITICAL: enforce allowed_space_type
        if catalog.allowed_space_type and catalog.allowed_space_type != space.space_type:
            logger.warning(
                f"Catalog {catalog.id} not allowed in space type {space.space_type}"
            )
            raise HTTPException(
                400,
                f"Catalog not allowed in {space.space_type}"
            )

        # 🔷 Prevent duplicates (also backed by DB unique constraint)
        existing = db.query(SpaceItem).filter(
            SpaceItem.space_id == payload.space_id,
            SpaceItem.catalog_id == payload.catalog_id
        ).first()

        if existing:
            logger.warning(
                f"Duplicate space_item for space {payload.space_id} and catalog {payload.catalog_id}"
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

    except Exception as e:
        db.rollback()
        logger.error(f"Unexpected error creating space item: {e}")

        raise HTTPException(500, "Internal server error")