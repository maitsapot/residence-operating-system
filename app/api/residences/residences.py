from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session, joinedload
from typing import List
from uuid import UUID

from app.core.database import get_db
from app.core.logger import get_logger

from app.models.residence import Residence

from app.models.location import Location
from app.models.landlord import Landlord
from app.models.caretaker import Caretaker
from app.models.residence_staff import ResidenceStaff

from app.models.manager import Manager   # 🔥 FIXED (use manager table)


from app.schemas.residence import ResidenceCreate, ResidenceResponse

from sqlalchemy import insert

logger = get_logger(__name__)

router = APIRouter(prefix="/residences", tags=["Residences"])


# ===============================
# CREATE RESIDENCE
# ===============================
@router.post("/", response_model=ResidenceResponse)
def create_residence(payload: ResidenceCreate, db: Session = Depends(get_db)):

    logger.info(f"[START] Creating residence: {payload.name}")

    try:
        # ===============================
        # VALIDATION
        # ===============================
        if not payload.landlord_ids:
            logger.warning("Residence creation failed: no landlords provided")
            raise HTTPException(400, "Residence must have at least one landlord")

        logger.info(f"[VALIDATION] Landlords: {payload.landlord_ids}")

        landlords = db.query(Landlord).filter(
            Landlord.user_id.in_(payload.landlord_ids)
        ).all()

        if len(landlords) != len(set(payload.landlord_ids)):
            raise HTTPException(400, "Invalid landlord(s) provided")

        # ===============================
        # CREATE LOCATION
        # ===============================
        logger.info("[DB] Creating location")

        location = Location(**payload.location.model_dump())
        db.add(location)
        db.flush()

        logger.info(f"[SUCCESS] Location created: {location.id}")

        # ===============================
        # CREATE RESIDENCE
        # ===============================
        logger.info("[DB] Creating residence")

        residence_data = payload.model_dump(
            exclude={
                "location",
                "landlord_ids",
                "caretaker_ids",
                "manager_ids",
                "staff_ids"
            }
        )

        residence = Residence(
            **residence_data,
            location_id=location.id
        )

        db.add(residence)
        db.flush()

        logger.info(f"[SUCCESS] Residence created: {residence.id}")

        # ===============================
        # ASSIGN LANDLORDS
        # ===============================
        for landlord_id in payload.landlord_ids:
            db.execute(
                insert("residence_landlords").values(
                    residence_id=residence.id,
                    landlord_id=landlord_id
                )
            )

        # ===============================
        # ASSIGN CARETAKERS
        # ===============================
        if payload.caretaker_ids:
            logger.info(f"[ASSIGN] Caretakers: {payload.caretaker_ids}")

            caretakers = db.query(Caretaker).filter(
                Caretaker.user_id.in_(payload.caretaker_ids)
            ).all()

            if len(caretakers) != len(set(payload.caretaker_ids)):
                raise HTTPException(400, "Invalid caretaker(s)")

            for caretaker_id in payload.caretaker_ids:
                db.execute(
                    insert("residence_caretakers").values(
                        residence_id=residence.id,
                        caretaker_id=caretaker_id
                    )
                )

        # ===============================
        # ASSIGN MANAGERS (FIXED)
        # ===============================
        if payload.manager_ids:
            logger.info(f"[ASSIGN] Managers: {payload.manager_ids}")

            managers = db.query(Manager).filter(
                Manager.user_id.in_(payload.manager_ids)
            ).all()

            if len(managers) != len(set(payload.manager_ids)):
                raise HTTPException(400, "Invalid manager(s)")

            for manager_id in payload.manager_ids:
                db.execute(
                    insert("residence_managers").values(
                        residence_id=residence.id,
                        manager_id=manager_id
                    )
                )

        # ===============================
        # ASSIGN STAFF
        # ===============================
        if payload.staff_ids:
            logger.info(f"[ASSIGN] Staff: {payload.staff_ids}")

            staff = db.query(Staff).filter(
                Staff.id.in_(payload.staff_ids)
            ).all()

            if len(staff) != len(set(payload.staff_ids)):
                raise HTTPException(400, "Invalid staff")

            for staff_id in payload.staff_ids:
                db.execute(
                    insert("residence_staff").values(
                        residence_id=residence.id,
                        staff_id=staff_id
                    )
                )

        # ===============================
        # COMMIT
        # ===============================
        logger.info("[DB] Commit transaction")

        db.commit()
        db.refresh(residence)

        logger.info(f"[SUCCESS] Residence fully created: {residence.id}")

        return {
            "id": residence.id,
            "name": residence.name,
            "company_id": residence.company_id,
            "total_rooms": residence.total_rooms,
            "total_capacity": residence.total_capacity,
            "is_active": residence.is_active,
            "landlord_ids": payload.landlord_ids,
            "caretaker_ids": payload.caretaker_ids or [],
            "manager_ids": payload.manager_ids or [],
            "staff_ids": payload.staff_ids or [],
            "location": location
        }

    except HTTPException as e:
        db.rollback()
        logger.warning(f"[BUSINESS ERROR] {e.detail}")
        raise

    except Exception:
        db.rollback()
        logger.error("[SYSTEM ERROR] Failed to create residence", exc_info=True)
        raise HTTPException(500, "Internal server error")


# ===============================
# GET ALL
# ===============================
@router.get("/", response_model=List[ResidenceResponse])
def get_residences(db: Session = Depends(get_db)):

    logger.info("[START] Fetch residences")

    residences = db.query(Residence).options(
        joinedload(Residence.location)
    ).all()

    logger.info(f"[SUCCESS] {len(residences)} residences found")

    return residences


# ===============================
# GET ONE
# ===============================
@router.get("/{residence_id}", response_model=ResidenceResponse)
def get_residence(residence_id: UUID, db: Session = Depends(get_db)):

    logger.info(f"[START] Fetch residence: {residence_id}")

    residence = db.query(Residence).options(
        joinedload(Residence.location)
    ).filter(Residence.id == residence_id).first()

    if not residence:
        logger.warning("[BUSINESS ERROR] Residence not found")
        raise HTTPException(404, "Residence not found")

    logger.info("[SUCCESS] Residence found")

    return residence