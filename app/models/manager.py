from sqlalchemy import Column, TIMESTAMP, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class Manager(Base):
    __tablename__ = "managers"

    user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True
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

    user = relationship("User")
