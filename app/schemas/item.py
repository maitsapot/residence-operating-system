from uuid import UUID
from pydantic import BaseModel, Field
from typing import Optional


class ItemCreate(BaseModel):
    category_id: UUID
    name: str = Field(..., min_length=2)

    is_trackable: Optional[bool] = True
    default_quantity: Optional[int] = 1
    is_active: Optional[bool] = True


class ItemResponse(BaseModel):
    id: UUID
    category_id: UUID
    name: str
    is_trackable: bool
    default_quantity: int
    is_active: bool

    class Config:
        from_attributes = True
