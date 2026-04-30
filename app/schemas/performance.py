from datetime import datetime
from decimal import Decimal
from typing import Any
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class PerformanceRatingCreate(BaseModel):
    target_type: str
    target_id: UUID
    rated_by: Optional[UUID] = None
    rating: int = Field(..., ge=1, le=5)
    category: str = "overall"
    comment: Optional[str] = None
    media_attachment_id: Optional[UUID] = None


class PerformanceRatingResponse(BaseModel):
    id: UUID
    target_type: str
    target_id: UUID
    rated_by: Optional[UUID]
    rating: int
    category: str
    comment: Optional[str]
    media_attachment_id: Optional[UUID]
    created_at: Optional[datetime]
    updated_at: Optional[datetime]
    archived_at: Optional[datetime]

    model_config = ConfigDict(from_attributes=True)


class PerformanceRatingSummary(BaseModel):
    target_type: str
    target_id: UUID
    ratings_count: int
    average_rating: Optional[float]
    category: Optional[str] = None


class PerformanceCheckResponse(BaseModel):
    id: UUID
    scope_type: str
    scope_id: UUID
    score: Decimal
    status: str
    calculated_at: Optional[datetime]
    summary: Optional[str]
    extra_metadata: dict[str, Any]
    created_at: Optional[datetime]
    updated_at: Optional[datetime]

    model_config = ConfigDict(from_attributes=True)


class PerformanceFindingResponse(BaseModel):
    id: UUID
    check_id: UUID
    finding_type: str
    severity: str
    message: str
    related_entity_type: Optional[str]
    related_entity_id: Optional[UUID]
    created_issue_id: Optional[UUID]
    created_at: Optional[datetime]
    updated_at: Optional[datetime]

    model_config = ConfigDict(from_attributes=True)


class PerformanceFindingIssueCreate(BaseModel):
    reported_by: UUID
    common_issue_id: Optional[UUID] = None
    space_id: Optional[UUID] = None
    description: Optional[str] = None
