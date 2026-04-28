from sqlalchemy import Column, ForeignKey, Text, Integer, Boolean, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID, TIMESTAMP
from sqlalchemy.sql import func
import uuid

from app.core.database import Base


class SpaceItemTemplate(Base):
    __tablename__ = "space_item_templates"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    space_type = Column(Text, nullable=False)

    catalog_id = Column(
        UUID(as_uuid=True),
        ForeignKey("catalog.id", ondelete="RESTRICT"),
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
            "space_type IN ('single', 'double', 'triple', 'ensuite', 'communal')",
            name="chk_space_item_template_type"
        ),
    )