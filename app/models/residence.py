from sqlalchemy import Column, String, Boolean, Integer, TIMESTAMP, text, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.models.residence_landlords import ResidenceLandlord
from app.models.residence_caretaker import ResidenceCaretaker
from app.models.residence_manager import ResidenceManager
from app.models.residence_staff import ResidenceStaff

from app.core.database import Base


class Residence(Base):
    __tablename__ = "residences"

    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=text("gen_random_uuid()")
    )

    name = Column(String, nullable=False)

    company_id = Column(
        UUID(as_uuid=True),
        ForeignKey("companies.id"),
        nullable=True
    )

    location_id = Column(
        UUID(as_uuid=True),
        ForeignKey("locations.id"),
        nullable=False
    )

    total_rooms = Column(Integer, server_default=text("0"))
    total_capacity = Column(Integer, server_default=text("0"))

    is_active = Column(Boolean, server_default=text("true"))

    created_at = Column(
        TIMESTAMP(timezone=True),
        server_default=func.now()
    )

    updated_at = Column(
        TIMESTAMP(timezone=True),
        server_default=func.now(),
        onupdate=func.now()
    )

    archived_at = Column(TIMESTAMP(timezone=True), nullable=True)

    # ===============================
    # RELATIONSHIPS
    # ===============================

    # Core relations
    location = relationship("Location", backref="residences")
    company = relationship("Company", backref="residences")

    # 🔥 Role relationships (many-to-many)

    landlords = relationship(
        "Landlord",
        secondary="residence_landlords",
        backref="residences"
    )

    caretakers = relationship(
        "Caretaker",
        secondary="residence_caretakers",
        backref="residences"
    )

    managers = relationship(
        "Manager",
        secondary=ResidenceManager.__table__,
        primaryjoin="Residence.id == ResidenceManager.residence_id",
        secondaryjoin="Manager.user_id == ResidenceManager.manager_id",
        backref="residences"
    )

    staff = relationship(
        "Staff",
        secondary="residence_staff",
        backref="residences"
    )
