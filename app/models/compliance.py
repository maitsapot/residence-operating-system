import uuid

from sqlalchemy import Boolean, CheckConstraint, Column, Date, ForeignKey, Index, Numeric, Text, UniqueConstraint
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from sqlalchemy.types import TIMESTAMP

from app.core.database import Base


class ComplianceRule(Base):
    __tablename__ = "compliance_rules"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    standard = Column(Text, nullable=False, default="nsfas")
    scope_type = Column(Text, nullable=False)
    rule_code = Column(Text, nullable=False)
    rule_name = Column(Text, nullable=False)
    description = Column(Text, nullable=True)
    severity = Column(Text, nullable=False, default="medium")
    is_active = Column(Boolean, nullable=False, default=True)
    effective_from = Column(Date, nullable=True)
    effective_to = Column(Date, nullable=True)

    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now())

    requirements = relationship("ComplianceRuleRequirement", back_populates="rule")
    findings = relationship("ComplianceFinding", back_populates="rule")

    __table_args__ = (
        CheckConstraint(
            "scope_type IN ('room','residence','documentation','overall')",
            name="compliance_rules_scope_type_check",
        ),
        CheckConstraint(
            "severity IN ('low','medium','high','critical')",
            name="compliance_rules_severity_check",
        ),
        UniqueConstraint("standard", "scope_type", "rule_code", name="uq_compliance_rule_code"),
        Index("idx_compliance_rules_scope", "standard", "scope_type", "is_active"),
    )


class ComplianceRuleRequirement(Base):
    __tablename__ = "compliance_rule_requirements"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    rule_id = Column(UUID(as_uuid=True), ForeignKey("compliance_rules.id", ondelete="CASCADE"), nullable=False)
    requirement_type = Column(Text, nullable=False)
    item_id = Column(UUID(as_uuid=True), ForeignKey("items.id", ondelete="SET NULL"), nullable=True)
    space_type = Column(Text, nullable=True)
    document_type = Column(Text, nullable=True)
    minimum_quantity = Column(Numeric(12, 2), nullable=True)
    ratio_numerator = Column(Numeric(12, 2), nullable=True)
    ratio_denominator = Column(Numeric(12, 2), nullable=True)
    extra_metadata = Column("metadata", JSONB, nullable=False, default=dict)

    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now())

    rule = relationship("ComplianceRule", back_populates="requirements")

    __table_args__ = (
        CheckConstraint(
            "requirement_type IN ("
            "'required_item','required_space','ratio','document','assignment','capacity','custom'"
            ")",
            name="compliance_rule_requirements_type_check",
        ),
        Index("idx_compliance_rule_requirements_rule", "rule_id"),
        Index("idx_compliance_rule_requirements_item", "item_id"),
    )


class ComplianceCheck(Base):
    __tablename__ = "compliance_checks"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    scope_type = Column(Text, nullable=False)
    scope_id = Column(UUID(as_uuid=True), nullable=False)
    standard = Column(Text, nullable=False, default="nsfas")
    score = Column(Numeric(5, 2), nullable=False)
    status = Column(Text, nullable=False)
    checked_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    checked_by = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    summary = Column(Text, nullable=True)
    extra_metadata = Column("metadata", JSONB, nullable=False, default=dict)

    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now())

    findings = relationship("ComplianceFinding", back_populates="check")

    __table_args__ = (
        CheckConstraint(
            "scope_type IN ('room','residence','documentation','overall')",
            name="compliance_checks_scope_type_check",
        ),
        CheckConstraint(
            "status IN ('pass','warning','fail','not_applicable','not_checked')",
            name="compliance_checks_status_check",
        ),
        CheckConstraint("score >= 0 AND score <= 100", name="compliance_checks_score_check"),
        Index("idx_compliance_checks_scope", "scope_type", "scope_id"),
        Index("idx_compliance_checks_standard", "standard"),
        Index("idx_compliance_checks_checked_at", "checked_at"),
    )


class ComplianceFinding(Base):
    __tablename__ = "compliance_findings"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    check_id = Column(UUID(as_uuid=True), ForeignKey("compliance_checks.id", ondelete="CASCADE"), nullable=False)
    rule_id = Column(UUID(as_uuid=True), ForeignKey("compliance_rules.id", ondelete="SET NULL"), nullable=True)
    finding_type = Column(Text, nullable=False)
    severity = Column(Text, nullable=False, default="medium")
    status = Column(Text, nullable=False, default="open")
    message = Column(Text, nullable=False)
    related_entity_type = Column(Text, nullable=True)
    related_entity_id = Column(UUID(as_uuid=True), nullable=True)
    expected_value = Column(Text, nullable=True)
    actual_value = Column(Text, nullable=True)
    created_issue_id = Column(UUID(as_uuid=True), ForeignKey("issues.id", ondelete="SET NULL"), nullable=True)

    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now())

    check = relationship("ComplianceCheck", back_populates="findings")
    rule = relationship("ComplianceRule", back_populates="findings")

    __table_args__ = (
        CheckConstraint(
            "finding_type IN ("
            "'missing_required_item','missing_required_space','quantity_shortfall',"
            "'ratio_failed','missing_document','expired_document','missing_assignment',"
            "'capacity_issue','custom'"
            ")",
            name="compliance_findings_type_check",
        ),
        CheckConstraint(
            "severity IN ('low','medium','high','critical')",
            name="compliance_findings_severity_check",
        ),
        CheckConstraint(
            "status IN ('open','resolved','waived')",
            name="compliance_findings_status_check",
        ),
        Index("idx_compliance_findings_check", "check_id"),
        Index("idx_compliance_findings_rule", "rule_id"),
        Index("idx_compliance_findings_status", "status"),
        Index("idx_compliance_findings_related", "related_entity_type", "related_entity_id"),
    )


class ComplianceDocument(Base):
    __tablename__ = "compliance_documents"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    residence_id = Column(UUID(as_uuid=True), ForeignKey("residences.id", ondelete="CASCADE"), nullable=False)
    document_type = Column(Text, nullable=False)
    document_name = Column(Text, nullable=False)
    status = Column(Text, nullable=False, default="submitted")
    issued_at = Column(Date, nullable=True)
    expires_at = Column(Date, nullable=True)
    verified_by = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    verified_at = Column(TIMESTAMP(timezone=True), nullable=True)
    media_attachment_id = Column(
        UUID(as_uuid=True),
        ForeignKey("media_attachments.id", ondelete="SET NULL"),
        nullable=True,
    )
    notes = Column(Text, nullable=True)

    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now())
    archived_at = Column(TIMESTAMP(timezone=True), nullable=True)

    residence = relationship("Residence", backref="compliance_documents")
    media_attachment = relationship("MediaAttachment")

    __table_args__ = (
        CheckConstraint(
            "status IN ('missing','submitted','approved','rejected','expired')",
            name="compliance_documents_status_check",
        ),
        Index("idx_compliance_documents_residence", "residence_id"),
        Index("idx_compliance_documents_type", "document_type"),
        Index("idx_compliance_documents_status", "status"),
        Index("idx_compliance_documents_expires_at", "expires_at"),
        Index("idx_compliance_documents_archived_at", "archived_at"),
    )
