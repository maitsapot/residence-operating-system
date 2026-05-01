import uuid

from sqlalchemy import Boolean, CheckConstraint, Column, Date, ForeignKey, Index, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from sqlalchemy.types import TIMESTAMP

from app.core.database import Base


class ServiceCatalog(Base):
    __tablename__ = "services"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(Text, nullable=False, unique=True)
    description = Column(Text, nullable=True)
    is_active = Column(Boolean, nullable=False, default=True)

    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now())
    archived_at = Column(TIMESTAMP(timezone=True), nullable=True)

    residence_services = relationship("ResidenceService", back_populates="service")

    __table_args__ = (
        Index("idx_services_name", "name"),
        Index("idx_services_archived_at", "archived_at"),
    )


class ResidenceService(Base):
    __tablename__ = "residence_services"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    residence_id = Column(UUID(as_uuid=True), ForeignKey("residences.id", ondelete="CASCADE"), nullable=False)
    service_id = Column(UUID(as_uuid=True), ForeignKey("services.id", ondelete="RESTRICT"), nullable=False)
    provider_type = Column(Text, nullable=False, default="internal")
    provider_id = Column(UUID(as_uuid=True), nullable=True)
    status = Column(Text, nullable=False, default="active")
    started_at = Column(Date, nullable=True)
    ended_at = Column(Date, nullable=True)

    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now())
    archived_at = Column(TIMESTAMP(timezone=True), nullable=True)

    residence = relationship("Residence", backref="residence_services")
    service = relationship("ServiceCatalog", back_populates="residence_services")

    __table_args__ = (
        CheckConstraint(
            "provider_type IN ('internal','contractor','vendor','company','other')",
            name="residence_services_provider_type_check",
        ),
        CheckConstraint(
            "status IN ('active','paused','cancelled','ended')",
            name="residence_services_status_check",
        ),
        Index("idx_residence_services_residence", "residence_id"),
        Index("idx_residence_services_service", "service_id"),
        Index("idx_residence_services_status", "status"),
        Index("idx_residence_services_provider", "provider_type", "provider_id"),
        Index("idx_residence_services_archived_at", "archived_at"),
    )
