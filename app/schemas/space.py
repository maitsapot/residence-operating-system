from pydantic import BaseModel, ConfigDict, Field
from typing import Optional
from uuid import UUID


class SpaceCreate(BaseModel):
    residence_id: UUID
    name: str = Field(..., min_length=1)
    space_type: str

    is_rentable: bool = False
    capacity: int = 0

    floor: Optional[int] = None
    notes: Optional[str] = None



class SpaceCreate(BaseModel):
    # existing fields...

    template_type: Optional[str] = None
    standard: Optional[str] = "custom"
    
class SpaceResponse(BaseModel):
    id: UUID
    residence_id: UUID

    name: str
    space_type: str

    is_rentable: bool
    capacity: int

    floor: Optional[int]
    notes: Optional[str]

    model_config = ConfigDict(from_attributes=True)