from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from sqlalchemy.sql import func

from app.core.database import get_db
from app.core.logger import get_logger

from app.models.issue import Issue
from app.models.issue_update import IssueUpdate
from app.models.space import Space
from app.models.space_item import SpaceItem
from app.models.common_issue import CommonIssue
from app.models.residence_manager import ResidenceManager

from app.schemas.issue import IssueCreate, IssueResponse
from app.schemas.issue_update import IssueUpdateResponse
from app.core.enums import IssueStatus

logger = get_logger(__name__)

router = APIRouter(prefix="/issues", tags=["Issues"])


# ==========================================================
# 🔧 HELPER — AUDIT LOG
# ==========================================================
def log_issue_update(
    db,
    issue,
    updated_by,
    update_type,
    old_status=None,
    new_status=None,
    old_assigned_to=None,
    new_assigned_to=None,
    comment=None
):
    """
    Centralized audit logging for issue changes
    """

    update = IssueUpdate(
        issue_id=issue.id,
        updated_by=updated_by,
        update_type=update_type,
        comment=comment,
        old_status=old_status,
        new_status=new_status,
        old_assigned_to=old_assigned_to,
        new_assigned_to=new_assigned_to,
        status=new_status or issue.status
    )

    db.add(update)

# ==========================================================
# 🧠 HELPER — STATUS TRANSITION VALIDATION
# ==========================================================
def validate_status_transition(issue, new_status):
    """
    Enforces valid issue lifecycle transitions
    """

    current = issue.status

    # Allow same-state updates (idempotent safety)
    if current == new_status:
        return True

    if current == "open" and new_status == "assigned":
        return True

    if current == "assigned" and new_status == "in_progress":
        return True

    if current == "in_progress" and new_status == "resolved":
        return True

    if current == "resolved" and new_status == "closed":
        return True

    # Allow rejection anytime
    if new_status == "rejected":
        return True

    return False


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

# ==========================================================
# 🚀 CREATE ISSUE
# ==========================================================
@router.post("/", response_model=IssueResponse)
def create_issue(payload: IssueCreate, db: Session = Depends(get_db)):
    """
    Create issue manually.

    - Validates space + optional space_item
    - Auto assigns to residence manager
    - Logs assignment in audit trail
    """

    logger.info(f"Creating issue for space: {payload.space_id}")

    try:
        # 🔷 Validate space
        space = db.query(Space).filter(Space.id == payload.space_id).first()
        if not space:
            logger.warning(f"Space not found: {payload.space_id}")
            raise HTTPException(400, "Space not found")

        # 🔷 Validate common issue
        common_issue = db.query(CommonIssue).filter(
            CommonIssue.id == payload.common_issue_id,
            CommonIssue.is_active == True
        ).first()

        if not common_issue:
            logger.warning(f"Invalid common_issue_id: {payload.common_issue_id}")
            raise HTTPException(400, "Invalid common_issue_id")

        if common_issue.is_other and not payload.description:
            raise HTTPException(400, "Description required for 'Other' issue")

        # 🔷 Validate space_item (optional)
        space_item = None
        if payload.space_item_id:
            space_item = db.query(SpaceItem).filter(
                SpaceItem.id == payload.space_item_id
            ).first()

            if not space_item:
                logger.warning(f"Invalid space_item_id: {payload.space_item_id}")
                raise HTTPException(400, "Invalid space_item_id")

            if space_item.space_id != payload.space_id:
                raise HTTPException(400, "space_item does not belong to space")

            if common_issue.item_id != space_item.item_id:
                raise HTTPException(
                    400,
                    "common_issue does not match the space_item item"
                )

        # 🔷 Resolve primary manager (default assignment)
        manager_id = get_primary_manager_id(db, space.residence_id)

        # 🔷 Create issue
        issue = Issue(**payload.model_dump())

        # 🔥 Default assignment
        issue.assigned_to = manager_id
        issue.status = "assigned" if manager_id else "open"

        db.add(issue)
        db.flush()

        # 🔥 Audit: system assignment
        if manager_id:
            log_issue_update(
                db=db,
                issue=issue,
                updated_by=payload.reported_by,
                update_type="system",
                old_assigned_to=None,
                new_assigned_to=manager_id,
                comment="Auto-assigned to residence manager"
            )

        db.commit()
        db.refresh(issue)

        logger.info(f"Issue created: {issue.id}")

        return issue

    except IntegrityError as e:
        db.rollback()
        logger.error(f"Integrity error creating issue: {e}")
        raise HTTPException(400, "Constraint violation")

    except Exception as e:
        db.rollback()
        logger.error(f"Unexpected error creating issue: {e}")
        raise HTTPException(500, "Internal server error")


# ==========================================================
# 📥 GET — ALL
# ==========================================================
@router.get("/", response_model=list[IssueResponse])
def get_issues(db: Session = Depends(get_db)):
    logger.info("Fetching all issues")

    issues = db.query(Issue).order_by(Issue.created_at.desc()).all()

    logger.info(f"Returned {len(issues)} issues")
    return issues


# ==========================================================
# 📥 GET — BY SPACE
# ==========================================================
@router.get("/space/{space_id}", response_model=list[IssueResponse])
def get_issues_by_space(space_id: str, db: Session = Depends(get_db)):
    logger.info(f"Fetching issues for space: {space_id}")

    return db.query(Issue).filter(Issue.space_id == space_id).all()


# ==========================================================
# 📥 GET — ASSIGNED
# ==========================================================
@router.get("/assigned/{user_id}", response_model=list[IssueResponse])
def get_assigned_issues(user_id: str, db: Session = Depends(get_db)):
    logger.info(f"Fetching assigned issues for user: {user_id}")

    return db.query(Issue).filter(
        Issue.assigned_to == user_id,
        Issue.status.in_(["open", "assigned", "in_progress"])
    ).all()


# ==========================================================
# 📥 GET — SINGLE
# ==========================================================
@router.get("/{issue_id}", response_model=IssueResponse)
def get_issue(issue_id: str, db: Session = Depends(get_db)):
    logger.info(f"Fetching issue: {issue_id}")

    issue = db.query(Issue).filter(Issue.id == issue_id).first()

    if not issue:
        logger.warning(f"Issue not found: {issue_id}")
        raise HTTPException(404, "Issue not found")

    return issue


# ==========================================================
# 🔄 ASSIGN ISSUE
# ==========================================================
@router.patch("/{issue_id}/assign")
def assign_issue(issue_id: str, user_id: str, updated_by: str, db: Session = Depends(get_db)):
    """
    Assign issue to a user + log audit
    """

    logger.info(f"Assigning issue {issue_id} to user {user_id}")

    issue = db.query(Issue).filter(Issue.id == issue_id).first()
    if not issue:
        raise HTTPException(404, "Issue not found")

    old_user = issue.assigned_to

    issue.assigned_to = user_id
    issue.status = "assigned"

    log_issue_update(
        db=db,
        issue=issue,
        updated_by=updated_by,
        update_type="assignment",
        old_assigned_to=old_user,
        new_assigned_to=user_id
    )

    db.commit()
    db.refresh(issue)

    logger.info(f"Issue {issue_id} assigned to {user_id}")

    return issue


# ==========================================================
# 🔄 UPDATE STATUS
# ==========================================================
@router.patch("/{issue_id}/status")
def update_issue_status(
    issue_id: str,
    status: IssueStatus,
    updated_by: str,
    db: Session = Depends(get_db)
):
    """
    Update issue status with basic lifecycle enforcement + audit
    """

    logger.info(f"Updating issue {issue_id} to {status}")

    issue = db.query(Issue).filter(Issue.id == issue_id).first()
    if not issue:
        raise HTTPException(404, "Issue not found")

    old_status = issue.status

    # Validate transition
    if not validate_status_transition(issue, status):
        logger.warning(f"Invalid transition: {old_status} → {status}")
        raise HTTPException(400, "Invalid status transition")

    # Business rules
    if status == "in_progress" and not issue.assigned_to:
        raise HTTPException(400, "Issue must be assigned first")

    if status == "resolved":
        if not issue.assigned_to:
            raise HTTPException(400, "Cannot resolve unassigned issue")
        issue.resolved_at = func.now()

    if status == "closed" and old_status != "resolved":
        raise HTTPException(400, "Issue must be resolved before closing")

    # Apply update
    issue.status = status

    # Audit log
    log_issue_update(
        db=db,
        issue=issue,
        updated_by=updated_by,
        update_type="status_change",
        old_status=old_status,
        new_status=status
    )

    db.commit()
    db.refresh(issue)

    logger.info(f"Issue {issue_id} moved from {old_status} → {status}")

    return issue

# ==========================================================
# 📜 GET ISSUE HISTORY
# ==========================================================
@router.get("/{issue_id}/updates", response_model=list[IssueUpdateResponse])
def get_issue_updates(issue_id: str, db: Session = Depends(get_db)):
    """
    Retrieve full audit trail for an issue
    """

    logger.info(f"Fetching updates for issue: {issue_id}")

    return db.query(IssueUpdate).filter(
        IssueUpdate.issue_id == issue_id
    ).order_by(IssueUpdate.created_at.asc()).all()
