from uuid import UUID
from pydantic import BaseModel
from typing import Optional
from decimal import Decimal


class IssueCreate(BaseModel):
    """
    Create issue manually or from inspection
    """

    reported_by: UUID
    space_id: UUID

    issue_catalog_id: UUID

    description: Optional[str] = None

    space_item_id: Optional[UUID] = None
    inspection_id: Optional[UUID] = None
    tenancy_id: Optional[UUID] = None

    assigned_to: Optional[UUID] = None

    severity: Optional[str] = "medium"
    urgency: Optional[str] = "medium"

    due_at: Optional[str] = None


class IssueResponse(BaseModel):
    id: UUID
    status: str
    severity: str
    urgency: str
    description: Optional[str]

    class Config:
        from_attributes = True