from pydantic import BaseModel, ConfigDict
from typing import Optional
from uuid import UUID


class LandlordCreate(BaseModel):
    user_id: UUID
    company_id: Optional[UUID] = None


class LandlordResponse(BaseModel):
    user_id: UUID
    company_id: Optional[UUID]

    model_config = ConfigDict(from_attributes=True)