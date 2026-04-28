from sqlalchemy import Column, String, Boolean, TIMESTAMP, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.core.database import Base
from sqlalchemy import ForeignKey


class Company(Base):
    __tablename__ = "companies"

    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=text("gen_random_uuid()")
    )

    name = Column(String, nullable=False)

    registration_number = Column(String, unique=True, nullable=True)

    location_id = Column(
        UUID(as_uuid=True),
        ForeignKey("locations.id"),
        nullable=False
    )

    is_active = Column(Boolean, server_default=text("true"))

    created_at = Column(
        TIMESTAMP(timezone=True),
        server_default=text("NOW()")
    )

    updated_at = Column(
        TIMESTAMP(timezone=True),
        server_default=text("NOW()")
    )

    # 🔥 relationship
    location = relationship("Location", backref="companies")