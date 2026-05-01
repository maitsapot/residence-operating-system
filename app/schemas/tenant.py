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

    emergency_contact_user_id: Optional[UUID] = None
    emergency_contact_relationship: Optional[str] = None

    guardian_user_id: Optional[UUID] = None
    guardian_relationship: Optional[str] = None

    authorized_proxy_user_id: Optional[UUID] = None
    authorized_proxy_relationship: Optional[str] = None


# ===============================
# RESPONSE
# ===============================
class TenantResponse(BaseModel):
    user_id: UUID

    is_student: bool
    student_number: Optional[str]
    institution_id: Optional[UUID]
    emergency_contact_user_id: Optional[UUID] = None
    emergency_contact_relationship: Optional[str] = None
    guardian_user_id: Optional[UUID] = None
    guardian_relationship: Optional[str] = None
    authorized_proxy_user_id: Optional[UUID] = None
    authorized_proxy_relationship: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)
