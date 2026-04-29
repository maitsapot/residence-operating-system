from typing import List
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.openapi import COMMON_ERROR_RESPONSES
from app.core.enums import InspectionStatus, InspectionType
from app.core.database import get_db
from app.schemas.inspection import (
    InspectionCreate,
    InspectionResponse,
    InspectionSignOff,
    InspectionUpdate,
)
from app.services import inspection as inspection_service
from app.services.inspection import (
    get_inspection_or_404,
    handle_inspection_issue,
    should_create_issue,
    validate_inspection_payload,
)

router = APIRouter(prefix="/inspections", tags=["Inspections"])

INSPECTION_EXAMPLE = {
    "id": "11111111-1111-1111-1111-111111111111",
    "space_item_id": "22222222-2222-2222-2222-222222222222",
    "inspected_by": "33333333-3333-3333-3333-333333333333",
    "condition": "damaged",
    "notes": "Desk surface is cracked.",
    "image_url": None,
    "inspection_type": "routine",
    "tenancy_id": "44444444-4444-4444-4444-444444444444",
    "inspector_signed_off": True,
    "tenant_signed_off": True,
    "status": "completed",
    "inspector_signature": "inspector-signature",
    "tenant_signature": "tenant-signature",
}


@router.post(
    "/",
    response_model=InspectionResponse,
    summary="Create inspection",
    description=(
        "Creates an inspection snapshot for a space item. Completed inspections "
        "must include both sign-offs and may create a maintenance issue when "
        "the inspection condition requires action."
    ),
    responses={
        200: {
            "description": "Inspection created.",
            "content": {"application/json": {"example": INSPECTION_EXAMPLE}},
        },
        **COMMON_ERROR_RESPONSES,
    },
)
def create_inspection(payload: InspectionCreate, db: Session = Depends(get_db)):
    return inspection_service.create_inspection(db, payload)


@router.get(
    "/",
    response_model=List[InspectionResponse],
    summary="List inspections",
    description="Returns all inspections ordered from newest to oldest.",
    responses={
        200: {
            "description": "Inspections returned.",
            "content": {"application/json": {"example": [INSPECTION_EXAMPLE]}},
        },
        **COMMON_ERROR_RESPONSES,
    },
)
def get_inspections(
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    status: InspectionStatus | None = None,
    inspection_type: InspectionType | None = None,
    inspected_by: UUID | None = None,
    db: Session = Depends(get_db),
):
    return inspection_service.get_inspections(
        db,
        offset=offset,
        limit=limit,
        status=status,
        inspection_type=inspection_type,
        inspected_by=inspected_by,
    )


@router.get(
    "/space/{space_id}",
    response_model=List[InspectionResponse],
    summary="List inspections by space",
    description="Returns inspections for all space items in a space.",
    responses={
        200: {
            "description": "Space inspections returned.",
            "content": {"application/json": {"example": [INSPECTION_EXAMPLE]}},
        },
        **COMMON_ERROR_RESPONSES,
    },
)
def get_inspections_by_space(
    space_id: UUID,
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    status: InspectionStatus | None = None,
    inspection_type: InspectionType | None = None,
    db: Session = Depends(get_db),
):
    return inspection_service.get_inspections_by_space(
        db,
        space_id,
        offset=offset,
        limit=limit,
        status=status,
        inspection_type=inspection_type,
    )


@router.get(
    "/tenancy/{tenancy_id}",
    response_model=List[InspectionResponse],
    summary="List inspections by tenancy",
    description="Returns inspections linked to a tenancy.",
    responses={
        200: {
            "description": "Tenancy inspections returned.",
            "content": {"application/json": {"example": [INSPECTION_EXAMPLE]}},
        },
        **COMMON_ERROR_RESPONSES,
    },
)
def get_inspections_by_tenancy(
    tenancy_id: UUID,
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    status: InspectionStatus | None = None,
    db: Session = Depends(get_db),
):
    return inspection_service.get_inspections_by_tenancy(
        db,
        tenancy_id,
        offset=offset,
        limit=limit,
        status=status,
    )


@router.get(
    "/residence/{residence_id}",
    response_model=List[InspectionResponse],
    summary="List inspections by residence",
    description="Returns inspections across all spaces in a residence.",
    responses={
        200: {
            "description": "Residence inspections returned.",
            "content": {"application/json": {"example": [INSPECTION_EXAMPLE]}},
        },
        **COMMON_ERROR_RESPONSES,
    },
)
def get_inspections_by_residence(
    residence_id: UUID,
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    status: InspectionStatus | None = None,
    inspection_type: InspectionType | None = None,
    db: Session = Depends(get_db),
):
    return inspection_service.get_inspections_by_residence(
        db,
        residence_id,
        offset=offset,
        limit=limit,
        status=status,
        inspection_type=inspection_type,
    )


@router.post(
    "/{inspection_id}/sign-off",
    response_model=InspectionResponse,
    summary="Sign off inspection",
    description=(
        "Records an inspector or tenant signature on a draft inspection. "
        "Completed inspections cannot be signed off again."
    ),
    responses={
        200: {
            "description": "Inspection sign-off recorded.",
            "content": {"application/json": {"example": INSPECTION_EXAMPLE}},
        },
        **COMMON_ERROR_RESPONSES,
    },
)
def sign_off_inspection(
    inspection_id: UUID,
    payload: InspectionSignOff,
    db: Session = Depends(get_db)
):
    return inspection_service.sign_off_inspection(db, inspection_id, payload)


@router.post(
    "/{inspection_id}/complete",
    response_model=InspectionResponse,
    summary="Complete inspection",
    description=(
        "Marks a draft inspection as completed after both sign-offs are present. "
        "Completion can trigger issue automation for poor or damaged conditions."
    ),
    responses={
        200: {
            "description": "Inspection completed.",
            "content": {"application/json": {"example": INSPECTION_EXAMPLE}},
        },
        **COMMON_ERROR_RESPONSES,
    },
)
def complete_inspection(inspection_id: UUID, db: Session = Depends(get_db)):
    return inspection_service.complete_inspection(db, inspection_id)


@router.patch(
    "/{inspection_id}",
    response_model=InspectionResponse,
    summary="Update inspection",
    description=(
        "Updates mutable fields on a draft inspection. Use the complete endpoint "
        "for completion instead of setting status directly."
    ),
    responses={
        200: {
            "description": "Inspection updated.",
            "content": {"application/json": {"example": INSPECTION_EXAMPLE}},
        },
        **COMMON_ERROR_RESPONSES,
    },
)
def update_inspection(
    inspection_id: UUID,
    payload: InspectionUpdate,
    db: Session = Depends(get_db)
):
    return inspection_service.update_inspection(db, inspection_id, payload)


@router.get(
    "/{inspection_id}",
    response_model=InspectionResponse,
    summary="Get inspection",
    description="Returns a single inspection by ID.",
    responses={
        200: {
            "description": "Inspection returned.",
            "content": {"application/json": {"example": INSPECTION_EXAMPLE}},
        },
        **COMMON_ERROR_RESPONSES,
    },
)
def get_inspection(inspection_id: UUID, db: Session = Depends(get_db)):
    return inspection_service.get_inspection(db, inspection_id)
