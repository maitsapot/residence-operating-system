from pydantic import BaseModel, ConfigDict, Field
from typing import Optional
from uuid import UUID

from app.core.enums import SpaceType, Standard, TemplateType


class SpaceCreate(BaseModel):
    residence_id: UUID
    name: str = Field(..., min_length=1)
    space_type: SpaceType

    is_rentable: bool = False
    capacity: int = 0

    floor: Optional[int] = None
    notes: Optional[str] = None

    template_type: TemplateType = "single_room"
    standard: Standard = "nsfas"
    
class SpaceResponse(BaseModel):
    id: UUID
    residence_id: UUID

    name: str
    space_type: SpaceType
    template_type: TemplateType
    standard: Standard

    is_rentable: bool
    capacity: int

    floor: Optional[int]
    notes: Optional[str]

    model_config = ConfigDict(from_attributes=True)
