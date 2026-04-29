import uuid
from datetime import date

from app.api.issues.issues import update_issue_status
from app.api.operations.inspections import create_inspection
from app.api.residences.spaces import create_space
from app.api.residences.tenancies import create_tenancy
from app.models.item import Item
from app.models.category import Category
from app.models.common_issue import CommonIssue
from app.models.inspection import Inspection
from app.models.issue import Issue
from app.models.issue_update import IssueUpdate
from app.models.landlord import Landlord
from app.models.location import Location
from app.models.manager import Manager
from app.models.residence import Residence
from app.models.residence_landlords import ResidenceLandlord
from app.models.residence_manager import ResidenceManager
from app.models.space_item import SpaceItem
from app.models.space_item_template import SpaceItemTemplate
from app.models.tenant import Tenant
from app.models.tenancy import Tenancy
from app.models.user import User
from app.schemas.inspection import InspectionCreate
from app.schemas.space import SpaceCreate
from app.schemas.tenancy import TenancyCreate


def _location(**overrides):
    data = {
        "province": "Gauteng",
        "city": "Johannesburg",
        "suburb": "Braamfontein",
        "address_line_1": f"{uuid.uuid4()} Test Street",
    }
    data.update(overrides)
    return Location(**data)


def _user(location_id, **overrides):
    unique = uuid.uuid4().hex[:10]
    data = {
        "first_name": "Test",
        "last_name": "User",
        "email": f"{unique}@example.com",
        "cellphone": f"071{unique[:7]}",
        "date_of_birth": date(2000, 1, 1),
        "gender": "other",
        "race": "other",
        "location_id": location_id,
    }
    data.update(overrides)
    return User(**data)


def _seed_role_user(db_session, role_model):
    location = _location()
    db_session.add(location)
    db_session.flush()

    user = _user(location.id)
    db_session.add(user)
    db_session.flush()

    db_session.add(role_model(user_id=user.id))
    db_session.flush()

    return user


def _seed_residence(db_session):
    residence_location = _location()
    db_session.add(residence_location)
    db_session.flush()

    landlord_user = _seed_role_user(db_session, Landlord)
    manager_user = _seed_role_user(db_session, Manager)

    residence = Residence(
        name="Integration Residence",
        location_id=residence_location.id,
        total_rooms=1,
        total_capacity=1,
    )
    db_session.add(residence)
    db_session.flush()

    db_session.add(
        ResidenceLandlord(
            residence_id=residence.id,
            landlord_id=landlord_user.id,
        )
    )
    db_session.add(
        ResidenceManager(
            residence_id=residence.id,
            manager_id=manager_user.id,
            is_primary=True,
        )
    )
    db_session.flush()

    return residence, landlord_user, manager_user


def _seed_tenant_user(db_session):
    location = _location()
    db_session.add(location)
    db_session.flush()

    user = _user(location.id, first_name="Tenant")
    db_session.add(user)
    db_session.flush()

    db_session.add(Tenant(user_id=user.id, is_student=False))
    db_session.flush()

    return user


def _seed_item_template(db_session, *, space_type="room"):
    category = Category(category_name="furniture", is_trackable=True)
    db_session.add(category)
    db_session.flush()

    item = Item(
        category_id=category.id,
        name=f"Desk {uuid.uuid4()}",
        is_trackable=True,
    )
    db_session.add(item)
    db_session.flush()

    template = SpaceItemTemplate(
        template_type="single_room",
        standard="nsfas",
        space_type=space_type,
        item_id=item.id,
        default_quantity=1,
        is_required=True,
    )
    db_session.add(template)

    common_issue = CommonIssue(
        item_id=item.id,
        issue_name="Condition Issue",
        default_severity="medium",
        default_urgency="medium",
        is_active=True,
    )
    db_session.add(common_issue)
    db_session.flush()

    return item, template, common_issue


def test_space_template_generation_creates_required_space_items(db_session):
    residence, _landlord_user, _manager_user = _seed_residence(db_session)
    item, _template, _common_issue = _seed_item_template(db_session)

    payload = SpaceCreate(
        residence_id=residence.id,
        name="Room 101",
        space_type="room",
        is_rentable=True,
        capacity=1,
        template_type="single_room",
        standard="nsfas",
    )

    space = create_space(payload, db_session)

    space_items = db_session.query(SpaceItem).filter(
        SpaceItem.space_id == space.id
    ).all()

    assert len(space_items) == 1
    assert space_items[0].item_id == item.id
    assert space_items[0].is_required is True


def test_user_to_tenant_to_inspection_to_issue_flow(db_session):
    residence, _landlord_user, manager_user = _seed_residence(db_session)
    item, _template, common_issue = _seed_item_template(db_session)
    tenant_user = _seed_tenant_user(db_session)

    space = create_space(
        SpaceCreate(
            residence_id=residence.id,
            name="Room 102",
            space_type="room",
            is_rentable=True,
            capacity=1,
            template_type="single_room",
            standard="nsfas",
        ),
        db_session,
    )

    tenancy = create_tenancy(
        TenancyCreate(
            start_date=date(2026, 1, 1),
            user_id=tenant_user.id,
            space_id=space.id,
        ),
        db_session,
    )

    space_item = db_session.query(SpaceItem).filter(
        SpaceItem.space_id == space.id,
        SpaceItem.item_id == item.id,
    ).first()

    inspection = create_inspection(
        InspectionCreate(
            space_item_id=space_item.id,
            inspected_by=manager_user.id,
            condition="damaged",
            inspection_type="routine",
            tenancy_id=tenancy.id,
            inspector_signed_off=True,
            tenant_signed_off=True,
            status="completed",
        ),
        db_session,
    )

    issue = db_session.query(Issue).filter(
        Issue.inspection_id == inspection.id
    ).first()

    assert issue is not None
    assert issue.common_issue_id == common_issue.id
    assert issue.space_id == space.id
    assert issue.tenancy_id == tenancy.id
    assert issue.assigned_to == manager_user.id


def test_issue_status_transition_route_writes_audit_entries(db_session):
    residence, _landlord_user, manager_user = _seed_residence(db_session)
    item, _template, common_issue = _seed_item_template(db_session)
    tenant_user = _seed_tenant_user(db_session)

    space = create_space(
        SpaceCreate(
            residence_id=residence.id,
            name="Room 103",
            space_type="room",
            is_rentable=True,
            capacity=1,
            template_type="single_room",
            standard="nsfas",
        ),
        db_session,
    )
    space_item = db_session.query(SpaceItem).filter(
        SpaceItem.space_id == space.id,
        SpaceItem.item_id == item.id,
    ).first()

    issue = Issue(
        reported_by=tenant_user.id,
        assigned_to=manager_user.id,
        status="assigned",
        description="Desk is damaged",
        space_id=space.id,
        space_item_id=space_item.id,
        common_issue_id=common_issue.id,
        severity="medium",
        urgency="medium",
    )
    db_session.add(issue)
    db_session.commit()
    db_session.refresh(issue)

    update_issue_status(issue.id, "in_progress", manager_user.id, db_session)
    update_issue_status(issue.id, "resolved", manager_user.id, db_session)
    update_issue_status(issue.id, "closed", manager_user.id, db_session)

    db_session.refresh(issue)
    updates = db_session.query(IssueUpdate).filter(
        IssueUpdate.issue_id == issue.id
    ).all()

    assert issue.status == "closed"
    assert issue.resolved_at is not None
    assert [update.new_status for update in updates] == [
        "in_progress",
        "resolved",
        "closed",
    ]
