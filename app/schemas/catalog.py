from uuid import UUID
from pydantic import BaseModel, Field
from typing import Optional


class CatalogCreate(BaseModel):
    category_id: UUID
    name: str = Field(..., min_length=2)

    is_trackable: Optional[bool] = True
    default_quantity: Optional[int] = 1
    is_active: Optional[bool] = True

    allowed_space_type: Optional[str] = None


class CatalogResponse(BaseModel):
    id: UUID
    category_id: UUID
    name: str
    is_trackable: bool
    default_quantity: int
    is_active: bool
    allowed_space_type: Optional[str]

    class Config:
        from_attributes = True