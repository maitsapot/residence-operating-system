from pydantic import BaseModel
from uuid import UUID
from datetime import date
from typing import Optional

from app.core.enums import TenancyStatus


class TenancyCreate(BaseModel):
    start_date: date
    end_date: Optional[date] = None
    user_id: UUID
    space_id: UUID


class TenancyLifecycleUpdate(BaseModel):
    end_date: Optional[date] = None


class TenancyResponse(BaseModel):
    id: UUID
    start_date: date
    end_date: Optional[date]
    status: TenancyStatus
    user_id: UUID
    space_id: UUID

    class Config:
        from_attributes = True
