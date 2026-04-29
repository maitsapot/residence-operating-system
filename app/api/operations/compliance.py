from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from uuid import UUID

from app.api.openapi import COMMON_ERROR_RESPONSES
from app.core.database import get_db
from app.core.logger import get_logger
from app.services.compliance import (
    auto_resolve_issues_for_space,
    generate_issues_from_space,
    get_space_compliance_report,
)

logger = get_logger(__name__)

router = APIRouter(prefix="/compliance", tags=["Compliance"])

COMPLIANCE_REPORT_EXAMPLE = {
    "space_id": "11111111-1111-1111-1111-111111111111",
    "template_type": "single_room",
    "standard": "nsfas",
    "missing_items": [
        {
            "item_id": "22222222-2222-2222-2222-222222222222",
            "item_name": "Desk",
            "required_quantity": 1,
        }
    ],
    "extra_items": [],
    "bad_items": [
        {
            "space_item_id": "33333333-3333-3333-3333-333333333333",
            "item_id": "22222222-2222-2222-2222-222222222222",
            "item_name": "Desk",
            "condition": "damaged",
            "status": "active",
            "quantity": 1,
        }
    ],
    "score": {
        "total_required": 2,
        "compliant_items": 0,
        "missing_items": 1,
        "bad_items": 1,
        "extra_items": 0,
        "compliance_percentage": 0.0,
    },
}


# =========================================================
# GET COMPLIANCE FOR SPACE
# =========================================================
@router.get(
    "/spaces/{space_id}",
    summary="Get space compliance",
    description=(
        "Calculates compliance for a space against the selected template and "
        "standard, including missing, extra, and non-compliant items."
    ),
    responses={
        200: {
            "description": "Compliance report returned.",
            "content": {"application/json": {"example": COMPLIANCE_REPORT_EXAMPLE}},
        },
        **COMMON_ERROR_RESPONSES,
    },
)
def get_space_compliance(
    space_id: UUID,
    template_type: str = "single_room",
    standard: str = "nsfas",
    db: Session = Depends(get_db)
):
    logger.info(f"[START] Compliance check | space={space_id}")

    try:
        result = get_space_compliance_report(
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
@router.post(
    "/spaces/{space_id}/generate-issues",
    summary="Generate compliance issues",
    description=(
        "Creates maintenance issues for required space items that are damaged, "
        "inactive, or otherwise non-compliant. Existing active issues are not duplicated."
    ),
    responses={
        200: {
            "description": "Compliance issues generated.",
            "content": {
                "application/json": {
                    "example": {
                        "space_id": "11111111-1111-1111-1111-111111111111",
                        "issues_created": 2,
                    }
                }
            },
        },
        **COMMON_ERROR_RESPONSES,
    },
)
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
@router.post(
    "/spaces/{space_id}/resolve-issues",
    summary="Resolve restored-item issues",
    description=(
        "Auto-resolves active issues for a space when the linked space item has "
        "returned to good condition and active status."
    ),
    responses={
        200: {
            "description": "Eligible issues resolved.",
            "content": {
                "application/json": {
                    "example": {
                        "space_id": "11111111-1111-1111-1111-111111111111",
                        "issues_resolved": 1,
                    }
                }
            },
        },
        **COMMON_ERROR_RESPONSES,
    },
)
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
