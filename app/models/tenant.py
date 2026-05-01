from sqlalchemy import Column, Boolean, String, TIMESTAMP, text, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class Tenant(Base):
    __tablename__ = "tenants"

    user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True
    )

    is_student = Column(Boolean, nullable=False, server_default=text("false"))

    student_number = Column(String, nullable=True)

    institution_id = Column(
        UUID(as_uuid=True),
        ForeignKey("institutions.id", ondelete="SET NULL"),
        nullable=True
    )

    emergency_contact_user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True
    )
    emergency_contact_relationship = Column(String)

    guardian_user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True
    )
    guardian_relationship = Column(String)

    authorized_proxy_user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True
    )
    authorized_proxy_relationship = Column(String)

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
    user = relationship("User", foreign_keys=[user_id])
    institution = relationship("Institution")
    emergency_contact_user = relationship("User", foreign_keys=[emergency_contact_user_id])
    guardian_user = relationship("User", foreign_keys=[guardian_user_id])
    authorized_proxy_user = relationship("User", foreign_keys=[authorized_proxy_user_id])
