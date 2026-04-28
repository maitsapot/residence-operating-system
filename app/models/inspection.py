from sqlalchemy import Column, Text, Boolean, ForeignKey, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID, TIMESTAMP
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import uuid

from app.core.database import Base


class Inspection(Base):
    __tablename__ = "inspections"

    # ===============================
    # PRIMARY KEY
    # ===============================
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # ===============================
    # CORE RELATIONSHIPS
    # ===============================
    space_item_id = Column(
        UUID(as_uuid=True),
        ForeignKey("space_items.id"),
        nullable=False
    )

    inspected_by = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id"),
        nullable=False
    )

    tenancy_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tenancies.id"),
        nullable=True
    )

    # ===============================
    # INSPECTION DATA
    # ===============================
    condition = Column(Text, nullable=False)
    notes = Column(Text, nullable=True)
    image_url = Column(Text, nullable=True)

    inspection_type = Column(
        Text,
        nullable=False,
        default="routine"
    )

    # ===============================
    # SIGN-OFF & STATUS
    # ===============================
    inspector_signed_off = Column(Boolean, default=False)
    tenant_signed_off = Column(Boolean, default=False)

    status = Column(
        Text,
        nullable=False,
        default="draft"
    )

    inspector_signature = Column(Text, nullable=True)
    tenant_signature = Column(Text, nullable=True)

    # ===============================
    # AUDIT FIELDS
    # ===============================
    created_at = Column(
        TIMESTAMP(timezone=True),
        server_default=func.now()
    )

    updated_at = Column(
        TIMESTAMP(timezone=True),
        server_default=func.now(),
        onupdate=func.now()
    )

    # ===============================
    # RELATIONSHIPS (OPTIONAL BUT RECOMMENDED)
    # ===============================
    space_item = relationship("SpaceItem")
    inspector = relationship("User", foreign_keys=[inspected_by])
    tenancy = relationship("Tenancy")

    # ===============================
    # CONSTRAINTS (CRITICAL)
    # ===============================
    __table_args__ = (

        # Condition values
        CheckConstraint(
            "condition IN ('good', 'fair', 'poor', 'damaged')",
            name="chk_inspection_condition"
        ),

        # Inspection type
        CheckConstraint(
            "inspection_type IN ('routine', 'checkin', 'checkout', 'audit')",
            name="chk_inspection_type"
        ),

        # Status
        CheckConstraint(
            "status IN ('draft', 'completed')",
            name="chk_inspection_status"
        ),
    )