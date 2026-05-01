from pydantic import BaseModel, ConfigDict
from typing import Optional
from uuid import UUID


class CaretakerCreate(BaseModel):
    user_id: UUID
    company_id: Optional[UUID] = None


class CaretakerResponse(BaseModel):
    user_id: UUID
    company_id: Optional[UUID]

    model_config = ConfigDict(from_attributes=True)