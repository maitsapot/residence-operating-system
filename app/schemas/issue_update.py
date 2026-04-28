from uuid import UUID
from pydantic import BaseModel
from typing import Optional


class IssueUpdateCreate(BaseModel):
    issue_id: UUID
    updated_by: UUID

    update_type: str

    comment: Optional[str] = None

    old_status: Optional[str] = None
    new_status: Optional[str] = None

    old_assigned_to: Optional[UUID] = None
    new_assigned_to: Optional[UUID] = None


class IssueUpdateResponse(BaseModel):
    id: UUID
    issue_id: UUID
    update_type: str
    comment: Optional[str]

    class Config:
        from_attributes = True