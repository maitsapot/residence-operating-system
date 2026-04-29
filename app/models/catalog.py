import uuid
from sqlalchemy import Column, Text, Boolean, Integer, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from sqlalchemy.types import TIMESTAMP

from app.core.database import Base


class Catalog(Base):
    """
    Master definition of items.
    Replaces item_catalog.
    """

    __tablename__ = "catalog"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    category_id = Column(
        UUID(as_uuid=True),
        ForeignKey("categories.id", ondelete="RESTRICT"),
        nullable=False
    )

    name = Column(Text, nullable=False, unique=True)

    is_trackable = Column(Boolean, default=True)
    default_quantity = Column(Integer, default=1)
    is_active = Column(Boolean, default=True)

    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
