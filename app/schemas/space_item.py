from uuid import UUID
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

from app.core.enums import Condition, SpaceItemStatus


class SpaceItemCreate(BaseModel):
    """
    Payload for creating expected items in a space.

    This represents the blueprint (not actual physical items).
    """

    space_id: UUID
    item_id: UUID

    # Expected quantity of this item in the space
    quantity: Optional[int] = Field(default=1, ge=1)

    # Whether this item is mandatory for the space
    is_required: Optional[bool] = True

    # Baseline condition expectation (initial state)
    condition: Optional[Condition] = "good"

    # Lifecycle status of expected item
    status: Optional[SpaceItemStatus] = "active"


class SpaceItemUpdate(BaseModel):
    """
    Update payload for space items.
    Allows controlled updates (no structural changes).
    """

    quantity: Optional[int] = Field(default=None, ge=1)
    is_required: Optional[bool] = None
    condition: Optional[Condition] = None
    status: Optional[SpaceItemStatus] = None


class SpaceItemResponse(BaseModel):
    """
    Standard API response model
    """

    id: UUID
    space_id: UUID
    item_id: UUID

    quantity: int
    is_required: bool
    condition: Condition
    status: SpaceItemStatus

    class Config:
        from_attributes = True


class SpaceItemInventoryResponse(SpaceItemResponse):
    item_name: str
    qr_code: str
    last_inspection_id: Optional[UUID] = None
    last_inspection_at: Optional[datetime] = None
    last_inspection_image_url: Optional[str] = None
