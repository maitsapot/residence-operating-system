from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy.sql import func
from typing import List
from uuid import UUID

from app.core.database import get_db
from app.core.logger import get_logger

from app.models.space import Space
from app.models.residence import Residence
from app.models.space_item import SpaceItem
from app.models.space_item_template import SpaceItemTemplate

from app.services.compliance import (
    auto_resolve_issues_for_space,
    fetch_space_compliance,
    generate_issues_from_space,
)
from app.schemas.space import SpaceCreate, SpaceResponse

logger = get_logger(__name__)

router = APIRouter(prefix="/spaces", tags=["Spaces"])


# ==========================================================
# CREATE SPACE (WITH TEMPLATE ENFORCEMENT)
# ==========================================================
@router.post("/", response_model=SpaceResponse)
def create_space(payload: SpaceCreate, db: Session = Depends(get_db)):

    logger.info(f"[START] Create space: {payload.name}")

    try:
        # ===============================
        # VALIDATE RESIDENCE
        # ===============================
        residence = db.query(Residence).filter(
            Residence.id == payload.residence_id
        ).first()

        if not residence:
            raise HTTPException(404, "Residence not found")

        # ===============================
        # RESOLVE TEMPLATE
        # ===============================
        template_type = payload.template_type or "single_room"
        standard = payload.standard or "nsfas"

        templates = db.query(SpaceItemTemplate).filter(
            SpaceItemTemplate.space_type == payload.space_type,
            SpaceItemTemplate.template_type == template_type,
            SpaceItemTemplate.standard == standard
        ).all()

        is_default_empty_template = (
            template_type == "single_room" and standard == "nsfas"
        )

        if not templates and not is_default_empty_template:
            raise HTTPException(404, "Space template not found")

        # ===============================
        # CREATE SPACE
        # ===============================
        space_data = payload.model_dump()
        space_data["template_type"] = template_type
        space_data["standard"] = standard
        space = Space(**space_data)

        db.add(space)
        db.flush()

        logger.info(f"[SUCCESS] Space created: {space.id}")

        items_to_create = []

        for template in templates:
            item = SpaceItem(
                space_id=space.id,
                item_id=template.item_id,
                quantity=template.default_quantity,
                is_required=template.is_required
            )
            items_to_create.append(item)

        if items_to_create:
            db.add_all(items_to_create)
            logger.info(f"[TEMPLATE] {len(items_to_create)} space_items created")

        db.commit()
        db.refresh(space)

        return space

    except HTTPException:
        db.rollback()
        raise

    except Exception:
        db.rollback()
        logger.error("Space creation failed", exc_info=True)
        raise HTTPException(500, "Internal server error")


# ==========================================================
# GET ALL SPACES
# ==========================================================
@router.get("/", response_model=List[SpaceResponse])
def get_spaces(
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    residence_id: UUID | None = None,
    space_type: str | None = None,
    is_rentable: bool | None = None,
    is_active: bool | None = None,
    include_archived: bool = False,
    db: Session = Depends(get_db),
):
    query = db.query(Space)
    if not include_archived:
        query = query.filter(Space.archived_at.is_(None))
    if residence_id:
        query = query.filter(Space.residence_id == residence_id)
    if space_type:
        query = query.filter(Space.space_type == space_type)
    if is_rentable is not None:
        query = query.filter(Space.is_rentable == is_rentable)
    if is_active is not None:
        query = query.filter(Space.is_active == is_active)
    return query.order_by(Space.name).offset(offset).limit(limit).all()


# ==========================================================
# GET SPACES BY RESIDENCE
# ==========================================================
@router.get("/residence/{residence_id}", response_model=List[SpaceResponse])
def get_spaces_by_residence(
    residence_id: UUID,
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    include_archived: bool = False,
    db: Session = Depends(get_db),
):
    query = db.query(Space).filter(Space.residence_id == residence_id)
    if not include_archived:
        query = query.filter(Space.archived_at.is_(None))
    return query.order_by(Space.name).offset(offset).limit(limit).all()


@router.delete("/{space_id}", response_model=SpaceResponse)
def archive_space(space_id: UUID, db: Session = Depends(get_db)):
    space = db.query(Space).filter(Space.id == space_id).first()
    if not space:
        raise HTTPException(404, "Space not found")

    space.is_active = False
    space.archived_at = func.now()
    db.commit()
    db.refresh(space)
    return space


@router.post("/{space_id}/restore", response_model=SpaceResponse)
def restore_space(space_id: UUID, db: Session = Depends(get_db)):
    space = db.query(Space).filter(Space.id == space_id).first()
    if not space:
        raise HTTPException(404, "Space not found")

    space.is_active = True
    space.archived_at = None
    db.commit()
    db.refresh(space)
    return space
    
    
# ==========================================================
# GENERATE ISSUES
# ==========================================================
@router.post("/{space_id}/generate-issues")
def generate_issues(
    space_id: UUID,
    template_type: str = "single_room",
    standard: str = "nsfas",
    reported_by: UUID = None,
    db: Session = Depends(get_db)
):
    
    logger.info(f"[START] Generate issues for space {space_id}")

    try:
        result = generate_issues_from_space(
            db=db,
            space_id=space_id,
            template_type=template_type,
            standard=standard,
            reported_by=reported_by
        )

        logger.info(f"[SUCCESS] Issues generated: {result}")

        return {
            "space_id": space_id,
            "issues_created": result
        }

    except ValueError as e:
        logger.warning(f"Generate issues validation failed: {e}")
        raise HTTPException(400, str(e))

    except Exception:
        logger.error("Generate issues failed", exc_info=True)
        raise HTTPException(500, "Failed to generate issues")


# ==========================================================
# RESOLVE ISSUES
# ==========================================================    
    
@router.post("/{space_id}/resolve-issues")
def resolve_issues(
    space_id: UUID,
    updated_by: UUID = None,
    db: Session = Depends(get_db)
):
    logger.info(f"[START] Resolve issues for space {space_id}")

    try:
        result = auto_resolve_issues_for_space(
            db=db,
            space_id=space_id,
            updated_by=updated_by
        )

        logger.info(f"[SUCCESS] Issues resolved: {result}")

        return {
            "space_id": space_id,
            "issues_resolved": result
        }

    except ValueError as e:
        logger.warning(f"Resolve issues validation failed: {e}")
        raise HTTPException(400, str(e))

    except Exception:
        logger.error("Resolve issues failed", exc_info=True)
        raise HTTPException(500, "Failed to resolve issues")
    
# ==========================================================
# COMPLIANCE ENDPOINT
# ==========================================================   
@router.get("/{space_id}/compliance")
def get_space_compliance(
    space_id: UUID,
    template_type: str = "single_room",
    standard: str = "nsfas",
    db: Session = Depends(get_db)
):
    logger.info(f"[START] Compliance check for space {space_id}")

    try:
        result = fetch_space_compliance(
            db=db,
            space_id=space_id,
            template_type=template_type,
            standard=standard
        )

        return result

    except ValueError as e:
        logger.warning(f"Compliance validation failed: {e}")
        raise HTTPException(400, str(e))

    except Exception:
        logger.error("Compliance fetch failed", exc_info=True)
        raise HTTPException(500, "Failed to fetch compliance")
