from uuid import UUID
from pydantic import BaseModel
from typing import Optional


class CategoryCreate(BaseModel):
    """
    Incoming payload for creating a category
    """
    category_name: str
    is_trackable: Optional[bool] = False
    is_active: Optional[bool] = True


class CategoryResponse(BaseModel):
    """
    Standard API response model
    """
    id: UUID
    category_name: str
    is_trackable: bool
    is_active: bool

    class Config:
        from_attributes = True  # SQLAlchemy compatibility