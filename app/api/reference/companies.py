from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session, joinedload
from typing import List
from uuid import UUID

from app.core.database import get_db
from app.core.logger import get_logger

from app.models.company import Company
from app.models.location import Location

from app.schemas.company import CompanyCreate, CompanyResponse

logger = get_logger(__name__)

router = APIRouter(prefix="/companies", tags=["Companies"])


# ===============================
# CREATE COMPANY
# ===============================
@router.post("/", response_model=CompanyResponse)
def create_company(payload: CompanyCreate, db: Session = Depends(get_db)):

    logger.info("Creating company...")

    try:
        # -------------------------------
        # DUPLICATE CHECK
        # -------------------------------
        if payload.registration_number:
            existing = db.query(Company).filter(
                Company.registration_number == payload.registration_number
            ).first()

            if existing:
                logger.warning(f"Duplicate registration number: {payload.registration_number}")
                raise HTTPException(status_code=400, detail="Registration number already exists")

        # -------------------------------
        # CREATE LOCATION
        # -------------------------------
        location = Location(**payload.location.model_dump())
        db.add(location)
        db.flush()

        logger.info(f"Location created: {location.id}")

        # -------------------------------
        # CREATE COMPANY
        # -------------------------------
        company_data = payload.model_dump(exclude={"location"})

        company = Company(
            **company_data,
            location_id=location.id
        )

        db.add(company)

        db.commit()
        db.refresh(company)

        logger.info(f"Company created: {company.id}")

        return company

    except HTTPException as e:
        db.rollback()
        logger.warning(f"Business error: {e.detail}")
        raise

    except Exception:
        db.rollback()
        logger.error("Unexpected error while creating company", exc_info=True)
        raise HTTPException(status_code=500, detail="Internal server error")


# ===============================
# GET ALL COMPANIES
# ===============================
@router.get("/", response_model=List[CompanyResponse])
def get_companies(db: Session = Depends(get_db)):
    companies = db.query(Company).options(joinedload(Company.location)).all()
    return companies


# ===============================
# GET SINGLE COMPANY
# ===============================
@router.get("/{company_id}", response_model=CompanyResponse)
def get_company(company_id: UUID, db: Session = Depends(get_db)):

    company = (
        db.query(Company)
        .options(joinedload(Company.location))
        .filter(Company.id == company_id)
        .first()
    )

    if not company:
        raise HTTPException(status_code=404, detail="Company not found")

    return company