from uuid import UUID
from pydantic import BaseModel
from typing import Optional


class CommonIssueCreate(BaseModel):
    catalog_id: UUID
    issue_name: str

    default_severity: Optional[str] = "medium"
    default_urgency: Optional[str] = "medium"

    is_other: Optional[bool] = False
    is_active: Optional[bool] = True


class CommonIssueResponse(BaseModel):
    id: UUID
    catalog_id: UUID
    issue_name: str
    default_severity: str
    default_urgency: str
    is_other: bool

    class Config:
        from_attributes = True