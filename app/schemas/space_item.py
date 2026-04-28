from uuid import UUID
from pydantic import BaseModel, Field
from typing import Optional


class SpaceItemCreate(BaseModel):
    """
    Payload for creating expected items in a space.

    This represents the blueprint (not actual physical items).
    """

    space_id: UUID
    catalog_id: UUID

    # Expected quantity of this item in the space
    quantity: Optional[int] = Field(default=1, ge=1)

    # Whether this item is mandatory for the space
    is_required: Optional[bool] = True

    # Baseline condition expectation (initial state)
    condition: Optional[str] = "good"

    # Lifecycle status of expected item
    status: Optional[str] = "active"


class SpaceItemUpdate(BaseModel):
    """
    Update payload for space items.
    Allows controlled updates (no structural changes).
    """

    quantity: Optional[int] = Field(default=None, ge=1)
    is_required: Optional[bool] = None
    condition: Optional[str] = None
    status: Optional[str] = None


class SpaceItemResponse(BaseModel):
    """
    Standard API response model
    """

    id: UUID
    space_id: UUID
    catalog_id: UUID

    quantity: int
    is_required: bool
    condition: str
    status: str

    class Config:
        from_attributes = True