from datetime import date, datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class ServiceCreate(BaseModel):
    name: str
    description: Optional[str] = None
    is_active: bool = True


class ServiceResponse(BaseModel):
    id: UUID
    name: str
    description: Optional[str]
    is_active: bool
    created_at: Optional[datetime]
    updated_at: Optional[datetime]
    archived_at: Optional[datetime]

    model_config = ConfigDict(from_attributes=True)


class ResidenceServiceCreate(BaseModel):
    residence_id: UUID
    service_id: UUID
    provider_type: str = "internal"
    provider_id: Optional[UUID] = None
    status: str = "active"
    started_at: Optional[date] = None
    ended_at: Optional[date] = None


class ResidenceServiceResponse(BaseModel):
    id: UUID
    residence_id: UUID
    service_id: UUID
    provider_type: str
    provider_id: Optional[UUID]
    status: str
    started_at: Optional[date]
    ended_at: Optional[date]
    created_at: Optional[datetime]
    updated_at: Optional[datetime]
    archived_at: Optional[datetime]
    service: Optional[ServiceResponse] = None

    model_config = ConfigDict(from_attributes=True)


class ServicePerformanceSummary(BaseModel):
    residence_service_id: UUID
    service_id: UUID
    residence_id: UUID
    service_name: str
    status: str
    ratings_count: int
    average_rating: Optional[float]
