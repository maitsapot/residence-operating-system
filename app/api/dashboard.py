from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.openapi import COMMON_ERROR_RESPONSES
from app.core.database import get_db
from app.services import dashboard as dashboard_service

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])


@router.get(
    "/compliance/residences/{residence_id}",
    summary="Get residence compliance dashboard summary",
    description="Returns latest compliance snapshots and open compliance finding counts for a residence.",
    responses=COMMON_ERROR_RESPONSES,
)
def get_compliance_summary(residence_id: UUID, db: Session = Depends(get_db)):
    return dashboard_service.get_compliance_summary(db, residence_id)


@router.get(
    "/performance/residences/{residence_id}",
    summary="Get residence performance dashboard summary",
    description="Returns latest performance snapshots, active issues, and performance finding counts.",
    responses=COMMON_ERROR_RESPONSES,
)
def get_performance_summary(residence_id: UUID, db: Session = Depends(get_db)):
    return dashboard_service.get_performance_summary(db, residence_id)


@router.get(
    "/residences/{residence_id}",
    summary="Get residence dashboard",
    description="Returns combined dashboard data while keeping compliance and performance separated.",
    responses=COMMON_ERROR_RESPONSES,
)
def get_residence_dashboard(residence_id: UUID, db: Session = Depends(get_db)):
    return dashboard_service.get_residence_dashboard(db, residence_id)


@router.get(
    "/residences/{residence_id}/trends",
    summary="Get residence trend history",
    description="Returns recent compliance and performance check history for dashboard charts.",
    responses=COMMON_ERROR_RESPONSES,
)
def get_residence_trends(
    residence_id: UUID,
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
):
    return dashboard_service.get_residence_trends(db, residence_id, limit=limit)


@router.get(
    "/residences/{residence_id}/export",
    summary="Get export-ready residence report",
    description="Returns a structured report payload ready for PDF/CSV generation by a client or worker.",
    responses=COMMON_ERROR_RESPONSES,
)
def get_export_ready_report(residence_id: UUID, db: Session = Depends(get_db)):
    return dashboard_service.get_export_ready_report(db, residence_id)
