from pydantic import BaseModel, ConfigDict, Field
from typing import Optional, List
from uuid import UUID
from datetime import datetime


from app.schemas.location import LocationCreate, LocationResponse


# ===============================
# CREATE
# ===============================
class ResidenceCreate(BaseModel):
    name: str = Field(..., min_length=1)

    # 🔥 REQUIRED (at least 1 landlord)
    landlord_ids: List[UUID]

    # OPTIONAL
    company_id: Optional[UUID] = None

    # nested location
    location: LocationCreate

    # OPTIONAL role assignments
    caretaker_ids: Optional[List[UUID]] = []
    manager_ids: Optional[List[UUID]] = []
    primary_manager_id: Optional[UUID] = None
    staff_ids: Optional[List[UUID]] = []

    total_rooms: int = 0
    total_capacity: int = 0

    model_config = ConfigDict(extra="forbid")


# ===============================
# RESPONSE
# ===============================
class ResidenceResponse(BaseModel):
    id: UUID
    name: str

    company_id: Optional[UUID]

    total_rooms: int
    total_capacity: int
    is_active: bool
    archived_at: Optional[datetime] = None

    # 🔥 role outputs
    landlord_ids: Optional[List[UUID]] = []
    caretaker_ids:Optional[List[UUID]] = []
    manager_ids: Optional[List[UUID]] = []
    primary_manager_id: Optional[UUID] = None
    staff_ids: Optional[List[UUID]] = []

    location: LocationResponse

    model_config = ConfigDict(from_attributes=True)
