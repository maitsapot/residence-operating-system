from sqlalchemy import Column, ForeignKey
from sqlalchemy.dialects.postgresql import UUID, TIMESTAMP
from sqlalchemy.sql import func

from app.core.database import Base


class ResidenceCaretaker(Base):
    __tablename__ = "residence_caretakers"

    # ===============================
    # COMPOSITE PRIMARY KEY
    # ===============================
    residence_id = Column(
        UUID(as_uuid=True),
        ForeignKey("residences.id", ondelete="CASCADE"),
        primary_key=True
    )

    caretaker_id = Column(
        UUID(as_uuid=True),
        ForeignKey("caretakers.user_id", ondelete="CASCADE"),
        primary_key=True
    )

    # ===============================
    # AUDIT
    # ===============================
    created_at = Column(
        TIMESTAMP(timezone=True),
        server_default=func.now()
    )