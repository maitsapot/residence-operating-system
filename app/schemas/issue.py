from uuid import UUID
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from decimal import Decimal

from app.core.enums import IssueSeverity, IssueStatus, IssueUrgency


class IssueCreate(BaseModel):
    """
    Create issue manually or from inspection
    """

    reported_by: UUID
    space_id: UUID

    common_issue_id: UUID

    description: Optional[str] = None

    space_item_id: Optional[UUID] = None
    inspection_id: Optional[UUID] = None
    tenancy_id: Optional[UUID] = None

    assigned_to: Optional[UUID] = None

    severity: Optional[IssueSeverity] = "medium"
    urgency: Optional[IssueUrgency] = "medium"

    due_at: Optional[str] = None


class IssueResponse(BaseModel):
    id: UUID
    reported_by: UUID
    assigned_to: Optional[UUID]

    space_id: UUID
    space_item_id: Optional[UUID]
    inspection_id: Optional[UUID]
    tenancy_id: Optional[UUID]
    common_issue_id: UUID

    status: IssueStatus
    severity: IssueSeverity
    urgency: IssueUrgency
    description: Optional[str]

    due_at: Optional[datetime]
    resolved_at: Optional[datetime]
    created_at: Optional[datetime]
    updated_at: Optional[datetime]
    archived_at: Optional[datetime] = None

    estimated_cost: Optional[Decimal]
    actual_cost: Optional[Decimal]

    class Config:
        from_attributes = True
