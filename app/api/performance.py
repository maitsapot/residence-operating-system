from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.openapi import COMMON_ERROR_RESPONSES
from app.core.database import get_db
from app.schemas.performance import (
    PerformanceCheckResponse,
    PerformanceFindingIssueCreate,
    PerformanceRatingCreate,
    PerformanceRatingResponse,
    PerformanceRatingSummary,
)
from app.services import performance as performance_service

router = APIRouter(prefix="/performance", tags=["Performance"])


@router.post(
    "/ratings",
    response_model=PerformanceRatingResponse,
    summary="Create performance rating",
    description=(
        "Records a performance rating for a space item, space, service, residence, "
        "contractor, vendor, or issue. Ratings are performance signals and do not "
        "change compliance scores."
    ),
    responses=COMMON_ERROR_RESPONSES,
)
def create_rating(payload: PerformanceRatingCreate, db: Session = Depends(get_db)):
    return performance_service.create_performance_rating(db, payload)


@router.get(
    "/ratings",
    response_model=list[PerformanceRatingResponse],
    summary="List performance ratings",
    description="Lists performance ratings with pagination and optional target/category filters.",
    responses=COMMON_ERROR_RESPONSES,
)
def list_ratings(
    target_type: str = None,
    target_id: UUID = None,
    rated_by: UUID = None,
    category: str = None,
    include_archived: bool = False,
    offset: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
):
    return performance_service.list_performance_ratings(
        db,
        target_type=target_type,
        target_id=target_id,
        rated_by=rated_by,
        category=category,
        include_archived=include_archived,
        offset=offset,
        limit=limit,
    )


@router.get(
    "/targets/{target_type}/{target_id}/ratings",
    response_model=list[PerformanceRatingResponse],
    summary="List target performance ratings",
    description="Lists active ratings for one performance target.",
    responses=COMMON_ERROR_RESPONSES,
)
def list_target_ratings(
    target_type: str,
    target_id: UUID,
    category: str = None,
    include_archived: bool = False,
    db: Session = Depends(get_db),
):
    return performance_service.get_target_ratings(
        db,
        target_type=target_type,
        target_id=target_id,
        category=category,
        include_archived=include_archived,
    )


@router.get(
    "/targets/{target_type}/{target_id}/ratings/summary",
    response_model=PerformanceRatingSummary,
    summary="Get target performance rating summary",
    description="Returns count and average rating for one performance target.",
    responses=COMMON_ERROR_RESPONSES,
)
def get_target_rating_summary(
    target_type: str,
    target_id: UUID,
    category: str = None,
    db: Session = Depends(get_db),
):
    return performance_service.get_target_rating_summary(
        db,
        target_type=target_type,
        target_id=target_id,
        category=category,
    )


@router.delete(
    "/ratings/{rating_id}",
    response_model=PerformanceRatingResponse,
    summary="Archive performance rating",
    description="Soft deletes a performance rating from active performance calculations.",
    responses=COMMON_ERROR_RESPONSES,
)
def archive_rating(rating_id: UUID, db: Session = Depends(get_db)):
    return performance_service.archive_performance_rating(db, rating_id)


@router.get(
    "/{scope_type}/{scope_id}",
    summary="Get performance report",
    description=(
        "Calculates performance from ratings, active issue backlog, SLA breaches, "
        "and inspection condition. This remains separate from compliance."
    ),
    responses=COMMON_ERROR_RESPONSES,
)
def get_performance_report(
    scope_type: str,
    scope_id: UUID,
    db: Session = Depends(get_db),
):
    return performance_service.get_performance_report(
        db,
        scope_type=scope_type,
        scope_id=scope_id,
    )


@router.post(
    "/{scope_type}/{scope_id}/calculate",
    summary="Run performance check",
    description="Calculates and persists an auditable performance check.",
    responses=COMMON_ERROR_RESPONSES,
)
def run_performance_check(
    scope_type: str,
    scope_id: UUID,
    db: Session = Depends(get_db),
):
    return performance_service.run_performance_check(
        db,
        scope_type=scope_type,
        scope_id=scope_id,
    )


@router.post(
    "/findings/{finding_id}/create-issue",
    summary="Create issue from performance finding",
    description=(
        "Creates an operational issue from an actionable performance finding and "
        "links the finding to the created issue. Repeated calls return the existing "
        "linked issue instead of creating duplicates."
    ),
    responses=COMMON_ERROR_RESPONSES,
)
def create_issue_from_finding(
    finding_id: UUID,
    payload: PerformanceFindingIssueCreate,
    db: Session = Depends(get_db),
):
    return performance_service.create_issue_from_performance_finding(
        db,
        finding_id=finding_id,
        reported_by=payload.reported_by,
        common_issue_id=payload.common_issue_id,
        space_id=payload.space_id,
        description=payload.description,
    )
