from sqlalchemy import Column, ForeignKey, Text, Integer, Boolean, CheckConstraint, Index, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID, TIMESTAMP
from sqlalchemy.sql import func
import uuid

from app.core.database import Base


class SpaceItemTemplate(Base):
    __tablename__ = "space_item_templates"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    template_type = Column(Text, nullable=False, default="single_room")
    standard = Column(Text, nullable=False, default="nsfas")

    space_type = Column(Text, nullable=False)

    item_id = Column(
        UUID(as_uuid=True),
        ForeignKey("items.id", ondelete="RESTRICT"),
        nullable=False
    )

    default_quantity = Column(Integer, default=1)
    is_required = Column(Boolean, default=True)

    created_at = Column(
        TIMESTAMP(timezone=True),
        server_default=func.now()
    )

    __table_args__ = (
        CheckConstraint(
            "space_type IN ('room','bathroom','kitchen','common','other')",
            name="chk_space_item_template_type"
        ),
        CheckConstraint(
            "default_quantity >= 1",
            name="chk_space_item_template_quantity"
        ),
        UniqueConstraint(
            "template_type",
            "standard",
            "space_type",
            "item_id",
            name="uq_space_item_template_item"
        ),
        Index(
            "idx_space_item_templates_lookup",
            "template_type",
            "standard",
            "space_type"
        ),
    )
