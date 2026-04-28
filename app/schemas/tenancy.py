from pydantic import BaseModel
from uuid import UUID
from datetime import date
from typing import Optional


class TenancyCreate(BaseModel):
    start_date: date
    end_date: Optional[date] = None
    user_id: UUID
    space_id: UUID


class TenancyResponse(BaseModel):
    id: UUID
    start_date: date
    end_date: Optional[date]
    status: str
    user_id: UUID
    space_id: UUID

    class Config:
        from_attributes = True