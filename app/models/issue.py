from sqlalchemy import Column, Text, ForeignKey, TIMESTAMP, Numeric, CheckConstraint, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from app.core.database import Base
import uuid


class Issue(Base):
    """
    Issue = actionable problem derived from inspection or manual reporting.
    """

    __tablename__ = "issues"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Who reported the issue
    reported_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)

    # Assigned user (caretaker/technician)
    assigned_to = Column(UUID(as_uuid=True), ForeignKey("users.id"))

    status = Column(Text, nullable=False, default="open")

    due_at = Column(TIMESTAMP(timezone=True))
    resolved_at = Column(TIMESTAMP(timezone=True))

    description = Column(Text)

    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(
        TIMESTAMP(timezone=True),
        server_default=func.now(),
        onupdate=func.now()
    )
    archived_at = Column(TIMESTAMP(timezone=True), nullable=True)

    # 🔷 Core relationships
    space_id = Column(UUID(as_uuid=True), ForeignKey("spaces.id"), nullable=False)
    space_item_id = Column(UUID(as_uuid=True), ForeignKey("space_items.id"))
    inspection_id = Column(UUID(as_uuid=True), ForeignKey("inspections.id"))
    tenancy_id = Column(UUID(as_uuid=True), ForeignKey("tenancies.id"))

    common_issue_id = Column(UUID(as_uuid=True), ForeignKey("common_issues.id"), nullable=False)

    severity = Column(Text, nullable=False, default="medium")
    urgency = Column(Text, nullable=False, default="medium")

    estimated_cost = Column(Numeric(12, 2))
    actual_cost = Column(Numeric(12, 2))

    __table_args__ = (
        CheckConstraint(
            "status IN ('open','assigned','in_progress','resolved','closed','rejected')",
            name="issues_status_check"
        ),
        CheckConstraint(
            "severity IN ('low','medium','high','critical')",
            name="issues_severity_check"
        ),
        CheckConstraint(
            "urgency IN ('low','medium','high','urgent')",
            name="issues_urgency_check"
        ),
        CheckConstraint(
            "(estimated_cost IS NULL OR estimated_cost >= 0) AND "
            "(actual_cost IS NULL OR actual_cost >= 0)",
            name="issues_cost_check"
        ),
        Index("idx_issues_space", "space_id"),
        Index("idx_issues_space_item", "space_item_id"),
        Index("idx_issues_common_issue", "common_issue_id"),
        Index("idx_issues_status", "status"),
    )
