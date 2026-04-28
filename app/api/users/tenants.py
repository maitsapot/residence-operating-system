from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

from app.core.database import get_db
from app.core.logger import get_logger

from app.models.tenant import Tenant
from app.models.user import User
from app.models.institution import Institution

from app.schemas.tenant import TenantCreate, TenantResponse

logger = get_logger(__name__)

router = APIRouter(prefix="/tenants", tags=["Tenants"])



@router.post("/", response_model=TenantResponse)
def create_tenant(payload: TenantCreate, db: Session = Depends(get_db)):

    logger.info(f"[START] Create tenant | user={payload.user_id}")

    try:
        # ===============================
        # USER EXISTS
        # ===============================
        user = db.query(User).filter(User.id == payload.user_id).first()

        if not user:
            raise HTTPException(404, "User not found")

        # ===============================
        # PREVENT DUPLICATE
        # ===============================
        existing = db.query(Tenant).filter(
            Tenant.user_id == payload.user_id
        ).first()

        if existing:
            raise HTTPException(400, "User already a tenant")

        # ===============================
        # BUSINESS RULE VALIDATION
        # ===============================
        if payload.is_student:
            if not payload.student_number or not payload.institution_id:
                raise HTTPException(
                    400,
                    "Student must have student_number and institution_id"
                )

            inst = db.query(Institution).filter(
                Institution.id == payload.institution_id
            ).first()

            if not inst:
                raise HTTPException(404, "Institution not found")

        else:
            # enforce clean data (optional but recommended)
            payload.student_number = None
            payload.institution_id = None

        # ===============================
        # CREATE
        # ===============================
        tenant = Tenant(**payload.model_dump())

        db.add(tenant)
        db.commit()
        db.refresh(tenant)

        logger.info("[SUCCESS] Tenant created")

        return tenant

    except HTTPException:
        db.rollback()
        raise

    except Exception:
        db.rollback()
        logger.error("Tenant creation failed", exc_info=True)
        raise HTTPException(500, "Internal server error")
    
    
@router.get("/", response_model=List[TenantResponse])
def get_tenants(db: Session = Depends(get_db)):

    logger.info("[START] Fetch tenants")

    tenants = db.query(Tenant).all()

    return tenants


@router.get("/{user_id}", response_model=TenantResponse)
def get_tenant(user_id: UUID, db: Session = Depends(get_db)):

    logger.info(f"[START] Fetch tenant | {user_id}")

    tenant = db.query(Tenant).filter(
        Tenant.user_id == user_id
    ).first()

    if not tenant:
        raise HTTPException(404, "Tenant not found")

    return tenant


# ===============================
# GET TENANTS BY RESIDENCE
# ===============================
@router.get("/by-residence/{residence_id}")
def get_tenants_by_residence(residence_id: UUID, db: Session = Depends(get_db)):

    logger.info(f"[START] Fetch tenants by residence | {residence_id}")

    try:
        from app.models.tenancy import Tenancy
        from app.models.space import Space

        results = (
            db.query(User)
            .join(Tenant, Tenant.user_id == User.id)
            .join(Tenancy, Tenancy.user_id == User.id)
            .join(Space, Space.id == Tenancy.space_id)
            .filter(Space.residence_id == residence_id)   # 🔥 FIX HERE
            .filter(Tenancy.status == "active")
            .all()
        )

        response = []

        for user in results:
            parts = [user.first_name, user.middle_name, user.last_name]
            full_name = " ".join([p for p in parts if p])

            response.append({
                "id": user.id,
                "full_name": full_name
            })

        logger.info(f"[SUCCESS] {len(response)} tenants found")

        return response

    except Exception:
        logger.error("Fetch tenants by residence failed", exc_info=True)
        raise HTTPException(500, "Internal server error")