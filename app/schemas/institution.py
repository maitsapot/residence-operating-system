from pydantic import BaseModel, ConfigDict, Field
from typing import Optional
from uuid import UUID

from app.schemas.location import LocationCreate, LocationResponse


# ===============================
# CREATE
# ===============================
class InstitutionCreate(BaseModel):
    name: str = Field(..., min_length=2)
    code: Optional[str] = None

    institution_type: str  # university, tvet, college, other
    parent_id: Optional[UUID] = None

    location: LocationCreate  # 🔥 REQUIRED


# ===============================
# RESPONSE
# ===============================
class InstitutionResponse(BaseModel):
    id: UUID

    name: str
    code: Optional[str]

    institution_type: str
    parent_id: Optional[UUID]

    is_active: bool

    location: LocationResponse

    model_config = ConfigDict(from_attributes=True)