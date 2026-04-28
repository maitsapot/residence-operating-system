from sqlalchemy import Column, String, Boolean, TIMESTAMP, text, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.core.database import Base


class Institution(Base):
    __tablename__ = "institutions"

    id = Column(UUID(as_uuid=True), primary_key=True, server_default=text("gen_random_uuid()"))

    name = Column(String, nullable=False, unique=True)
    code = Column(String, nullable=True)

    institution_type = Column(String, nullable=False)

    parent_id = Column(UUID(as_uuid=True), ForeignKey("institutions.id"), nullable=True)

    location_id = Column(
        UUID(as_uuid=True),
        ForeignKey("locations.id"),
        nullable=False
    )

    is_active = Column(Boolean, server_default=text("true"))

    created_at = Column(TIMESTAMP(timezone=True), server_default=text("NOW()"))
    updated_at = Column(TIMESTAMP(timezone=True), server_default=text("NOW()"))

    # relationships
    location = relationship("Location")
    parent = relationship("Institution", remote_side=[id])