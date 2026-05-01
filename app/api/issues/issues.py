from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.enums import IssueStatus
from app.api.openapi import COMMON_ERROR_RESPONSES
from app.schemas.issue import IssueCreate, IssueResponse
from app.schemas.issue_update import IssueUpdateResponse
from app.services import issue as issue_service
from app.services.issue import validate_status_transition

router = APIRouter(prefix="/issues", tags=["Issues"])

ISSUE_EXAMPLE = {
    "id": "11111111-1111-1111-1111-111111111111",
    "reported_by": "22222222-2222-2222-2222-222222222222",
    "assigned_to": "33333333-3333-3333-3333-333333333333",
    "space_id": "44444444-4444-4444-4444-444444444444",
    "space_item_id": "55555555-5555-5555-5555-555555555555",
    "inspection_id": None,
    "tenancy_id": None,
    "common_issue_id": "66666666-6666-6666-6666-666666666666",
    "status": "assigned",
    "severity": "medium",
    "urgency": "medium",
    "description": "Desk has condition/status issue.",
    "due_at": None,
    "resolved_at": None,
    "created_at": "2026-04-29T00:00:00Z",
    "updated_at": "2026-04-29T00:00:00Z",
    "estimated_cost": None,
    "actual_cost": None,
}


@router.post(
    "/",
    response_model=IssueResponse,
    summary="Create issue",
    description=(
        "Creates a maintenance issue for a space. The API validates the space, "
        "common issue, and optional space item, then auto-assigns the issue to "
        "the residence manager when one is available."
    ),
    responses={
        200: {
            "description": "Issue created.",
            "content": {"application/json": {"example": ISSUE_EXAMPLE}},
        },
        **COMMON_ERROR_RESPONSES,
    },
)
def create_issue(payload: IssueCreate, db: Session = Depends(get_db)):
    return issue_service.create_issue(db, payload)


@router.get(
    "/",
    response_model=list[IssueResponse],
    summary="List issues",
    description="Returns all issues ordered from newest to oldest.",
    responses={
        200: {
            "description": "Issues returned.",
            "content": {"application/json": {"example": [ISSUE_EXAMPLE]}},
        },
        **COMMON_ERROR_RESPONSES,
    },
)
def get_issues(
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    status: IssueStatus | None = None,
    assigned_to: UUID | None = None,
    reported_by: UUID | None = None,
    space_id: UUID | None = None,
    include_archived: bool = False,
    db: Session = Depends(get_db),
):
    return issue_service.get_issues(
        db,
        offset=offset,
        limit=limit,
        status=status,
        assigned_to=assigned_to,
        reported_by=reported_by,
        space_id=space_id,
        include_archived=include_archived,
    )


@router.get(
    "/space/{space_id}",
    response_model=list[IssueResponse],
    summary="List issues by space",
    description="Returns issues linked to a specific space.",
    responses={
        200: {
            "description": "Space issues returned.",
            "content": {"application/json": {"example": [ISSUE_EXAMPLE]}},
        },
        **COMMON_ERROR_RESPONSES,
    },
)
def get_issues_by_space(
    space_id: str,
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    status: IssueStatus | None = None,
    include_archived: bool = False,
    db: Session = Depends(get_db),
):
    return issue_service.get_issues_by_space(
        db,
        space_id,
        offset=offset,
        limit=limit,
        status=status,
        include_archived=include_archived,
    )


@router.get(
    "/assigned/{user_id}",
    response_model=list[IssueResponse],
    summary="List assigned issues",
    description="Returns open, assigned, or in-progress issues assigned to a user.",
    responses={
        200: {
            "description": "Assigned issues returned.",
            "content": {"application/json": {"example": [ISSUE_EXAMPLE]}},
        },
        **COMMON_ERROR_RESPONSES,
    },
)
def get_assigned_issues(
    user_id: str,
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    include_archived: bool = False,
    db: Session = Depends(get_db),
):
    return issue_service.get_assigned_issues(
        db,
        user_id,
        offset=offset,
        limit=limit,
        include_archived=include_archived,
    )


@router.get(
    "/{issue_id}",
    response_model=IssueResponse,
    summary="Get issue",
    description="Returns a single issue by ID.",
    responses={
        200: {
            "description": "Issue returned.",
            "content": {"application/json": {"example": ISSUE_EXAMPLE}},
        },
        **COMMON_ERROR_RESPONSES,
    },
)
def get_issue(issue_id: str, db: Session = Depends(get_db)):
    return issue_service.get_issue(db, issue_id)


@router.patch(
    "/{issue_id}/assign",
    summary="Assign issue",
    description="Assigns an issue to a user and writes an audit entry.",
    responses={
        200: {
            "description": "Issue assignment updated.",
            "content": {"application/json": {"example": ISSUE_EXAMPLE}},
        },
        **COMMON_ERROR_RESPONSES,
    },
)
def assign_issue(issue_id: str, user_id: str, updated_by: str, db: Session = Depends(get_db)):
    return issue_service.assign_issue(db, issue_id, user_id, updated_by)


@router.delete(
    "/{issue_id}",
    response_model=IssueResponse,
    summary="Archive issue",
    description="Soft-deletes an issue by setting archived_at. Archived issues are hidden from list endpoints by default.",
    responses=COMMON_ERROR_RESPONSES,
)
def archive_issue(issue_id: str, db: Session = Depends(get_db)):
    return issue_service.archive_issue(db, issue_id)


@router.post(
    "/{issue_id}/restore",
    response_model=IssueResponse,
    summary="Restore issue",
    description="Restores a previously archived issue by clearing archived_at.",
    responses=COMMON_ERROR_RESPONSES,
)
def restore_issue(issue_id: str, db: Session = Depends(get_db)):
    return issue_service.restore_issue(db, issue_id)


@router.patch(
    "/{issue_id}/status",
    summary="Update issue status",
    description=(
        "Moves an issue through the allowed lifecycle and writes an audit entry. "
        "Valid forward transitions are open to assigned, assigned to in_progress, "
        "in_progress to resolved, and resolved to closed. Rejection is allowed "
        "from any state."
    ),
    responses={
        200: {
            "description": "Issue status updated.",
            "content": {"application/json": {"example": ISSUE_EXAMPLE}},
        },
        **COMMON_ERROR_RESPONSES,
    },
)
def update_issue_status(
    issue_id: str,
    status: IssueStatus,
    updated_by: str,
    db: Session = Depends(get_db)
):
    return issue_service.update_issue_status(db, issue_id, status, updated_by)


@router.get(
    "/{issue_id}/updates",
    response_model=list[IssueUpdateResponse],
    summary="List issue updates",
    description="Returns the audit trail for an issue in chronological order.",
    responses={
        200: {
            "description": "Issue audit entries returned.",
            "content": {
                "application/json": {
                    "example": [
                        {
                            "id": "77777777-7777-7777-7777-777777777777",
                            "issue_id": "11111111-1111-1111-1111-111111111111",
                            "update_type": "status_change",
                            "comment": None,
                        }
                    ]
                }
            },
        },
        **COMMON_ERROR_RESPONSES,
    },
)
def get_issue_updates(issue_id: str, db: Session = Depends(get_db)):
    return issue_service.get_issue_updates(db, issue_id)
