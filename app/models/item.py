import uuid
from sqlalchemy import Column, Text, Boolean, ForeignKey, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from sqlalchemy.types import TIMESTAMP

from app.core.database import Base


class Item(Base):
    """
    Physical instance of a catalog item inside a space.

    Example:
    Catalog: Bed
    Item: Bed in Room 101 (QR123)
    """

    __tablename__ = "items"

    # Primary key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # FK → space (physical location)
    space_id = Column(
        UUID(as_uuid=True),
        ForeignKey("spaces.id", ondelete="CASCADE"),
        nullable=False
    )

    # FK → catalog (what this item is)
    catalog_id = Column(
        UUID(as_uuid=True),
        ForeignKey("catalog.id", ondelete="RESTRICT"),
        nullable=False
    )

    # Optional override name
    name = Column(Text)

    # Can override catalog tracking behavior
    is_trackable = Column(Boolean)

    # Unique QR code (if provided)
    qr_code = Column(Text, unique=True)

    # Current condition of item
    condition = Column(Text, default="good")

    # Lifecycle state
    status = Column(Text, default="active")

    # Free notes
    notes = Column(Text)

    # Audit fields
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now())

    # DB constraint alignment
    __table_args__ = (
        CheckConstraint(
            "condition IN ('good','fair','poor','damaged')",
            name="items_condition_check"
        ),
        CheckConstraint(
            "status IN ('active','removed','replaced')",
            name="items_status_check"
        ),
        CheckConstraint(
            "(qr_code IS NULL) OR (is_trackable = true)",
            name="items_qr_trackable_check"
        ),
    )