from sqlalchemy import Column, ForeignKey, Text, Integer, Date, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID, TIMESTAMP
from sqlalchemy.sql import func
import uuid

from app.core.database import Base


class NsfasAccreditation(Base):
    __tablename__ = "nsfas_accreditations"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    residence_id = Column(
        UUID(as_uuid=True),
        ForeignKey("residences.id", ondelete="CASCADE"),
        nullable=False
    )

    accreditation_number = Column(Text, nullable=True)

    status = Column(Text, nullable=False)

    approved_capacity = Column(Integer, nullable=True)

    valid_from = Column(Date, nullable=True)
    valid_to = Column(Date, nullable=True)

    document_url = Column(Text, nullable=True)
    notes = Column(Text, nullable=True)

    created_at = Column(
        TIMESTAMP(timezone=True),
        server_default=func.now()
    )

    updated_at = Column(
        TIMESTAMP(timezone=True),
        server_default=func.now(),
        onupdate=func.now()
    )

    __table_args__ = (
        CheckConstraint(
            "status IN ('pending', 'approved', 'rejected', 'expired')",
            name="chk_nsfas_status"
        ),
    )