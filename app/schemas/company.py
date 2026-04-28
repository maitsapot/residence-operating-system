from pydantic import BaseModel, ConfigDict
from typing import Optional
from uuid import UUID

from app.schemas.location import LocationCreate, LocationResponse


# ===============================
# CREATE
# ===============================
class CompanyCreate(BaseModel):
    name: str
    registration_number: Optional[str] = None

    # 🔥 nested location
    location: LocationCreate


# ===============================
# RESPONSE
# ===============================
class CompanyResponse(BaseModel):
    id: UUID
    name: str
    registration_number: Optional[str]
    is_active: bool

    location: LocationResponse

    model_config = ConfigDict(from_attributes=True)