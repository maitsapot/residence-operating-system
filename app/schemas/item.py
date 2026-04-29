from uuid import UUID
from pydantic import BaseModel
from typing import Optional

from app.core.enums import Condition, ItemStatus


class ItemCreate(BaseModel):
    """
    Payload for creating an item instance
    """

    space_id: UUID
    catalog_id: UUID

    name: Optional[str] = None
    is_trackable: Optional[bool] = None
    qr_code: Optional[str] = None

    condition: Optional[Condition] = "good"
    status: Optional[ItemStatus] = "active"
    notes: Optional[str] = None


class ItemResponse(BaseModel):
    """
    Standard API response
    """

    id: UUID
    space_id: UUID
    catalog_id: UUID
    name: Optional[str]
    is_trackable: Optional[bool]
    qr_code: Optional[str]
    condition: Condition
    status: ItemStatus
    notes: Optional[str]

    class Config:
        from_attributes = True
