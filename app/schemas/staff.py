from pydantic import BaseModel, ConfigDict, Field
from typing import Optional
from uuid import UUID


# ===============================
# CREATE
# ===============================
class StaffCreate(BaseModel):
    user_id: UUID
    role: str = Field(..., min_length=2)
    company_id: Optional[UUID] = None


# ===============================
# RESPONSE
# ===============================
class StaffResponse(BaseModel):
    id: UUID
    user_id: UUID
    role: str
    company_id: Optional[UUID]

    model_config = ConfigDict(from_attributes=True)