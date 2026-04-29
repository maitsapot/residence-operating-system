from uuid import UUID
from pydantic import BaseModel
from typing import Optional

from app.core.enums import CategoryName


class CategoryCreate(BaseModel):
    """
    Incoming payload for creating a category
    """
    category_name: CategoryName
    is_trackable: Optional[bool] = False
    is_active: Optional[bool] = True


class CategoryResponse(BaseModel):
    """
    Standard API response model
    """
    id: UUID
    category_name: CategoryName
    is_trackable: bool
    is_active: bool

    class Config:
        from_attributes = True  # SQLAlchemy compatibility
