from uuid import UUID
from pydantic import BaseModel, Field
from typing import Optional

from app.core.enums import SpaceType, Standard, TemplateType


class SpaceItemTemplateCreate(BaseModel):
    template_type: TemplateType = Field(default="single_room", min_length=1)
    standard: Standard = Field(default="nsfas", min_length=1)
    space_type: SpaceType
    catalog_id: UUID
    default_quantity: int = Field(default=1, ge=1)
    is_required: bool = True


class SpaceItemTemplateResponse(BaseModel):
    id: UUID
    template_type: TemplateType
    standard: Standard
    space_type: SpaceType
    catalog_id: UUID
    default_quantity: int
    is_required: bool

    class Config:
        from_attributes = True
