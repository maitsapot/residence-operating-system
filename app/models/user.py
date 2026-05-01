from sqlalchemy import Column, String, Boolean, ForeignKey, TIMESTAMP, Date, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class User(Base):
    __tablename__ = "users"

    # ===============================
    # PRIMARY KEY
    # ===============================
    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=text("gen_random_uuid()")
    )

    # ===============================
    # NAME FIELDS
    # ===============================
    first_name = Column(String, nullable=False)
    middle_name = Column(String, nullable=True)
    last_name = Column(String, nullable=False)

    # ===============================
    # CONTACT
    # ===============================
    email = Column(String, unique=True, nullable=True)
    cellphone = Column(String, nullable=False, index=True)
    phone = Column(String, nullable=True)

    # ===============================
    # PERSONAL
    # ===============================
    id_number = Column(String, nullable=True)
    date_of_birth = Column(Date, nullable=False)
    gender = Column(String, nullable=False)
    race = Column(String, nullable=False)
  
    # ===============================
    # LOCATION
    # ===============================
    location_id = Column(
        UUID(as_uuid=True),
        ForeignKey("locations.id"),
        nullable=True,
        index=True
    )

    # ===============================
    # MOBILE / NOTIFICATIONS
    # ===============================
    fcm_token = Column(String, nullable=True)

    # ===============================
    # STATUS
    # ===============================
    is_active = Column(Boolean, default=True)

    # ===============================
    # AUDIT
    # ===============================
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
    location = relationship("Location", backref="users")

    # ===============================
    # COMPUTED FULL NAME (CLEAN)
    # ===============================
    @property
    def full_name(self):
        return " ".join(
            part for part in [self.first_name, self.middle_name, self.last_name]
            if part and part.strip()
        )
