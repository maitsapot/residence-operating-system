from sqlalchemy import Column, ForeignKey
from sqlalchemy.dialects.postgresql import UUID, TIMESTAMP
from sqlalchemy.sql import func

from app.core.database import Base


class ResidenceStaff(Base):
    __tablename__ = "residence_staff"

    residence_id = Column(
        UUID(as_uuid=True),
        ForeignKey("residences.id", ondelete="CASCADE"),
        primary_key=True
    )

    staff_id = Column(
        UUID(as_uuid=True),
        ForeignKey("staff.id", ondelete="CASCADE"),
        primary_key=True
    )

    created_at = Column(
        TIMESTAMP(timezone=True),
        server_default=func.now()
    )