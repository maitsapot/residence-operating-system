from uuid import UUID
from pydantic import BaseModel
from typing import Optional


class InspectionCreate(BaseModel):
    """
    Create inspection snapshot
    """

    space_item_id: UUID
    inspected_by: UUID

    condition: str
    notes: Optional[str] = None
    image_url: Optional[str] = None

    inspection_type: Optional[str] = "routine"
    tenancy_id: Optional[UUID] = None

    inspector_signed_off: Optional[bool] = False
    tenant_signed_off: Optional[bool] = False

    status: Optional[str] = "draft"

    inspector_signature: Optional[str] = None
    tenant_signature: Optional[str] = None


class InspectionResponse(BaseModel):
    id: UUID
    space_item_id: UUID
    inspected_by: UUID

    condition: str
    notes: Optional[str]
    image_url: Optional[str]

    inspection_type: str
    tenancy_id: Optional[UUID]

    inspector_signed_off: bool
    tenant_signed_off: bool
    status: str

    class Config:
        from_attributes = True