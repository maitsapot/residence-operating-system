from datetime import date
from uuid import UUID

from fastapi import HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.sql import func

from app.core.enums import TenancyStatus
from app.core.logger import get_logger
from app.models.space import Space
from app.models.tenancy import Tenancy
from app.models.tenant import Tenant as TenantProfile
from app.models.user import User
from app.schemas.tenancy import TenancyCreate

logger = get_logger(__name__)


def validate_date_range(start_date: date, end_date: date | None):
    if end_date and end_date < start_date:
        raise HTTPException(400, "end_date cannot be before start_date")


def ranges_overlap(
    first_start: date,
    first_end: date | None,
    second_start: date,
    second_end: date | None,
) -> bool:
    first_end_value = first_end or date.max
    second_end_value = second_end or date.max
    return first_start <= second_end_value and second_start <= first_end_value


def find_overlapping_active_tenancy(
    db: Session,
    *,
    user_id: UUID,
    space_id: UUID,
    start_date: date,
    end_date: date | None,
):
    active_tenancies = db.query(Tenancy).filter(
        Tenancy.status == "active",
        (
            (Tenancy.space_id == space_id)
            | (Tenancy.user_id == user_id)
        )
    ).all()

    for tenancy in active_tenancies:
        if ranges_overlap(
            tenancy.start_date,
            tenancy.end_date,
            start_date,
            end_date,
        ):
            return tenancy

    return None


def close_tenancy(
    tenancy: Tenancy,
    status: TenancyStatus,
    end_date: date | None,
):
    if tenancy.status != "active":
        raise HTTPException(400, "Only active tenancies can be closed")

    close_date = end_date or date.today()
    if close_date < tenancy.start_date:
        raise HTTPException(400, "end_date cannot be before start_date")

    tenancy.status = status
    tenancy.end_date = close_date
    tenancy.updated_at = func.now()


def create_tenancy(db: Session, payload: TenancyCreate):
    try:
        validate_date_range(payload.start_date, payload.end_date)

        user = db.query(User).filter(User.id == payload.user_id).first()
        if not user:
            raise HTTPException(404, "User not found")

        tenant = db.query(TenantProfile).filter(
            TenantProfile.user_id == payload.user_id
        ).first()
        if not tenant:
            raise HTTPException(400, "User is not registered as a tenant")

        space = db.query(Space).filter(Space.id == payload.space_id).first()
        if not space:
            raise HTTPException(404, "Space not found")

        if not space.is_rentable:
            raise HTTPException(400, "Space is not rentable")

        overlap = find_overlapping_active_tenancy(
            db,
            user_id=payload.user_id,
            space_id=payload.space_id,
            start_date=payload.start_date,
            end_date=payload.end_date,
        )
        if overlap:
            if overlap.space_id == payload.space_id:
                raise HTTPException(
                    400,
                    "Space already has an overlapping active tenancy"
                )

            raise HTTPException(
                400,
                "Tenant already has an overlapping active tenancy"
            )

        tenancy = Tenancy(**payload.model_dump())

        db.add(tenancy)
        db.commit()
        db.refresh(tenancy)

        logger.info(f"Tenancy created: {tenancy.id}")

        return tenancy

    except HTTPException:
        db.rollback()
        raise

    except Exception:
        db.rollback()
        logger.error("Error creating tenancy", exc_info=True)
        raise HTTPException(status_code=500, detail="Failed to create tenancy")


def get_tenancies(
    db: Session,
    *,
    offset: int = 0,
    limit: int = 50,
    status: TenancyStatus | None = None,
    user_id: UUID | None = None,
    space_id: UUID | None = None,
):
    query = db.query(Tenancy)
    if status:
        query = query.filter(Tenancy.status == status)
    if user_id:
        query = query.filter(Tenancy.user_id == user_id)
    if space_id:
        query = query.filter(Tenancy.space_id == space_id)
    return query.order_by(Tenancy.start_date.desc()).offset(offset).limit(limit).all()


def get_tenancy(db: Session, tenancy_id: UUID):
    tenancy = db.query(Tenancy).filter(Tenancy.id == tenancy_id).first()

    if not tenancy:
        raise HTTPException(status_code=404, detail="Tenancy not found")

    return tenancy


def terminate_tenancy(db: Session, tenancy_id: UUID, end_date: date | None = None):
    return update_tenancy_lifecycle(
        db=db,
        tenancy_id=tenancy_id,
        status="terminated",
        end_date=end_date,
        error_message="Failed to terminate tenancy",
        log_message="Error terminating tenancy",
    )


def complete_tenancy(db: Session, tenancy_id: UUID, end_date: date | None = None):
    return update_tenancy_lifecycle(
        db=db,
        tenancy_id=tenancy_id,
        status="completed",
        end_date=end_date,
        error_message="Failed to complete tenancy",
        log_message="Error completing tenancy",
    )


def update_tenancy_lifecycle(
    db: Session,
    tenancy_id: UUID,
    status: TenancyStatus,
    end_date: date | None,
    error_message: str,
    log_message: str,
):
    tenancy = get_tenancy(db, tenancy_id)

    try:
        close_tenancy(
            tenancy=tenancy,
            status=status,
            end_date=end_date,
        )

        db.commit()
        db.refresh(tenancy)

        return tenancy

    except HTTPException:
        db.rollback()
        raise

    except Exception:
        db.rollback()
        logger.error(log_message, exc_info=True)
        raise HTTPException(500, error_message)
