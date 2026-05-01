from sqlalchemy import Column, String, TIMESTAMP, text, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class Staff(Base):
    __tablename__ = "staff"

    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=text("gen_random_uuid()")
    )

    user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False
    )

    role = Column(
        String,
        nullable=False
    )

    company_id = Column(
        UUID(as_uuid=True),
        ForeignKey("companies.id", ondelete="SET NULL"),
        nullable=True
    )

    created_at = Column(
        TIMESTAMP(timezone=True),
        server_default=func.now()
    )

    updated_at = Column(
        TIMESTAMP(timezone=True),
        server_default=func.now(),
        onupdate=func.now()
    )

    # relationships
    user = relationship("User")
