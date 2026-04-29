from uuid import UUID
from pydantic import BaseModel
from typing import Optional

from app.core.enums import Condition, InspectionStatus, InspectionType


class InspectionCreate(BaseModel):
    """
    Create inspection snapshot
    """

    space_item_id: UUID
    inspected_by: UUID

    condition: Condition
    notes: Optional[str] = None
    image_url: Optional[str] = None

    inspection_type: Optional[InspectionType] = "routine"
    tenancy_id: Optional[UUID] = None

    inspector_signed_off: Optional[bool] = False
    tenant_signed_off: Optional[bool] = False

    status: Optional[InspectionStatus] = "draft"

    inspector_signature: Optional[str] = None
    tenant_signature: Optional[str] = None


class InspectionUpdate(BaseModel):
    """
    Partial update for draft inspection details.
    """

    condition: Optional[Condition] = None
    notes: Optional[str] = None
    image_url: Optional[str] = None
    inspection_type: Optional[InspectionType] = None
    tenancy_id: Optional[UUID] = None
    inspector_signature: Optional[str] = None
    tenant_signature: Optional[str] = None
    inspector_signed_off: Optional[bool] = None
    tenant_signed_off: Optional[bool] = None


class InspectionSignOff(BaseModel):
    """
    Captures inspector or tenant sign-off for an inspection.
    """

    role: str
    signature: str


class InspectionResponse(BaseModel):
    id: UUID
    space_item_id: UUID
    inspected_by: UUID

    condition: Condition
    notes: Optional[str]
    image_url: Optional[str]

    inspection_type: InspectionType
    tenancy_id: Optional[UUID]

    inspector_signed_off: bool
    tenant_signed_off: bool
    status: InspectionStatus
    inspector_signature: Optional[str] = None
    tenant_signature: Optional[str] = None

    class Config:
        from_attributes = True
