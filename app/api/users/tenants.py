from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID
import re

from app.core.database import get_db
from app.core.logger import get_logger

from app.models.tenant import Tenant
from app.models.user import User
from app.models.institution import Institution

from app.schemas.tenant import TenantCreate, TenantResponse

logger = get_logger(__name__)

router = APIRouter(prefix="/tenants", tags=["Tenants"])

SEED_NAME_RE = re.compile(r"^seed\d+$", re.IGNORECASE)


def _tenant_full_name(user: User) -> str:
    parts = [user.first_name, user.middle_name, user.last_name]
    visible_parts = [
        part.strip()
        for part in parts
        if part and part.strip() and not SEED_NAME_RE.match(part.strip())
    ]
    return " ".join(visible_parts) or "Tenant"



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

        contact_user_ids = {
            "emergency_contact_user_id": payload.emergency_contact_user_id,
            "guardian_user_id": payload.guardian_user_id,
            "authorized_proxy_user_id": payload.authorized_proxy_user_id,
        }
        contact_user_ids = {
            field: user_id
            for field, user_id in contact_user_ids.items()
            if user_id is not None
        }

        if payload.user_id in contact_user_ids.values():
            raise HTTPException(400, "Tenant contact references must point to another user")

        if contact_user_ids:
            found_contact_ids = {
                row[0]
                for row in db.query(User.id)
                .filter(User.id.in_(contact_user_ids.values()))
                .all()
            }
            missing_fields = [
                field
                for field, user_id in contact_user_ids.items()
                if user_id not in found_contact_ids
            ]
            if missing_fields:
                raise HTTPException(
                    404,
                    f"Contact user not found for: {', '.join(missing_fields)}"
                )

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
            response.append({
                "id": user.id,
                "full_name": _tenant_full_name(user)
            })

        logger.info(f"[SUCCESS] {len(response)} tenants found")

        return response

    except Exception:
        logger.error("Fetch tenants by residence failed", exc_info=True)
        raise HTTPException(500, "Internal server error")


@router.get("/{user_id}", response_model=TenantResponse)
def get_tenant(user_id: UUID, db: Session = Depends(get_db)):

    logger.info(f"[START] Fetch tenant | {user_id}")

    tenant = db.query(Tenant).filter(
        Tenant.user_id == user_id
    ).first()

    if not tenant:
        raise HTTPException(404, "Tenant not found")

    return tenant
