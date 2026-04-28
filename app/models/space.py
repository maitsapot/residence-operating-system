from sqlalchemy import Column, String, Boolean, Integer, TIMESTAMP, text, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

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

    is_rentable = Column(Boolean, server_default=text("false"))
    capacity = Column(Integer, server_default=text("0"))

    floor = Column(Integer, nullable=True)
    notes = Column(String, nullable=True)

    created_at = Column(
        TIMESTAMP(timezone=True),
        server_default=text("NOW()")
    )

    residence = relationship("Residence", backref="spaces")