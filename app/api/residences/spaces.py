from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID
from sqlalchemy import text

from app.core.database import get_db
from app.core.logger import get_logger

from app.models.space import Space
from app.models.residence import Residence
from app.models.space_item import SpaceItem
from app.models.space_item_template import SpaceItemTemplate

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
        # CREATE SPACE
        # ===============================
        space = Space(**payload.model_dump())

        db.add(space)
        db.commit()
        db.refresh(space)

        logger.info(f"[SUCCESS] Space created: {space.id}")

        # ===============================
        # TEMPLATE ENFORCEMENT (OPTIONAL)
        # ===============================
        # Only trigger if template_type is provided
        if hasattr(payload, "template_type") and payload.template_type:

            logger.info(
                f"[TEMPLATE] Applying template: {payload.template_type} | {getattr(payload, 'standard', 'custom')}"
            )

            templates = db.query(SpaceItemTemplate).filter(
                SpaceItemTemplate.space_type == space.space_type,
                SpaceItemTemplate.template_type == payload.template_type,
                SpaceItemTemplate.standard == getattr(payload, "standard", "custom")
            ).all()

            if not templates:
                logger.warning("[TEMPLATE] No templates found")
            else:
                items_to_create = []

                for t in templates:
                    item = SpaceItem(
                        space_id=space.id,
                        catalog_id=t.catalog_id,
                        quantity=t.default_quantity,
                        is_required=t.is_required
                    )
                    items_to_create.append(item)

                db.add_all(items_to_create)
                db.commit()

                logger.info(f"[TEMPLATE] {len(items_to_create)} space_items created")

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
def get_spaces(db: Session = Depends(get_db)):
    return db.query(Space).all()


# ==========================================================
# GET SPACES BY RESIDENCE
# ==========================================================
@router.get("/residence/{residence_id}", response_model=List[SpaceResponse])
def get_spaces_by_residence(residence_id: UUID, db: Session = Depends(get_db)):
    return db.query(Space).filter(
        Space.residence_id == residence_id
    ).all()
    
    
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
        result = db.execute(
            text("""
                SELECT fn_generate_issues_from_space(
                    :space_id,
                    :template_type,
                    :standard,
                    :reported_by
                )
            """),
            {
                "space_id": str(space_id),
                "template_type": template_type,
                "standard": standard,
                "reported_by": str(reported_by) if reported_by else None
            }
        ).scalar()

        logger.info(f"[SUCCESS] Issues generated: {result}")

        return {
            "space_id": space_id,
            "issues_created": result
        }

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
        result = db.execute(
            text("""
                SELECT fn_auto_resolve_issues_for_space(
                    :space_id,
                    :updated_by
                )
            """),
            {
                "space_id": str(space_id),
                "updated_by": str(updated_by) if updated_by else None
            }
        ).scalar()

        logger.info(f"[SUCCESS] Issues resolved: {result}")

        return {
            "space_id": space_id,
            "issues_resolved": result
        }

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
        result = db.execute(
            text("""
                SELECT fn_space_compliance(
                    :space_id,
                    :template_type,
                    :standard
                )
            """),
            {
                "space_id": str(space_id),
                "template_type": template_type,
                "standard": standard
            }
        ).scalar()

        return result

    except Exception:
        logger.error("Compliance fetch failed", exc_info=True)
        raise HTTPException(500, "Failed to fetch compliance")