import uuid

from sqlalchemy import CheckConstraint, Column, ForeignKey, Index, Integer, Numeric, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from sqlalchemy.types import TIMESTAMP

from app.core.database import Base


class PerformanceRating(Base):
    __tablename__ = "performance_ratings"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    target_type = Column(Text, nullable=False)
    target_id = Column(UUID(as_uuid=True), nullable=False)
    rated_by = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    rating = Column(Integer, nullable=False)
    category = Column(Text, nullable=False, default="overall")
    comment = Column(Text, nullable=True)
    media_attachment_id = Column(
        UUID(as_uuid=True),
        ForeignKey("media_attachments.id", ondelete="SET NULL"),
        nullable=True,
    )

    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now())
    archived_at = Column(TIMESTAMP(timezone=True), nullable=True)

    __table_args__ = (
        CheckConstraint(
            "target_type IN ('space_item','space','service','residence','contractor','vendor','issue')",
            name="performance_ratings_target_type_check",
        ),
        CheckConstraint(
            "category IN ("
            "'overall','cleanliness','comfort','safety','maintenance',"
            "'availability','responsiveness','quality','condition'"
            ")",
            name="performance_ratings_category_check",
        ),
        CheckConstraint("rating >= 1 AND rating <= 5", name="performance_ratings_rating_check"),
        Index("idx_performance_ratings_target", "target_type", "target_id"),
        Index("idx_performance_ratings_rated_by", "rated_by"),
        Index("idx_performance_ratings_category", "category"),
        Index("idx_performance_ratings_archived_at", "archived_at"),
    )


class PerformanceCheck(Base):
    __tablename__ = "performance_checks"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    scope_type = Column(Text, nullable=False)
    scope_id = Column(UUID(as_uuid=True), nullable=False)
    score = Column(Numeric(5, 2), nullable=False)
    status = Column(Text, nullable=False)
    calculated_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    summary = Column(Text, nullable=True)
    extra_metadata = Column("metadata", JSONB, nullable=False, default=dict)

    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now())

    findings = relationship("PerformanceFinding", back_populates="check")

    __table_args__ = (
        CheckConstraint(
            "scope_type IN ('room','space','residence','service','contractor','vendor')",
            name="performance_checks_scope_type_check",
        ),
        CheckConstraint(
            "status IN ('excellent','good','degraded','poor','critical','not_enough_data')",
            name="performance_checks_status_check",
        ),
        CheckConstraint("score >= 0 AND score <= 100", name="performance_checks_score_check"),
        Index("idx_performance_checks_scope", "scope_type", "scope_id"),
        Index("idx_performance_checks_calculated_at", "calculated_at"),
    )


class PerformanceFinding(Base):
    __tablename__ = "performance_findings"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    check_id = Column(UUID(as_uuid=True), ForeignKey("performance_checks.id", ondelete="CASCADE"), nullable=False)
    finding_type = Column(Text, nullable=False)
    severity = Column(Text, nullable=False, default="medium")
    message = Column(Text, nullable=False)
    related_entity_type = Column(Text, nullable=True)
    related_entity_id = Column(UUID(as_uuid=True), nullable=True)
    created_issue_id = Column(UUID(as_uuid=True), ForeignKey("issues.id", ondelete="SET NULL"), nullable=True)

    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now())

    check = relationship("PerformanceCheck", back_populates="findings")

    __table_args__ = (
        CheckConstraint(
            "finding_type IN ("
            "'low_rating','broken_item','dirty_space','sla_breach','repeat_issue',"
            "'high_backlog','poor_service','inspection_condition'"
            ")",
            name="performance_findings_type_check",
        ),
        CheckConstraint(
            "severity IN ('low','medium','high','critical')",
            name="performance_findings_severity_check",
        ),
        Index("idx_performance_findings_check", "check_id"),
        Index("idx_performance_findings_related", "related_entity_type", "related_entity_id"),
    )
