from pydantic import BaseModel, ConfigDict, Field
from typing import Optional
from uuid import UUID


# ===============================
# CREATE
# ===============================
class TenantCreate(BaseModel):
    user_id: UUID

    is_student: bool = False

    student_number: Optional[str] = None
    institution_id: Optional[UUID] = None

    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    emergency_contact_relationship: Optional[str] = None

    proxy_contact_name: Optional[str] = None
    proxy_contact_phone: Optional[str] = None
    proxy_contact_relationship: Optional[str] = None


# ===============================
# RESPONSE
# ===============================
class TenantResponse(BaseModel):
    user_id: UUID

    is_student: bool
    student_number: Optional[str]
    institution_id: Optional[UUID]

    model_config = ConfigDict(from_attributes=True)