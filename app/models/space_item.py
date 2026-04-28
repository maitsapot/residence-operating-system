import uuid
from sqlalchemy import (
    Column, Integer, Boolean, Text, ForeignKey,
    CheckConstraint, UniqueConstraint, Index
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from sqlalchemy.types import TIMESTAMP

from app.core.database import Base


class SpaceItem(Base):
    """
    Defines expected items for a space (blueprint level).
    """

    __tablename__ = "space_items"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # FK → space
    space_id = Column(
        UUID(as_uuid=True),
        ForeignKey("spaces.id", ondelete="CASCADE"),
        nullable=False
    )

    # FK → catalog
    catalog_id = Column(
        UUID(as_uuid=True),
        ForeignKey("catalog.id", ondelete="RESTRICT"),
        nullable=False
    )

    # Expected quantity (must be >= 1)
    quantity = Column(Integer, nullable=False, default=1)

    # Whether item is mandatory
    is_required = Column(Boolean, default=True)

    # Baseline condition expectation
    condition = Column(Text, nullable=False, default="good")

    # Lifecycle status
    status = Column(Text, nullable=False, default="active")

    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(
        TIMESTAMP(timezone=True),
        server_default=func.now(),
        onupdate=func.now()
    )

    __table_args__ = (
        # Prevent duplicates per space
        UniqueConstraint("space_id", "catalog_id", name="uq_space_catalog"),

        # Condition constraint
        CheckConstraint(
            "condition IN ('good','fair','poor','damaged')",
            name="space_items_condition_check"
        ),

        # Status constraint
        CheckConstraint(
            "status IN ('active','removed','missing','damaged')",
            name="space_items_status_check"
        ),

        # Quantity must be valid
        CheckConstraint(
            "quantity >= 1",
            name="space_items_quantity_check"
        ),

        # Performance
        Index("idx_space_items_space", "space_id"),
    )