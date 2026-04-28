from pydantic import BaseModel, ConfigDict
from typing import Optional
from uuid import UUID


class ManagerCreate(BaseModel):
    user_id: UUID
    company_id: Optional[UUID] = None


class ManagerResponse(BaseModel):
    user_id: UUID
    company_id: Optional[UUID]

    model_config = ConfigDict(from_attributes=True)