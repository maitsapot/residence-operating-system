from uuid import UUID

from fastapi import HTTPException
from sqlalchemy.orm import Session, joinedload
from sqlalchemy.sql import func

from app.models.residence import Residence
from app.models.service_catalog import ResidenceService, ServiceCatalog
from app.schemas.service_catalog import ResidenceServiceCreate, ServiceCreate
from app.services.performance import get_target_rating_summary

CORE_SERVICE_NAMES = ["cleaning", "wifi", "security", "laundry", "maintenance"]
VALID_PROVIDER_TYPES = {"internal", "contractor", "vendor", "company", "other"}
VALID_RESIDENCE_SERVICE_STATUSES = {"active", "paused", "cancelled", "ended"}


def seed_core_services(db: Session):
    created = 0
    for name in CORE_SERVICE_NAMES:
        existing = db.query(ServiceCatalog).filter(
            ServiceCatalog.name == name,
            ServiceCatalog.archived_at.is_(None),
        ).first()
        if existing:
            continue
        db.add(
            ServiceCatalog(
                name=name,
                description=f"Core residence service: {name}",
                is_active=True,
            )
        )
        created += 1
    db.commit()
    return created


def create_service(db: Session, payload: ServiceCreate):
    existing = db.query(ServiceCatalog).filter(
        ServiceCatalog.name == payload.name,
        ServiceCatalog.archived_at.is_(None),
    ).first()
    if existing:
        raise HTTPException(409, "Service already exists")
    service = ServiceCatalog(**payload.model_dump())
    db.add(service)
    db.commit()
    db.refresh(service)
    return service


def list_services(db: Session, *, include_archived: bool = False):
    query = db.query(ServiceCatalog)
    if not include_archived:
        query = query.filter(ServiceCatalog.archived_at.is_(None))
    return query.order_by(ServiceCatalog.name).all()


def archive_service(db: Session, service_id: UUID):
    service = _get_service(db, service_id)
    service.archived_at = func.now()
    service.is_active = False
    db.commit()
    db.refresh(service)
    return service


def create_residence_service(db: Session, payload: ResidenceServiceCreate):
    _validate_residence_service_payload(db, payload)
    residence_service = ResidenceService(**payload.model_dump())
    db.add(residence_service)
    db.commit()
    return get_residence_service(db, residence_service.id)


def list_residence_services(
    db: Session,
    *,
    residence_id: UUID | None = None,
    service_id: UUID | None = None,
    status: str | None = None,
    include_archived: bool = False,
):
    query = db.query(ResidenceService).options(joinedload(ResidenceService.service))
    if not include_archived:
        query = query.filter(ResidenceService.archived_at.is_(None))
    if residence_id:
        query = query.filter(ResidenceService.residence_id == residence_id)
    if service_id:
        query = query.filter(ResidenceService.service_id == service_id)
    if status:
        query = query.filter(ResidenceService.status == status)
    return query.order_by(ResidenceService.created_at.desc()).all()


def get_residence_service(db: Session, residence_service_id: UUID):
    residence_service = db.query(ResidenceService).options(
        joinedload(ResidenceService.service)
    ).filter(
        ResidenceService.id == residence_service_id,
        ResidenceService.archived_at.is_(None),
    ).first()
    if not residence_service:
        raise HTTPException(404, "Residence service not found")
    return residence_service


def archive_residence_service(db: Session, residence_service_id: UUID):
    residence_service = get_residence_service(db, residence_service_id)
    residence_service.status = "ended"
    residence_service.archived_at = func.now()
    db.commit()
    return get_residence_service_including_archived(db, residence_service_id)


def get_residence_service_including_archived(db: Session, residence_service_id: UUID):
    residence_service = db.query(ResidenceService).options(
        joinedload(ResidenceService.service)
    ).filter(ResidenceService.id == residence_service_id).first()
    if not residence_service:
        raise HTTPException(404, "Residence service not found")
    return residence_service


def get_service_performance_summary(db: Session, residence_service_id: UUID):
    residence_service = get_residence_service(db, residence_service_id)
    rating_summary = get_target_rating_summary(
        db,
        target_type="service",
        target_id=residence_service.id,
    )
    return {
        "residence_service_id": residence_service.id,
        "service_id": residence_service.service_id,
        "residence_id": residence_service.residence_id,
        "service_name": residence_service.service.name,
        "status": residence_service.status,
        "ratings_count": rating_summary["ratings_count"],
        "average_rating": rating_summary["average_rating"],
    }


def _get_service(db: Session, service_id: UUID):
    service = db.query(ServiceCatalog).filter(
        ServiceCatalog.id == service_id,
        ServiceCatalog.archived_at.is_(None),
    ).first()
    if not service:
        raise HTTPException(404, "Service not found")
    return service


def _validate_residence_service_payload(db: Session, payload: ResidenceServiceCreate):
    if payload.provider_type not in VALID_PROVIDER_TYPES:
        raise HTTPException(400, "Invalid provider type")
    if payload.status not in VALID_RESIDENCE_SERVICE_STATUSES:
        raise HTTPException(400, "Invalid residence service status")
    if not db.query(Residence.id).filter(Residence.id == payload.residence_id).first():
        raise HTTPException(404, "Residence not found")
    service = _get_service(db, payload.service_id)
    if not service.is_active:
        raise HTTPException(400, "Cannot assign inactive service")
