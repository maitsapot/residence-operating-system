from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session
from typing import List, Optional

from app.core.database import get_db
from app.core.logger import get_logger
from app.models.catalog import Catalog
from app.models.space_item_template import SpaceItemTemplate
from app.schemas.space_item_template import (
    SpaceItemTemplateCreate,
    SpaceItemTemplateResponse,
)

logger = get_logger(__name__)

router = APIRouter(prefix="/space-item-templates", tags=["Space Item Templates"])


@router.post("/", response_model=SpaceItemTemplateResponse)
def create_space_item_template(
    payload: SpaceItemTemplateCreate,
    db: Session = Depends(get_db)
):
    logger.info(
        f"[START] Create space item template | "
        f"{payload.template_type}/{payload.standard}/{payload.space_type}"
    )

    catalog = db.query(Catalog).filter(Catalog.id == payload.catalog_id).first()
    if not catalog:
        raise HTTPException(400, "Catalog does not exist")

    template = SpaceItemTemplate(**payload.model_dump())

    try:
        db.add(template)
        db.commit()
        db.refresh(template)

        logger.info(f"[SUCCESS] Space item template created: {template.id}")
        return template

    except IntegrityError:
        db.rollback()
        logger.warning("[BUSINESS ERROR] Duplicate or invalid template")
        raise HTTPException(400, "Duplicate or invalid template")

    except Exception:
        db.rollback()
        logger.error("[SYSTEM ERROR] Failed to create space item template", exc_info=True)
        raise HTTPException(500, "Internal server error")


@router.get("/", response_model=List[SpaceItemTemplateResponse])
def get_space_item_templates(
    template_type: Optional[str] = None,
    standard: Optional[str] = None,
    space_type: Optional[str] = None,
    db: Session = Depends(get_db)
):
    query = db.query(SpaceItemTemplate)

    if template_type:
        query = query.filter(SpaceItemTemplate.template_type == template_type)

    if standard:
        query = query.filter(SpaceItemTemplate.standard == standard)

    if space_type:
        query = query.filter(SpaceItemTemplate.space_type == space_type)

    return query.order_by(
        SpaceItemTemplate.template_type,
        SpaceItemTemplate.standard,
        SpaceItemTemplate.space_type,
    ).all()
