from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from sqlalchemy.sql import func
from typing import List
from uuid import UUID

from app.core.database import get_db
from app.core.logger import get_logger

from app.models.inspection import Inspection
from app.models.space_item import SpaceItem
from app.models.space import Space
from app.models.issue import Issue
from app.models.issue_update import IssueUpdate
from app.models.residence_manager import ResidenceManager

from app.schemas.inspection import (
    InspectionCreate,
    InspectionResponse,
    InspectionSignOff,
    InspectionUpdate,
)

logger = get_logger(__name__)

router = APIRouter(prefix="/inspections", tags=["Inspections"])

from app.models.common_issue import CommonIssue


def get_primary_manager_id(db: Session, residence_id):
    primary_manager = db.query(ResidenceManager).filter(
        ResidenceManager.residence_id == residence_id,
        ResidenceManager.is_primary == True
    ).first()

    if primary_manager:
        return primary_manager.manager_id

    fallback_manager = db.query(ResidenceManager).filter(
        ResidenceManager.residence_id == residence_id
    ).first()

    return fallback_manager.manager_id if fallback_manager else None


def get_inspection_or_404(db: Session, inspection_id: UUID):
    inspection = db.query(Inspection).filter(
        Inspection.id == inspection_id
    ).first()

    if not inspection:
        logger.warning(f"Inspection not found: {inspection_id}")
        raise HTTPException(404, "Inspection not found")

    return inspection


def validate_inspection_payload(payload):
    """
    Applies business rules shared by create, update and complete operations.
    """

    if payload.inspection_type in ["checkin", "checkout"] and not payload.tenancy_id:
        logger.warning("Missing tenancy_id for checkin/checkout inspection")
        raise HTTPException(400, "tenancy_id required")

    if payload.status == "completed":
        if not (payload.inspector_signed_off and payload.tenant_signed_off):
            logger.warning("Attempt to complete inspection without signatures")
            raise HTTPException(400, "Signatures required")


# ==========================================================
# 🔧 HELPER — ISSUE AUDIT LOG
# ==========================================================
def log_issue_update(db, issue, updated_by, comment):
    """
    Creates an audit record for system-generated issue actions
    """
    update = IssueUpdate(
        issue_id=issue.id,
        updated_by=updated_by,
        update_type="system",
        comment=comment,
        new_status=issue.status
    )
    db.add(update)


# ==========================================================
# 🧠 NEW HELPER — DECISION ENGINE
# ==========================================================
def should_create_issue(inspection):
    """
    Determines whether an inspection should create an issue.

    This prevents unnecessary issue creation and keeps the system clean.
    """

    # 🔷 Only completed inspections should trigger issues
    if inspection.status != "completed":
        return False

    # 🔷 Routine inspections → only damaged
    if inspection.inspection_type == "routine":
        return inspection.condition == "damaged"

    # 🔷 Audit inspections → stricter
    if inspection.inspection_type == "audit":
        return inspection.condition in ["poor", "damaged"]

    # 🔷 Check-in → baseline capture only
    if inspection.inspection_type == "checkin":
        return False

    # 🔷 Checkout → tenant liability detection
    if inspection.inspection_type == "checkout":
        return inspection.condition in ["poor", "damaged"]

    return False


# ==========================================================
# 🔥 CORE AUTOMATION — INSPECTION → ISSUE
# ==========================================================
def handle_inspection_issue(db, inspection):
    """
    Automatically creates an issue based on inspection rules.

    Enhancements:
    - Uses decision engine (should_create_issue)
    - Prevents duplicates
    - Assigns to manager
    - Logs audit trail
    """

    # 🔥 NEW: decision engine
    if not should_create_issue(inspection):
        logger.info(f"[AUTOMATION] No issue required for inspection {inspection.id}")
        return

    logger.info(f"[AUTOMATION] Inspection {inspection.id} qualifies for issue creation")

    # 🔷 Prevent duplicate active issues
    existing_issue = db.query(Issue).filter(
        Issue.space_item_id == inspection.space_item_id,
        Issue.status.in_(["open", "assigned", "in_progress"])
    ).first()

    if existing_issue:
        logger.info(f"[AUTOMATION] Existing issue found → skipping creation")
        return

    # 🔷 Resolve space_item → space
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

    # 🔷 Resolve primary manager (default assignment)
    manager_id = get_primary_manager_id(db, space.residence_id)

    # 🔷 Create issue
    
    # 🔥 NEW: resolve intelligent issue defaults
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

    # 🔥 Audit log
    log_issue_update(
        db=db,
        issue=issue,
        updated_by=inspection.inspected_by,
        comment="Auto-created from inspection"
    )

    logger.info(f"[AUTOMATION] Issue {issue.id} created from inspection {inspection.id}")


# ==========================================================
# 🧠 HELPER — COMMON ISSUE RESOLUTION
# ==========================================================
def resolve_common_issue(db, space_item):
    """
    Resolves a common issue for a given space_item via catalog.

    Returns:
    - common_issue_id
    - severity
    - urgency
    - description
    """

    common_issue = db.query(CommonIssue).filter(
        CommonIssue.catalog_id == space_item.catalog_id,
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


# ==========================================================
# 🚀 CREATE INSPECTION
# ==========================================================
@router.post("/", response_model=InspectionResponse)
def create_inspection(payload: InspectionCreate, db: Session = Depends(get_db)):
    """
    Create inspection record.

    Enforces:
    - space_item must exist
    - checkin/checkout requires tenancy_id
    - completed requires both signatures

    Also triggers:
    - intelligent issue automation
    """

    logger.info(f"Creating inspection for space_item: {payload.space_item_id}")

    try:
        # 🔷 Validate space_item
        space_item = db.query(SpaceItem).filter(
            SpaceItem.id == payload.space_item_id
        ).first()

        if not space_item:
            logger.warning("Space item not found")
            raise HTTPException(400, "Space item not found")

        # 🔷 Apply shared inspection business rules
        validate_inspection_payload(payload)

        # 🔷 Create inspection
        inspection = Inspection(**payload.dict())

        db.add(inspection)
        db.flush()

        # 🔥 AUTOMATION TRIGGER
        handle_inspection_issue(db, inspection)

        db.commit()
        db.refresh(inspection)

        logger.info(f"Inspection created successfully: {inspection.id}")

        return inspection

    except IntegrityError as e:
        db.rollback()
        logger.error(f"Integrity error creating inspection: {e}")
        raise HTTPException(400, "Constraint violation")

    except Exception as e:
        db.rollback()
        logger.error(f"Unexpected error creating inspection: {e}")
        raise HTTPException(500, "Internal server error")


# ==========================================================
# 📥 GET — ALL INSPECTIONS
# ==========================================================
@router.get("/", response_model=List[InspectionResponse])
def get_inspections(db: Session = Depends(get_db)):
    logger.info("[START] Fetch all inspections")

    inspections = db.query(Inspection).order_by(
        Inspection.created_at.desc()
    ).all()

    logger.info(f"[SUCCESS] Returned {len(inspections)} inspections")
    return inspections


# ==========================================================
# 📥 GET — BY SPACE
# ==========================================================
@router.get("/space/{space_id}", response_model=List[InspectionResponse])
def get_inspections_by_space(space_id: UUID, db: Session = Depends(get_db)):
    logger.info(f"[START] Fetch inspections by space | space={space_id}")

    inspections = db.query(Inspection).join(
        SpaceItem,
        Inspection.space_item_id == SpaceItem.id
    ).filter(
        SpaceItem.space_id == space_id
    ).order_by(
        Inspection.created_at.desc()
    ).all()

    logger.info(f"[SUCCESS] Returned {len(inspections)} inspections for space")
    return inspections


# ==========================================================
# 📥 GET — BY TENANCY
# ==========================================================
@router.get("/tenancy/{tenancy_id}", response_model=List[InspectionResponse])
def get_inspections_by_tenancy(tenancy_id: UUID, db: Session = Depends(get_db)):
    logger.info(f"[START] Fetch inspections by tenancy | tenancy={tenancy_id}")

    inspections = db.query(Inspection).filter(
        Inspection.tenancy_id == tenancy_id
    ).order_by(
        Inspection.created_at.desc()
    ).all()

    logger.info(f"[SUCCESS] Returned {len(inspections)} inspections for tenancy")
    return inspections


# ==========================================================
# 📥 GET — BY RESIDENCE
# ==========================================================
@router.get("/residence/{residence_id}", response_model=List[InspectionResponse])
def get_inspections_by_residence(residence_id: UUID, db: Session = Depends(get_db)):
    logger.info(f"[START] Fetch inspections by residence | residence={residence_id}")

    inspections = db.query(Inspection).join(
        SpaceItem,
        Inspection.space_item_id == SpaceItem.id
    ).join(
        Space,
        Space.id == SpaceItem.space_id
    ).filter(
        Space.residence_id == residence_id
    ).order_by(
        Inspection.created_at.desc()
    ).all()

    logger.info(f"[SUCCESS] Returned {len(inspections)} inspections for residence")
    return inspections


# ==========================================================
# ✍️ SIGN-OFF
# ==========================================================
@router.post("/{inspection_id}/sign-off", response_model=InspectionResponse)
def sign_off_inspection(
    inspection_id: UUID,
    payload: InspectionSignOff,
    db: Session = Depends(get_db)
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


# ==========================================================
# ✅ COMPLETE INSPECTION
# ==========================================================
@router.post("/{inspection_id}/complete", response_model=InspectionResponse)
def complete_inspection(inspection_id: UUID, db: Session = Depends(get_db)):
    logger.info(f"[START] Complete inspection | inspection={inspection_id}")

    try:
        inspection = get_inspection_or_404(db, inspection_id)

        if inspection.status == "completed":
            raise HTTPException(400, "Inspection already completed")

        # 🔷 Completion requires both parties to sign off
        if not (inspection.inspector_signed_off and inspection.tenant_signed_off):
            logger.warning("Attempt to complete inspection without both sign-offs")
            raise HTTPException(400, "Signatures required")

        inspection.status = "completed"
        inspection.updated_at = func.now()

        # 🔥 Completion triggers inspection issue automation
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


# ==========================================================
# ✏️ UPDATE INSPECTION
# ==========================================================
@router.patch("/{inspection_id}", response_model=InspectionResponse)
def update_inspection(
    inspection_id: UUID,
    payload: InspectionUpdate,
    db: Session = Depends(get_db)
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

        # 🔷 Validate the resulting draft state before saving
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


# ==========================================================
# 📥 GET — BY ID
# ==========================================================
@router.get("/{inspection_id}", response_model=InspectionResponse)
def get_inspection(inspection_id: UUID, db: Session = Depends(get_db)):
    logger.info(f"[START] Fetch inspection | inspection={inspection_id}")

    inspection = get_inspection_or_404(db, inspection_id)

    logger.info(f"[SUCCESS] Inspection found: {inspection.id}")
    return inspection
