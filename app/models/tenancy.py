from sqlalchemy import Column, Date, Text, ForeignKey, TIMESTAMP, text, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.core.database import Base


class Tenancy(Base):
    __tablename__ = "tenancies"

    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=text("gen_random_uuid()")
    )

    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=True)

    status = Column(
        Text,
        nullable=False,
        server_default=text("'active'")
    )

    user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False
    )

    space_id = Column(
        UUID(as_uuid=True),
        ForeignKey("spaces.id", ondelete="CASCADE"),
        nullable=False
    )

    created_at = Column(
        TIMESTAMP(timezone=True),
        server_default=text("NOW()")
    )

    updated_at = Column(
        TIMESTAMP(timezone=True),
        server_default=text("NOW()")
    )

    # ===============================
    # RELATIONSHIPS
    # ===============================
    user = relationship("User", backref="tenancies")
    space = relationship("Space", backref="tenancies")

    # ===============================
    # CONSTRAINTS
    # ===============================
    __table_args__ = (
        CheckConstraint(
            "status IN ('active', 'terminated', 'completed')",
            name="chk_tenancy_status"
        ),
    )