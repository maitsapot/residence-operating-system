from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from sqlalchemy.sql import func

from app.core.database import get_db
from app.core.logger import get_logger

from app.models.inspection import Inspection
from app.models.space_item import SpaceItem
from app.models.space import Space
from app.models.residence import Residence
from app.models.issue import Issue
from app.models.issue_update import IssueUpdate

from app.schemas.inspection import InspectionCreate, InspectionResponse

logger = get_logger(__name__)

router = APIRouter(prefix="/inspections", tags=["Inspections"])

from app.models.common_issue import CommonIssue


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

    # 🔷 Resolve manager (default assignment)
    manager_id = None
    if space.residence_id:
        residence = db.query(Residence).filter(
            Residence.id == space.residence_id
        ).first()

        if residence:
            manager_id = residence.manager_id

    # 🔷 Create issue
    
    # 🔥 NEW: resolve intelligent issue defaults
    issue_data = resolve_common_issue(db, space_item)
    issue = Issue(
        reported_by=inspection.inspected_by,
        space_id=space.id,
        space_item_id=inspection.space_item_id,
        inspection_id=inspection.id,
        tenancy_id=inspection.tenancy_id,

        description=issue_data["description"],

        issue_catalog_id=issue_data["issue_catalog_id"],
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
    - issue_catalog_id
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
            "issue_catalog_id": common_issue.id,
            "severity": common_issue.default_severity,
            "urgency": common_issue.default_urgency,
            "description": common_issue.issue_name
        }

    # 🔷 fallback (existing behavior preserved)
    return {
        "issue_catalog_id": None,
        "severity": "medium",
        "urgency": "medium",
        "description": "Auto-created from inspection"
    }


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

        # 🔷 Check tenancy rule
        if payload.inspection_type in ["checkin", "checkout"] and not payload.tenancy_id:
            logger.warning("Missing tenancy_id for checkin/checkout")
            raise HTTPException(400, "tenancy_id required")

        # 🔷 Completion rule (signature enforcement)
        if payload.status == "completed":
            if not (payload.inspector_signed_off and payload.tenant_signed_off):
                logger.warning("Attempt to complete inspection without signatures")
                raise HTTPException(400, "Signatures required")

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