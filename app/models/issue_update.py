import uuid
from sqlalchemy import Column, Text, ForeignKey, TIMESTAMP, CheckConstraint, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func

from app.core.database import Base


class IssueUpdate(Base):
    """
    Audit trail for every change to an issue.
    """

    __tablename__ = "issue_updates"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    issue_id = Column(
        UUID(as_uuid=True),
        ForeignKey("issues.id", ondelete="CASCADE"),
        nullable=False
    )

    updated_by = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=False
    )

    # Snapshot fields
    status = Column(Text)
    comment = Column(Text)

    update_type = Column(Text, nullable=False)

    old_status = Column(Text)
    new_status = Column(Text)

    old_assigned_to = Column(UUID(as_uuid=True))
    new_assigned_to = Column(UUID(as_uuid=True))

    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())

    __table_args__ = (
        CheckConstraint(
            "update_type IN ('status_change','assignment','comment','system')",
            name="issue_updates_type_check"
        ),
        Index("idx_issue_updates_issue", "issue_id"),
    )