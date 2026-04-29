import uuid
from sqlalchemy import Column, Text, Boolean, ForeignKey, CheckConstraint, Index, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from sqlalchemy.types import TIMESTAMP

from app.core.database import Base


class CommonIssue(Base):
    """
    Predefined/common issues for a catalog item.

    Used for dropdown selection and automation.
    """

    __tablename__ = "common_issues"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # FK → catalog
    catalog_id = Column(
        UUID(as_uuid=True),
        ForeignKey("catalog.id", ondelete="CASCADE"),
        nullable=False
    )

    issue_name = Column(Text, nullable=False)

    default_severity = Column(Text, nullable=False, default="medium")
    default_urgency = Column(Text, nullable=False, default="medium")

    is_other = Column(Boolean, default=False)
    is_active = Column(Boolean, default=True)

    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())

    __table_args__ = (
        UniqueConstraint("catalog_id", "issue_name", name="common_issues_unique"),

        CheckConstraint(
            "default_severity IN ('low','medium','high','critical')",
            name="common_issues_severity_check"
        ),

        CheckConstraint(
            "default_urgency IN ('low','medium','high','urgent')",
            name="common_issues_urgency_check"
        ),

        Index("idx_common_issues_catalog", "catalog_id"),
        Index("idx_common_issues_active", "is_active"),
    )
