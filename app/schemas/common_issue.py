from uuid import UUID
from pydantic import BaseModel
from typing import Optional

from app.core.enums import IssueSeverity, IssueUrgency


class CommonIssueCreate(BaseModel):
    catalog_id: UUID
    issue_name: str

    default_severity: Optional[IssueSeverity] = "medium"
    default_urgency: Optional[IssueUrgency] = "medium"

    is_other: Optional[bool] = False
    is_active: Optional[bool] = True


class CommonIssueResponse(BaseModel):
    id: UUID
    catalog_id: UUID
    issue_name: str
    default_severity: IssueSeverity
    default_urgency: IssueUrgency
    is_other: bool

    class Config:
        from_attributes = True
