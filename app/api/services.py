from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.openapi import COMMON_ERROR_RESPONSES
from app.core.database import get_db
from app.schemas.service_catalog import (
    ResidenceServiceCreate,
    ResidenceServiceResponse,
    ServiceCreate,
    ServicePerformanceSummary,
    ServiceResponse,
)
from app.services import service_catalog

router = APIRouter(prefix="/services", tags=["Services"])


@router.post("/", response_model=ServiceResponse, responses=COMMON_ERROR_RESPONSES)
def create_service(payload: ServiceCreate, db: Session = Depends(get_db)):
    return service_catalog.create_service(db, payload)


@router.get("/", response_model=list[ServiceResponse], responses=COMMON_ERROR_RESPONSES)
def list_services(include_archived: bool = False, db: Session = Depends(get_db)):
    return service_catalog.list_services(db, include_archived=include_archived)


@router.post("/seed-core", responses=COMMON_ERROR_RESPONSES)
def seed_core_services(db: Session = Depends(get_db)):
    return {"services_created": service_catalog.seed_core_services(db)}


@router.delete("/{service_id}", response_model=ServiceResponse, responses=COMMON_ERROR_RESPONSES)
def archive_service(service_id: UUID, db: Session = Depends(get_db)):
    return service_catalog.archive_service(db, service_id)


@router.post(
    "/residence-services",
    response_model=ResidenceServiceResponse,
    responses=COMMON_ERROR_RESPONSES,
)
def create_residence_service(payload: ResidenceServiceCreate, db: Session = Depends(get_db)):
    return service_catalog.create_residence_service(db, payload)


@router.get(
    "/residence-services",
    response_model=list[ResidenceServiceResponse],
    responses=COMMON_ERROR_RESPONSES,
)
def list_residence_services(
    residence_id: UUID = None,
    service_id: UUID = None,
    status: str = None,
    include_archived: bool = False,
    db: Session = Depends(get_db),
):
    return service_catalog.list_residence_services(
        db,
        residence_id=residence_id,
        service_id=service_id,
        status=status,
        include_archived=include_archived,
    )


@router.get(
    "/residence-services/{residence_service_id}/performance",
    response_model=ServicePerformanceSummary,
    responses=COMMON_ERROR_RESPONSES,
)
def get_service_performance(residence_service_id: UUID, db: Session = Depends(get_db)):
    return service_catalog.get_service_performance_summary(db, residence_service_id)


@router.delete(
    "/residence-services/{residence_service_id}",
    response_model=ResidenceServiceResponse,
    responses=COMMON_ERROR_RESPONSES,
)
def archive_residence_service(residence_service_id: UUID, db: Session = Depends(get_db)):
    return service_catalog.archive_residence_service(db, residence_service_id)
