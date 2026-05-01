from sqlalchemy import Column, String, Boolean, Integer, TIMESTAMP, text, ForeignKey, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class Space(Base):
    __tablename__ = "spaces"

    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=text("gen_random_uuid()")
    )

    residence_id = Column(
        UUID(as_uuid=True),
        ForeignKey("residences.id", ondelete="CASCADE"),
        nullable=False
    )

    name = Column(String, nullable=False)
    space_type = Column(String, nullable=False)

    template_type = Column(String, nullable=False, server_default=text("'single_room'"))
    standard = Column(String, nullable=False, server_default=text("'nsfas'"))

    is_rentable = Column(Boolean, server_default=text("false"))
    capacity = Column(Integer, server_default=text("0"))

    floor = Column(Integer, nullable=True)
    notes = Column(String, nullable=True)

    created_at = Column(
        TIMESTAMP(timezone=True),
        server_default=func.now()
    )

    is_active = Column(Boolean, server_default=text("true"))

    updated_at = Column(
        TIMESTAMP(timezone=True),
        server_default=func.now(),
        onupdate=func.now()
    )

    archived_at = Column(TIMESTAMP(timezone=True), nullable=True)

    residence = relationship("Residence", backref="spaces")

    __table_args__ = (
        CheckConstraint(
            "space_type IN ('room','bathroom','kitchen','common','other')",
            name="spaces_type_check"
        ),
    )
