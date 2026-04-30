from datetime import date, datetime
from decimal import Decimal
from typing import Any, Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class ComplianceRuleResponse(BaseModel):
    id: UUID
    standard: str
    scope_type: str
    rule_code: str
    rule_name: str
    description: Optional[str]
    severity: str
    is_active: bool
    effective_from: Optional[date]
    effective_to: Optional[date]
    created_at: Optional[datetime]
    updated_at: Optional[datetime]

    model_config = ConfigDict(from_attributes=True)


class ComplianceRuleRequirementResponse(BaseModel):
    id: UUID
    rule_id: UUID
    requirement_type: str
    item_id: Optional[UUID]
    space_type: Optional[str]
    document_type: Optional[str]
    minimum_quantity: Optional[Decimal]
    ratio_numerator: Optional[Decimal]
    ratio_denominator: Optional[Decimal]
    extra_metadata: dict[str, Any]
    created_at: Optional[datetime]
    updated_at: Optional[datetime]

    model_config = ConfigDict(from_attributes=True)


class ComplianceCheckResponse(BaseModel):
    id: UUID
    scope_type: str
    scope_id: UUID
    standard: str
    score: Decimal
    status: str
    checked_at: Optional[datetime]
    checked_by: Optional[UUID]
    summary: Optional[str]
    extra_metadata: dict[str, Any]
    created_at: Optional[datetime]
    updated_at: Optional[datetime]

    model_config = ConfigDict(from_attributes=True)


class ComplianceFindingResponse(BaseModel):
    id: UUID
    check_id: UUID
    rule_id: Optional[UUID]
    finding_type: str
    severity: str
    status: str
    message: str
    related_entity_type: Optional[str]
    related_entity_id: Optional[UUID]
    expected_value: Optional[str]
    actual_value: Optional[str]
    created_issue_id: Optional[UUID]
    created_at: Optional[datetime]
    updated_at: Optional[datetime]

    model_config = ConfigDict(from_attributes=True)


class ComplianceDocumentCreate(BaseModel):
    residence_id: UUID
    document_type: str
    document_name: str
    status: str = "submitted"
    issued_at: Optional[date] = None
    expires_at: Optional[date] = None
    media_attachment_id: Optional[UUID] = None
    notes: Optional[str] = None


class ComplianceDocumentStatusUpdate(BaseModel):
    status: str
    verified_by: Optional[UUID] = None
    notes: Optional[str] = None


class ComplianceDocumentMediaAttach(BaseModel):
    media_attachment_id: UUID


class ComplianceDocumentResponse(BaseModel):
    id: UUID
    residence_id: UUID
    document_type: str
    document_name: str
    status: str
    issued_at: Optional[date]
    expires_at: Optional[date]
    verified_by: Optional[UUID]
    verified_at: Optional[datetime]
    media_attachment_id: Optional[UUID]
    notes: Optional[str]
    created_at: Optional[datetime]
    updated_at: Optional[datetime]
    archived_at: Optional[datetime]

    model_config = ConfigDict(from_attributes=True)
