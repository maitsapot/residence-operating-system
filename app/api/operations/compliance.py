from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from uuid import UUID

from app.api.openapi import COMMON_ERROR_RESPONSES
from app.core.database import get_db
from app.core.logger import get_logger
from app.schemas.compliance import (
    ComplianceDocumentCreate,
    ComplianceDocumentMediaAttach,
    ComplianceDocumentResponse,
    ComplianceDocumentStatusUpdate,
)
from app.services.compliance import (
    auto_resolve_issues_for_space,
    generate_issues_from_space,
    get_space_compliance_report,
)
from app.services.documentation_compliance import (
    archive_compliance_document,
    attach_media_to_compliance_document,
    create_compliance_document,
    get_documentation_compliance_report,
    list_compliance_documents,
    run_documentation_compliance_check,
    update_compliance_document_status,
)
from app.services.overall_compliance import (
    get_overall_compliance_report,
    run_overall_compliance_check,
)
from app.services.residence_compliance import (
    get_residence_compliance_report,
    run_residence_compliance_check,
)
from app.services.room_compliance import (
    get_room_compliance_report,
    run_room_compliance_check,
    seed_room_compliance_rules,
)

logger = get_logger(__name__)

router = APIRouter(prefix="/compliance", tags=["Compliance"])

COMPLIANCE_REPORT_EXAMPLE = {
    "scope_type": "room",
    "compliance_type": "room",
    "space_id": "11111111-1111-1111-1111-111111111111",
    "template_type": "single_room",
    "standard": "nsfas",
    "compliance": {
        "score": 50.0,
        "status": "fail",
        "required_quantity_total": 2,
        "compliant_quantity_total": 1,
        "findings_count": 1,
    },
    "performance": {
        "indicators_count": 1,
        "message": "Performance indicators are reported separately.",
    },
    "compliance_findings": [
        {
            "finding_type": "missing_required_item",
            "severity": "high",
            "item_name": "Desk",
            "expected_quantity": 1,
            "actual_quantity": 0,
        }
    ],
    "performance_indicators": [
        {
            "indicator_type": "item_condition_or_status",
            "item_name": "Chair",
            "condition": "damaged",
            "status": "active",
        }
    ],
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


@router.get(
    "/rooms/{space_id}",
    summary="Get room compliance",
    description=(
        "Calculates room compliance for a private/rentable room. This checks "
        "required room inventory presence and quantity. Broken or damaged items "
        "are returned as performance indicators, not compliance failures, unless "
        "a rule explicitly requires usable condition."
    ),
    responses={
        200: {
            "description": "Room compliance report returned.",
            "content": {"application/json": {"example": COMPLIANCE_REPORT_EXAMPLE}},
        },
        **COMMON_ERROR_RESPONSES,
    },
)
def get_room_compliance(
    space_id: UUID,
    template_type: str = "single_room",
    standard: str = "nsfas",
    db: Session = Depends(get_db)
):
    logger.info(f"[START] Room compliance check | space={space_id}")

    try:
        return get_room_compliance_report(
            db=db,
            space_id=space_id,
            template_type=template_type,
            standard=standard,
        )

    except ValueError as e:
        logger.warning(f"Room compliance validation failed: {e}")
        raise HTTPException(400, str(e))

    except Exception:
        logger.error("Room compliance fetch failed", exc_info=True)
        raise HTTPException(500, "Failed to fetch room compliance")


@router.post(
    "/rooms/{space_id}/check",
    summary="Run room compliance check",
    description=(
        "Calculates and persists an auditable room compliance check. Findings are "
        "stored for missing required items or quantity shortfalls. Performance "
        "indicators remain separate from compliance findings."
    ),
    responses={
        200: {
            "description": "Room compliance check persisted.",
            "content": {"application/json": {"example": {**COMPLIANCE_REPORT_EXAMPLE, "check_id": "99999999-9999-9999-9999-999999999999"}}},
        },
        **COMMON_ERROR_RESPONSES,
    },
)
def run_room_compliance(
    space_id: UUID,
    template_type: str = "single_room",
    standard: str = "nsfas",
    checked_by: UUID = None,
    db: Session = Depends(get_db)
):
    logger.info(f"[START] Persist room compliance check | space={space_id}")

    try:
        return run_room_compliance_check(
            db=db,
            space_id=space_id,
            template_type=template_type,
            standard=standard,
            checked_by=checked_by,
        )

    except ValueError as e:
        logger.warning(f"Room compliance check validation failed: {e}")
        raise HTTPException(400, str(e))

    except Exception:
        logger.error("Room compliance check failed", exc_info=True)
        raise HTTPException(500, "Failed to run room compliance check")


@router.post(
    "/rooms/rules/seed",
    summary="Seed room compliance rules",
    description="Creates default room required-item compliance rules from active room templates.",
    responses=COMMON_ERROR_RESPONSES,
)
def seed_room_rules(
    template_type: str = "single_room",
    standard: str = "nsfas",
    db: Session = Depends(get_db)
):
    try:
        created = seed_room_compliance_rules(
            db=db,
            template_type=template_type,
            standard=standard,
        )
        return {"rules_created": created}
    except Exception:
        logger.error("Room compliance rule seeding failed", exc_info=True)
        raise HTTPException(500, "Failed to seed room compliance rules")


@router.get(
    "/residences/{residence_id}",
    summary="Get residence compliance",
    description=(
        "Calculates residence compliance for shared spaces and required role "
        "assignments. Rooms are handled by room compliance; condition and student "
        "ratings are performance, not compliance."
    ),
    responses=COMMON_ERROR_RESPONSES,
)
def get_residence_compliance(
    residence_id: UUID,
    standard: str = "nsfas",
    template_type: str = "single_room",
    db: Session = Depends(get_db)
):
    try:
        return get_residence_compliance_report(
            db=db,
            residence_id=residence_id,
            standard=standard,
            template_type=template_type,
        )
    except ValueError as e:
        raise HTTPException(400, str(e))
    except Exception:
        logger.error("Residence compliance fetch failed", exc_info=True)
        raise HTTPException(500, "Failed to fetch residence compliance")


@router.post(
    "/residences/{residence_id}/check",
    summary="Run residence compliance check",
    description="Calculates and persists an auditable residence compliance check.",
    responses=COMMON_ERROR_RESPONSES,
)
def run_residence_compliance(
    residence_id: UUID,
    standard: str = "nsfas",
    template_type: str = "single_room",
    checked_by: UUID = None,
    db: Session = Depends(get_db)
):
    try:
        return run_residence_compliance_check(
            db=db,
            residence_id=residence_id,
            standard=standard,
            template_type=template_type,
            checked_by=checked_by,
        )
    except ValueError as e:
        raise HTTPException(400, str(e))
    except Exception:
        logger.error("Residence compliance check failed", exc_info=True)
        raise HTTPException(500, "Failed to run residence compliance check")


@router.post(
    "/documents",
    response_model=ComplianceDocumentResponse,
    summary="Create compliance document",
    description=(
        "Creates a residence documentation compliance record. The uploaded file "
        "itself is managed through media attachments and can be linked here."
    ),
    responses=COMMON_ERROR_RESPONSES,
)
def create_document_compliance_record(
    payload: ComplianceDocumentCreate,
    db: Session = Depends(get_db),
):
    try:
        return create_compliance_document(db, payload)
    except HTTPException:
        raise
    except Exception:
        logger.error("Compliance document creation failed", exc_info=True)
        raise HTTPException(500, "Failed to create compliance document")


@router.get(
    "/residences/{residence_id}/documents",
    response_model=list[ComplianceDocumentResponse],
    summary="List residence compliance documents",
    description="Lists required certification/documentation records for a residence.",
    responses=COMMON_ERROR_RESPONSES,
)
def list_document_compliance_records(
    residence_id: UUID,
    document_type: str = None,
    status: str = None,
    include_archived: bool = False,
    db: Session = Depends(get_db),
):
    try:
        return list_compliance_documents(
            db,
            residence_id=residence_id,
            document_type=document_type,
            status=status,
            include_archived=include_archived,
        )
    except HTTPException:
        raise
    except Exception:
        logger.error("Compliance document listing failed", exc_info=True)
        raise HTTPException(500, "Failed to list compliance documents")


@router.patch(
    "/documents/{document_id}/status",
    response_model=ComplianceDocumentResponse,
    summary="Update compliance document status",
    description="Approves, rejects, expires, or marks a submitted compliance document.",
    responses=COMMON_ERROR_RESPONSES,
)
def update_document_compliance_status(
    document_id: UUID,
    payload: ComplianceDocumentStatusUpdate,
    db: Session = Depends(get_db),
):
    try:
        return update_compliance_document_status(
            db,
            document_id=document_id,
            payload=payload,
        )
    except HTTPException:
        raise
    except Exception:
        logger.error("Compliance document status update failed", exc_info=True)
        raise HTTPException(500, "Failed to update compliance document status")


@router.post(
    "/documents/{document_id}/attach-media",
    response_model=ComplianceDocumentResponse,
    summary="Attach media to compliance document",
    description="Links an uploaded media attachment to a certification/documentation record.",
    responses=COMMON_ERROR_RESPONSES,
)
def attach_document_compliance_media(
    document_id: UUID,
    payload: ComplianceDocumentMediaAttach,
    db: Session = Depends(get_db),
):
    try:
        return attach_media_to_compliance_document(
            db,
            document_id=document_id,
            media_attachment_id=payload.media_attachment_id,
        )
    except HTTPException:
        raise
    except Exception:
        logger.error("Compliance document media attachment failed", exc_info=True)
        raise HTTPException(500, "Failed to attach media to compliance document")


@router.delete(
    "/documents/{document_id}",
    response_model=ComplianceDocumentResponse,
    summary="Archive compliance document",
    description="Soft deletes a compliance document record from active documentation checks.",
    responses=COMMON_ERROR_RESPONSES,
)
def archive_document_compliance_record(
    document_id: UUID,
    db: Session = Depends(get_db),
):
    try:
        return archive_compliance_document(db, document_id)
    except HTTPException:
        raise
    except Exception:
        logger.error("Compliance document archive failed", exc_info=True)
        raise HTTPException(500, "Failed to archive compliance document")


@router.get(
    "/residences/{residence_id}/documents/compliance",
    summary="Get documentation compliance",
    description=(
        "Calculates documentation/certification compliance for a residence. This "
        "checks required document existence, attachment, approval, and expiry."
    ),
    responses=COMMON_ERROR_RESPONSES,
)
def get_documentation_compliance(
    residence_id: UUID,
    standard: str = "nsfas",
    db: Session = Depends(get_db),
):
    try:
        return get_documentation_compliance_report(
            db=db,
            residence_id=residence_id,
            standard=standard,
        )
    except HTTPException:
        raise
    except Exception:
        logger.error("Documentation compliance fetch failed", exc_info=True)
        raise HTTPException(500, "Failed to fetch documentation compliance")


@router.post(
    "/residences/{residence_id}/documents/check",
    summary="Run documentation compliance check",
    description="Calculates and persists an auditable documentation compliance check.",
    responses=COMMON_ERROR_RESPONSES,
)
def run_documentation_compliance(
    residence_id: UUID,
    standard: str = "nsfas",
    checked_by: UUID = None,
    db: Session = Depends(get_db),
):
    try:
        return run_documentation_compliance_check(
            db=db,
            residence_id=residence_id,
            standard=standard,
            checked_by=checked_by,
        )
    except HTTPException:
        raise
    except Exception:
        logger.error("Documentation compliance check failed", exc_info=True)
        raise HTTPException(500, "Failed to run documentation compliance check")


@router.get(
    "/overall/residences/{residence_id}",
    summary="Get overall compliance",
    description=(
        "Combines room, residence, and documentation compliance into one overall "
        "compliance score. Performance signals such as ratings, item condition, "
        "and maintenance speed are intentionally excluded."
    ),
    responses=COMMON_ERROR_RESPONSES,
)
def get_overall_compliance(
    residence_id: UUID,
    standard: str = "nsfas",
    template_type: str = "single_room",
    db: Session = Depends(get_db),
):
    try:
        return get_overall_compliance_report(
            db=db,
            residence_id=residence_id,
            standard=standard,
            template_type=template_type,
        )
    except ValueError as e:
        raise HTTPException(400, str(e))
    except HTTPException:
        raise
    except Exception:
        logger.error("Overall compliance fetch failed", exc_info=True)
        raise HTTPException(500, "Failed to fetch overall compliance")


@router.post(
    "/overall/residences/{residence_id}/check",
    summary="Run overall compliance check",
    description="Calculates and persists an auditable overall compliance check.",
    responses=COMMON_ERROR_RESPONSES,
)
def run_overall_compliance(
    residence_id: UUID,
    standard: str = "nsfas",
    template_type: str = "single_room",
    checked_by: UUID = None,
    db: Session = Depends(get_db),
):
    try:
        return run_overall_compliance_check(
            db=db,
            residence_id=residence_id,
            standard=standard,
            template_type=template_type,
            checked_by=checked_by,
        )
    except ValueError as e:
        raise HTTPException(400, str(e))
    except HTTPException:
        raise
    except Exception:
        logger.error("Overall compliance check failed", exc_info=True)
        raise HTTPException(500, "Failed to run overall compliance check")


# =========================================================
# GET COMPLIANCE FOR SPACE
# =========================================================
@router.get(
    "/spaces/{space_id}",
    summary="Get space compliance",
    description=(
        "Legacy compatibility endpoint. For room spaces, this returns the room "
        "compliance report. Residence-level shared spaces will move to dedicated "
        "residence compliance endpoints."
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
