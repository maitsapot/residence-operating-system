from sqlalchemy import Column, ForeignKey, Text, Date, Boolean
from sqlalchemy.dialects.postgresql import UUID, TIMESTAMP
from sqlalchemy.sql import func

from app.core.database import Base


class ResidenceManager(Base):
    __tablename__ = "residence_managers"

    # ===============================
    # COMPOSITE PRIMARY KEY
    # ===============================
    residence_id = Column(
        UUID(as_uuid=True),
        ForeignKey("residences.id", ondelete="CASCADE"),
        primary_key=True
    )

    manager_id = Column(
        UUID(as_uuid=True),
        ForeignKey("managers.user_id", ondelete="CASCADE"),
        primary_key=True
    )

    # ===============================
    # ADDITIONAL FIELDS
    # ===============================
    employee_number = Column(Text, nullable=True)
    hire_date = Column(Date, nullable=True)
    is_primary = Column(Boolean, nullable=False, default=False)

    created_at = Column(
        TIMESTAMP(timezone=True),
        server_default=func.now()
    )

    updated_at = Column(
        TIMESTAMP(timezone=True),
        server_default=func.now(),
        onupdate=func.now()
    )
