from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from uuid import UUID

from app.core.database import get_db
from app.core.logger import get_logger

logger = get_logger(__name__)

router = APIRouter(prefix="/compliance", tags=["Compliance"])


# =========================================================
# GET COMPLIANCE FOR SPACE
# =========================================================
@router.get("/spaces/{space_id}")
def get_space_compliance(
    space_id: UUID,
    template_type: str = "single_room",
    standard: str = "nsfas",
    db: Session = Depends(get_db)
):
    logger.info(f"[START] Compliance check | space={space_id}")

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

        if not result:
            return {
                "space_id": space_id,
                "message": "No compliance data"
            }

        logger.info("[SUCCESS] Compliance fetched")

        return result

    except Exception:
        logger.error("Compliance fetch failed", exc_info=True)
        raise HTTPException(500, "Failed to fetch compliance")


# =========================================================
# GENERATE ISSUES FROM SPACE
# =========================================================
@router.post("/spaces/{space_id}/generate-issues")
def generate_issues(
    space_id: UUID,
    template_type: str = "single_room",
    standard: str = "nsfas",
    reported_by: UUID = None,
    db: Session = Depends(get_db)
):
    logger.info(f"[START] Generate issues | space={space_id}")

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


# =========================================================
# AUTO RESOLVE ISSUES
# =========================================================
@router.post("/spaces/{space_id}/resolve-issues")
def resolve_issues(
    space_id: UUID,
    updated_by: UUID = None,
    db: Session = Depends(get_db)
):
    logger.info(f"[START] Resolve issues | space={space_id}")

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