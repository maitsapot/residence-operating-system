from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from uuid import UUID

from app.core.database import get_db
from app.core.logger import get_logger
from app.services.compliance import (
    auto_resolve_issues_for_space,
    generate_issues_from_space,
    get_space_compliance_report,
)

logger = get_logger(__name__)

router = APIRouter(prefix="/compliance", tags=["Compliance"])


def fetch_space_compliance(
    db: Session,
    space_id: UUID,
    template_type: str = "single_room",
    standard: str = "nsfas"
):
    return get_space_compliance_report(
        db=db,
        space_id=space_id,
        template_type=template_type,
        standard=standard
    )


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
        result = fetch_space_compliance(
            db=db,
            space_id=space_id,
            template_type=template_type,
            standard=standard
        )

        if not result:
            return {
                "space_id": space_id,
                "message": "No compliance data"
            }

        logger.info("[SUCCESS] Compliance fetched")

        return result

    except ValueError as e:
        logger.warning(f"Compliance validation failed: {e}")
        raise HTTPException(400, str(e))

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
