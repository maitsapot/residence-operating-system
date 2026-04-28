import uuid
from sqlalchemy import Column, Text, Boolean, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID

from app.core.database import Base


class Category(Base):
    """
    Categories define high-level grouping of items
    (e.g. furniture, electrical, plumbing).
    """

    __tablename__ = "categories"

    # Primary key (UUID)
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Must match predefined allowed values (DB constraint enforced)
    category_name = Column(Text, nullable=False, unique=True)

    # Indicates whether items in this category can be tracked (QR, lifecycle)
    is_trackable = Column(Boolean, default=False)

    # Soft enable/disable
    is_active = Column(Boolean, default=True)

    # Enforce allowed category values (aligned with DB)
    __table_args__ = (
        CheckConstraint(
            "category_name IN ('furniture','structural','electrical','plumbing','appliance','hygiene','security','other')",
            name="categories_name_check"
        ),
    )