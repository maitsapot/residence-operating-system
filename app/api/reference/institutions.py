from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session, joinedload
from typing import List
from uuid import UUID

from app.core.database import get_db
from app.core.logger import get_logger

from app.models.institution import Institution
from app.models.location import Location

from app.schemas.institution import InstitutionCreate, InstitutionResponse

logger = get_logger(__name__)

router = APIRouter(prefix="/institutions", tags=["Institutions"])

@router.post("/", response_model=InstitutionResponse)
def create_institution(payload: InstitutionCreate, db: Session = Depends(get_db)):

    logger.info(f"[START] Create institution: {payload.name}")

    try:
        # ===============================
        # DUPLICATE CHECK
        # ===============================
        existing = db.query(Institution).filter(
            Institution.name == payload.name
        ).first()

        if existing:
            raise HTTPException(400, "Institution already exists")

        # ===============================
        # VALIDATE PARENT (IF PROVIDED)
        # ===============================
        if payload.parent_id:
            parent = db.query(Institution).filter(
                Institution.id == payload.parent_id
            ).first()

            if not parent:
                raise HTTPException(404, "Parent institution not found")

        # ===============================
        # CREATE LOCATION
        # ===============================
        location = Location(**payload.location.model_dump())

        db.add(location)
        db.flush()

        logger.info(f"[LOCATION CREATED] {location.id}")

        # ===============================
        # CREATE INSTITUTION
        # ===============================
        institution = Institution(
            name=payload.name,
            code=payload.code,
            institution_type=payload.institution_type,
            parent_id=payload.parent_id,
            location_id=location.id
        )

        db.add(institution)
        db.commit()
        db.refresh(institution)

        logger.info(f"[SUCCESS] Institution created: {institution.id}")

        return institution

    except HTTPException:
        db.rollback()
        raise

    except Exception:
        db.rollback()
        logger.error("Institution creation failed", exc_info=True)
        raise HTTPException(500, "Internal server error")
    
@router.get("/", response_model=List[InstitutionResponse])
def get_institutions(
    institution_type: str = None,
    parent_id: UUID = None,
    include_satellites: bool = True,
    db: Session = Depends(get_db),
):

    logger.info("[START] Fetch institutions")

    query = db.query(Institution).options(
        joinedload(Institution.location)
    )
    if institution_type:
        query = query.filter(Institution.institution_type == institution_type)
    if parent_id:
        query = query.filter(Institution.parent_id == parent_id)
    if not include_satellites:
        query = query.filter(Institution.parent_id.is_(None))

    institutions = query.order_by(Institution.name).all()

    return institutions


@router.get("/{institution_id}/satellites", response_model=List[InstitutionResponse])
def get_institution_satellites(institution_id: UUID, db: Session = Depends(get_db)):
    parent = db.query(Institution).filter(Institution.id == institution_id).first()
    if not parent:
        raise HTTPException(404, "Institution not found")

    return db.query(Institution).options(
        joinedload(Institution.location)
    ).filter(
        Institution.parent_id == institution_id
    ).order_by(Institution.name).all()


@router.get("/{institution_id}/network", response_model=List[InstitutionResponse])
def get_institution_network(institution_id: UUID, db: Session = Depends(get_db)):
    institution = db.query(Institution).filter(Institution.id == institution_id).first()
    if not institution:
        raise HTTPException(404, "Institution not found")

    root_id = institution.parent_id or institution.id
    return db.query(Institution).options(
        joinedload(Institution.location)
    ).filter(
        (Institution.id == root_id) | (Institution.parent_id == root_id)
    ).order_by(Institution.parent_id.nullsfirst(), Institution.name).all()


@router.get("/{institution_id}", response_model=InstitutionResponse)
def get_institution(institution_id: UUID, db: Session = Depends(get_db)):

    logger.info(f"[START] Fetch institution: {institution_id}")

    institution = db.query(Institution).options(
        joinedload(Institution.location)
    ).filter(
        Institution.id == institution_id
    ).first()

    if not institution:
        raise HTTPException(404, "Institution not found")

    return institution
