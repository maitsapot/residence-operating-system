from uuid import UUID

from fastapi import HTTPException
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session
from sqlalchemy.sql import func

from app.core.logger import get_logger
from app.models.common_issue import CommonIssue
from app.models.inspection import Inspection
from app.models.issue import Issue
from app.models.space import Space
from app.models.space_item import SpaceItem
from app.schemas.inspection import (
    InspectionCreate,
    InspectionSignOff,
    InspectionUpdate,
)
from app.services.issue import get_primary_manager_id, log_issue_update

logger = get_logger(__name__)


def get_inspection_or_404(db: Session, inspection_id: UUID):
    inspection = db.query(Inspection).filter(
        Inspection.id == inspection_id
    ).first()

    if not inspection:
        logger.warning(f"Inspection not found: {inspection_id}")
        raise HTTPException(404, "Inspection not found")

    return inspection


def validate_inspection_payload(payload):
    if payload.inspection_type in ["checkin", "checkout"] and not payload.tenancy_id:
        logger.warning("Missing tenancy_id for checkin/checkout inspection")
        raise HTTPException(400, "tenancy_id required")

    if payload.status == "completed":
        if not (payload.inspector_signed_off and payload.tenant_signed_off):
            logger.warning("Attempt to complete inspection without signatures")
            raise HTTPException(400, "Signatures required")


def should_create_issue(inspection):
    if inspection.status != "completed":
        return False

    if inspection.inspection_type == "routine":
        return inspection.condition == "damaged"

    if inspection.inspection_type == "audit":
        return inspection.condition in ["poor", "damaged"]

    if inspection.inspection_type == "checkin":
        return False

    if inspection.inspection_type == "checkout":
        return inspection.condition in ["poor", "damaged"]

    return False


def resolve_common_issue(db, space_item):
    common_issue = db.query(CommonIssue).filter(
        CommonIssue.item_id == space_item.item_id,
        CommonIssue.is_active == True
    ).first()

    if common_issue:
        return {
            "common_issue_id": common_issue.id,
            "severity": common_issue.default_severity,
            "urgency": common_issue.default_urgency,
            "description": common_issue.issue_name
        }

    return None


def handle_inspection_issue(db, inspection):
    if not should_create_issue(inspection):
        logger.info(f"[AUTOMATION] No issue required for inspection {inspection.id}")
        return

    logger.info(f"[AUTOMATION] Inspection {inspection.id} qualifies for issue creation")

    existing_issue = db.query(Issue).filter(
        Issue.space_item_id == inspection.space_item_id,
        Issue.status.in_(["open", "assigned", "in_progress"])
    ).first()

    if existing_issue:
        logger.info("[AUTOMATION] Existing issue found; skipping creation")
        return

    space_item = db.query(SpaceItem).filter(
        SpaceItem.id == inspection.space_item_id
    ).first()

    if not space_item:
        logger.warning("[AUTOMATION] SpaceItem not found")
        return

    space = db.query(Space).filter(
        Space.id == space_item.space_id
    ).first()

    if not space:
        logger.warning("[AUTOMATION] Space not found")
        return

    manager_id = get_primary_manager_id(db, space.residence_id)

    issue_data = resolve_common_issue(db, space_item)
    if not issue_data:
        logger.warning("[AUTOMATION] No common issue found; skipping issue creation")
        return

    issue = Issue(
        reported_by=inspection.inspected_by,
        space_id=space.id,
        space_item_id=inspection.space_item_id,
        inspection_id=inspection.id,
        tenancy_id=inspection.tenancy_id,
        description=issue_data["description"],
        common_issue_id=issue_data["common_issue_id"],
        severity=issue_data["severity"],
        urgency=issue_data["urgency"],
        assigned_to=manager_id,
        status="assigned" if manager_id else "open"
    )

    db.add(issue)
    db.flush()

    log_issue_update(
        db=db,
        issue=issue,
        updated_by=inspection.inspected_by,
        update_type="system",
        comment="Auto-created from inspection",
        new_status=issue.status,
    )

    logger.info(f"[AUTOMATION] Issue {issue.id} created from inspection {inspection.id}")


def create_inspection(db: Session, payload: InspectionCreate):
    logger.info(f"Creating inspection for space_item: {payload.space_item_id}")

    try:
        space_item = db.query(SpaceItem).filter(
            SpaceItem.id == payload.space_item_id
        ).first()

        if not space_item:
            logger.warning("Space item not found")
            raise HTTPException(400, "Space item not found")

        validate_inspection_payload(payload)

        inspection = Inspection(**payload.model_dump())

        db.add(inspection)
        db.flush()

        handle_inspection_issue(db, inspection)

        db.commit()
        db.refresh(inspection)

        logger.info(f"Inspection created successfully: {inspection.id}")

        return inspection

    except HTTPException:
        db.rollback()
        raise

    except IntegrityError as e:
        db.rollback()
        logger.error(f"Integrity error creating inspection: {e}")
        raise HTTPException(400, "Constraint violation")

    except Exception as e:
        db.rollback()
        logger.error(f"Unexpected error creating inspection: {e}")
        raise HTTPException(500, "Internal server error")


def get_inspections(
    db: Session,
    *,
    offset: int = 0,
    limit: int = 50,
    status: str | None = None,
    inspection_type: str | None = None,
    inspected_by: UUID | None = None,
):
    logger.info("[START] Fetch all inspections")

    query = db.query(Inspection)
    if status:
        query = query.filter(Inspection.status == status)
    if inspection_type:
        query = query.filter(Inspection.inspection_type == inspection_type)
    if inspected_by:
        query = query.filter(Inspection.inspected_by == inspected_by)

    inspections = query.order_by(
        Inspection.created_at.desc()
    ).offset(offset).limit(limit).all()

    logger.info(f"[SUCCESS] Returned {len(inspections)} inspections")
    return inspections


def get_inspections_by_space(
    db: Session,
    space_id: UUID,
    *,
    offset: int = 0,
    limit: int = 50,
    status: str | None = None,
    inspection_type: str | None = None,
):
    logger.info(f"[START] Fetch inspections by space | space={space_id}")

    query = db.query(Inspection).join(
        SpaceItem,
        Inspection.space_item_id == SpaceItem.id
    ).filter(
        SpaceItem.space_id == space_id
    )
    if status:
        query = query.filter(Inspection.status == status)
    if inspection_type:
        query = query.filter(Inspection.inspection_type == inspection_type)

    inspections = query.order_by(
        Inspection.created_at.desc()
    ).offset(offset).limit(limit).all()

    logger.info(f"[SUCCESS] Returned {len(inspections)} inspections for space")
    return inspections


def get_inspections_by_tenancy(
    db: Session,
    tenancy_id: UUID,
    *,
    offset: int = 0,
    limit: int = 50,
    status: str | None = None,
):
    logger.info(f"[START] Fetch inspections by tenancy | tenancy={tenancy_id}")

    query = db.query(Inspection).filter(
        Inspection.tenancy_id == tenancy_id
    )
    if status:
        query = query.filter(Inspection.status == status)

    inspections = query.order_by(
        Inspection.created_at.desc()
    ).offset(offset).limit(limit).all()

    logger.info(f"[SUCCESS] Returned {len(inspections)} inspections for tenancy")
    return inspections


def get_inspections_by_residence(
    db: Session,
    residence_id: UUID,
    *,
    offset: int = 0,
    limit: int = 50,
    status: str | None = None,
    inspection_type: str | None = None,
):
    logger.info(f"[START] Fetch inspections by residence | residence={residence_id}")

    query = db.query(Inspection).join(
        SpaceItem,
        Inspection.space_item_id == SpaceItem.id
    ).join(
        Space,
        Space.id == SpaceItem.space_id
    ).filter(
        Space.residence_id == residence_id
    )
    if status:
        query = query.filter(Inspection.status == status)
    if inspection_type:
        query = query.filter(Inspection.inspection_type == inspection_type)

    inspections = query.order_by(
        Inspection.created_at.desc()
    ).offset(offset).limit(limit).all()

    logger.info(f"[SUCCESS] Returned {len(inspections)} inspections for residence")
    return inspections


def sign_off_inspection(
    db: Session,
    inspection_id: UUID,
    payload: InspectionSignOff,
):
    logger.info(
        f"[START] Sign-off inspection | inspection={inspection_id} role={payload.role}"
    )

    try:
        inspection = get_inspection_or_404(db, inspection_id)

        if inspection.status == "completed":
            raise HTTPException(400, "Completed inspections cannot be signed off")

        if payload.role == "inspector":
            inspection.inspector_signed_off = True
            inspection.inspector_signature = payload.signature
        elif payload.role == "tenant":
            inspection.tenant_signed_off = True
            inspection.tenant_signature = payload.signature
        else:
            raise HTTPException(400, "role must be 'inspector' or 'tenant'")

        inspection.updated_at = func.now()

        db.commit()
        db.refresh(inspection)

        logger.info(f"[SUCCESS] Inspection signed off: {inspection.id}")
        return inspection

    except HTTPException:
        db.rollback()
        raise

    except Exception as e:
        db.rollback()
        logger.error(f"Unexpected error signing off inspection: {e}", exc_info=True)
        raise HTTPException(500, "Internal server error")


def complete_inspection(db: Session, inspection_id: UUID):
    logger.info(f"[START] Complete inspection | inspection={inspection_id}")

    try:
        inspection = get_inspection_or_404(db, inspection_id)

        if inspection.status == "completed":
            raise HTTPException(400, "Inspection already completed")

        if not (inspection.inspector_signed_off and inspection.tenant_signed_off):
            logger.warning("Attempt to complete inspection without both sign-offs")
            raise HTTPException(400, "Signatures required")

        inspection.status = "completed"
        inspection.updated_at = func.now()

        handle_inspection_issue(db, inspection)

        db.commit()
        db.refresh(inspection)

        logger.info(f"[SUCCESS] Inspection completed: {inspection.id}")
        return inspection

    except HTTPException:
        db.rollback()
        raise

    except Exception as e:
        db.rollback()
        logger.error(f"Unexpected error completing inspection: {e}", exc_info=True)
        raise HTTPException(500, "Internal server error")


def update_inspection(
    db: Session,
    inspection_id: UUID,
    payload: InspectionUpdate,
):
    logger.info(f"[START] Update inspection | inspection={inspection_id}")

    try:
        inspection = get_inspection_or_404(db, inspection_id)

        if inspection.status == "completed":
            raise HTTPException(400, "Completed inspections cannot be updated")

        update_data = payload.model_dump(exclude_unset=True)

        if "status" in update_data:
            raise HTTPException(400, "Use the complete endpoint to complete inspections")

        for field, value in update_data.items():
            setattr(inspection, field, value)

        validate_inspection_payload(inspection)

        inspection.updated_at = func.now()

        db.commit()
        db.refresh(inspection)

        logger.info(f"[SUCCESS] Inspection updated: {inspection.id}")
        return inspection

    except HTTPException:
        db.rollback()
        raise

    except IntegrityError as e:
        db.rollback()
        logger.error(f"Integrity error updating inspection: {e}")
        raise HTTPException(400, "Constraint violation")

    except Exception as e:
        db.rollback()
        logger.error(f"Unexpected error updating inspection: {e}", exc_info=True)
        raise HTTPException(500, "Internal server error")


def get_inspection(db: Session, inspection_id: UUID):
    logger.info(f"[START] Fetch inspection | inspection={inspection_id}")

    inspection = get_inspection_or_404(db, inspection_id)

    logger.info(f"[SUCCESS] Inspection found: {inspection.id}")
    return inspection
