from pydantic import BaseModel, ConfigDict, Field, computed_field
from typing import Optional
from uuid import UUID

from app.core.enums import InstitutionType
from app.schemas.location import LocationCreate, LocationResponse


# ===============================
# CREATE
# ===============================
class InstitutionCreate(BaseModel):
    name: str = Field(..., min_length=2)
    code: Optional[str] = None

    institution_type: InstitutionType
    parent_id: Optional[UUID] = None

    location: LocationCreate  # 🔥 REQUIRED


# ===============================
# RESPONSE
# ===============================
class InstitutionResponse(BaseModel):
    id: UUID

    name: str
    code: Optional[str]

    institution_type: InstitutionType
    parent_id: Optional[UUID]

    @computed_field
    @property
    def is_satellite(self) -> bool:
        return self.parent_id is not None

    is_active: bool

    location: LocationResponse

    model_config = ConfigDict(from_attributes=True)
