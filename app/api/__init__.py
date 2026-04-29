from fastapi import APIRouter


from app.api.core.db_test import router as db_test_router
from app.api.media import router as media_router

# Core identity & users
from app.api.users.users import router as users_router
from app.api.users.staff import router as staff_router
from app.api.users.managers import router as managers_router
from app.api.users.caretakers import router as caretakers_router
from app.api.users.landlords import router as landlords_router
from app.api.users.tenants import router as tenants_router



# Locations & companies
from app.api.reference.locations import router as locations_router
from app.api.reference.companies import router as companies_router
from app.api.reference.institutions import router as institutions_router

# Residence structure
from app.api.residences.residences import router as residences_router
from app.api.residences.spaces import router as spaces_router
from app.api.residences.space_items import router as space_items_router
from app.api.residences.space_item_templates import router as space_item_templates_router
from app.api.residences.tenancies import router as tenancy_router

# Item & items
from app.api.items.categories import router as categories_router
from app.api.items.items import router as items_router


# Operations (core engine)
from app.api.operations.inspections import router as inspections_router
from app.api.operations.compliance import router as compliance_router

# Issues
from app.api.issues.issues import router as issues_router
from app.api.issues.common_issues import router as common_issues_router

# ==========================================================
# 🔗 API ROUTER
# ==========================================================
api_router = APIRouter(prefix="/api/v1")

# Identity & users
api_router.include_router(users_router)
api_router.include_router(staff_router)
api_router.include_router(managers_router)
api_router.include_router(caretakers_router)
api_router.include_router(landlords_router)
api_router.include_router(tenants_router)

# Locations & companies
api_router.include_router(locations_router)
api_router.include_router(companies_router)
api_router.include_router(institutions_router)

# Residence structure
api_router.include_router(residences_router)
api_router.include_router(spaces_router)
api_router.include_router(space_items_router)
api_router.include_router(space_item_templates_router)
api_router.include_router(tenancy_router)

# Item & items
api_router.include_router(categories_router)
api_router.include_router(items_router)
api_router.include_router(common_issues_router)

# Core operations
api_router.include_router(inspections_router)
api_router.include_router(compliance_router)
api_router.include_router(issues_router)
api_router.include_router(media_router)

api_router.include_router(db_test_router)
