from typing import List
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.openapi import COMMON_ERROR_RESPONSES
from app.core.database import get_db
from app.core.enums import TenancyStatus
from app.schemas.tenancy import (
    TenancyCreate,
    TenancyLifecycleUpdate,
    TenancyResponse,
)
from app.services import tenancy as tenancy_service

router = APIRouter(prefix="/tenancies", tags=["Tenancies"])

TENANCY_EXAMPLE = {
    "id": "11111111-1111-1111-1111-111111111111",
    "start_date": "2026-01-01",
    "end_date": None,
    "status": "active",
    "user_id": "22222222-2222-2222-2222-222222222222",
    "space_id": "33333333-3333-3333-3333-333333333333",
}


@router.post(
    "/",
    response_model=TenancyResponse,
    summary="Create tenancy",
    description=(
        "Creates an active tenancy for a registered tenant in a rentable space. "
        "The service rejects invalid date ranges and overlapping active tenancies "
        "for the tenant or space."
    ),
    responses={
        200: {
            "description": "Tenancy created.",
            "content": {"application/json": {"example": TENANCY_EXAMPLE}},
        },
        **COMMON_ERROR_RESPONSES,
    },
)
def create_tenancy(payload: TenancyCreate, db: Session = Depends(get_db)):
    return tenancy_service.create_tenancy(db, payload)


@router.get(
    "/",
    response_model=List[TenancyResponse],
    summary="List tenancies",
    description="Returns all tenancy records.",
    responses={
        200: {
            "description": "Tenancies returned.",
            "content": {"application/json": {"example": [TENANCY_EXAMPLE]}},
        },
        **COMMON_ERROR_RESPONSES,
    },
)
def get_tenancies(
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    status: TenancyStatus | None = None,
    user_id: UUID | None = None,
    space_id: UUID | None = None,
    db: Session = Depends(get_db),
):
    return tenancy_service.get_tenancies(
        db,
        offset=offset,
        limit=limit,
        status=status,
        user_id=user_id,
        space_id=space_id,
    )


@router.get(
    "/{tenancy_id}",
    response_model=TenancyResponse,
    summary="Get tenancy",
    description="Returns a single tenancy by ID.",
    responses={
        200: {
            "description": "Tenancy returned.",
            "content": {"application/json": {"example": TENANCY_EXAMPLE}},
        },
        **COMMON_ERROR_RESPONSES,
    },
)
def get_tenancy(tenancy_id: UUID, db: Session = Depends(get_db)):
    return tenancy_service.get_tenancy(db, tenancy_id)


@router.post(
    "/{tenancy_id}/terminate",
    response_model=TenancyResponse,
    summary="Terminate tenancy",
    description=(
        "Closes an active tenancy with status terminated. If no end date is "
        "provided, the current date is used."
    ),
    responses={
        200: {
            "description": "Tenancy terminated.",
            "content": {
                "application/json": {
                    "example": {**TENANCY_EXAMPLE, "status": "terminated", "end_date": "2026-04-29"}
                }
            },
        },
        **COMMON_ERROR_RESPONSES,
    },
)
def terminate_tenancy(
    tenancy_id: UUID,
    payload: TenancyLifecycleUpdate | None = None,
    db: Session = Depends(get_db)
):
    return tenancy_service.terminate_tenancy(
        db=db,
        tenancy_id=tenancy_id,
        end_date=payload.end_date if payload else None,
    )


@router.post(
    "/{tenancy_id}/complete",
    response_model=TenancyResponse,
    summary="Complete tenancy",
    description=(
        "Closes an active tenancy with status completed. If no end date is "
        "provided, the current date is used."
    ),
    responses={
        200: {
            "description": "Tenancy completed.",
            "content": {
                "application/json": {
                    "example": {**TENANCY_EXAMPLE, "status": "completed", "end_date": "2026-04-29"}
                }
            },
        },
        **COMMON_ERROR_RESPONSES,
    },
)
def complete_tenancy(
    tenancy_id: UUID,
    payload: TenancyLifecycleUpdate | None = None,
    db: Session = Depends(get_db)
):
    return tenancy_service.complete_tenancy(
        db=db,
        tenancy_id=tenancy_id,
        end_date=payload.end_date if payload else None,
    )
