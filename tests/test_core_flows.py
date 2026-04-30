import uuid
from datetime import date, datetime, timedelta, timezone

from app.api.issues.issues import update_issue_status
from app.api.operations.inspections import create_inspection
from app.api.residences.spaces import create_space
from app.api.residences.tenancies import create_tenancy
from app.models.item import Item
from app.models.category import Category
from app.models.common_issue import CommonIssue
from app.models.compliance import ComplianceCheck, ComplianceDocument, ComplianceFinding, ComplianceRule
from app.models.inspection import Inspection
from app.models.issue import Issue
from app.models.issue_update import IssueUpdate
from app.models.landlord import Landlord
from app.models.location import Location
from app.models.manager import Manager
from app.models.media import MediaAsset, MediaAttachment
from app.models.performance import PerformanceCheck, PerformanceFinding, PerformanceRating
from app.models.residence import Residence
from app.models.residence_landlords import ResidenceLandlord
from app.models.residence_manager import ResidenceManager
from app.models.service_catalog import ResidenceService, ServiceCatalog
from app.models.space import Space
from app.models.space_item import SpaceItem
from app.models.space_item_template import SpaceItemTemplate
from app.models.tenant import Tenant
from app.models.tenancy import Tenancy
from app.models.user import User
from app.schemas.inspection import InspectionCreate
from app.schemas.compliance import ComplianceDocumentCreate, ComplianceDocumentStatusUpdate
from app.schemas.performance import PerformanceRatingCreate
from app.schemas.service_catalog import ResidenceServiceCreate, ServiceCreate
from app.schemas.space import SpaceCreate
from app.schemas.tenancy import TenancyCreate
from app.services.documentation_compliance import (
    DEFAULT_REQUIRED_DOCUMENTS,
    attach_media_to_compliance_document,
    create_compliance_document,
    get_documentation_compliance_report,
    run_documentation_compliance_check,
    update_compliance_document_status,
)
from app.services.dashboard import (
    get_compliance_summary,
    get_export_ready_report,
    get_performance_summary,
    get_residence_dashboard,
    get_residence_trends,
)
from app.services.overall_compliance import (
    get_overall_compliance_report,
    run_overall_compliance_check,
)
from app.services.performance import (
    archive_performance_rating,
    create_performance_rating,
    create_issue_from_performance_finding,
    get_performance_report,
    get_target_rating_summary,
    list_performance_ratings,
    run_performance_check,
)
from app.services.service_catalog import (
    archive_residence_service,
    create_residence_service,
    create_service,
    get_service_performance_summary,
    list_residence_services,
    seed_core_services,
)
from app.services.residence_compliance import (
    get_residence_compliance_report,
    run_residence_compliance_check,
)
from app.services.room_compliance import (
    get_room_compliance_report,
    run_room_compliance_check,
    seed_room_compliance_rules,
)


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


def _seed_media_attachment(db_session, *, owner_type="residence", owner_id=None):
    owner_id = owner_id or uuid.uuid4()
    asset = MediaAsset(
        storage_provider="local",
        storage_key=f"storage/uploads/{uuid.uuid4()}.pdf",
        public_url="/api/v1/media/test/download",
        original_filename="certificate.pdf",
        content_type="application/pdf",
        file_extension="pdf",
        file_size=128,
        checksum_sha256=uuid.uuid4().hex,
        media_type="document",
        status="available",
        extra_metadata={},
    )
    db_session.add(asset)
    db_session.flush()

    attachment = MediaAttachment(
        asset_id=asset.id,
        owner_type=owner_type,
        owner_id=owner_id,
        purpose="compliance_document",
        visibility="internal",
    )
    db_session.add(attachment)
    db_session.flush()

    return attachment


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


def test_room_compliance_separates_required_inventory_from_performance(db_session):
    residence, _landlord_user, _manager_user = _seed_residence(db_session)
    item, _template, _common_issue = _seed_item_template(db_session)

    space = create_space(
        SpaceCreate(
            residence_id=residence.id,
            name="Room 104",
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
    space_item.condition = "damaged"
    db_session.commit()

    report = get_room_compliance_report(db_session, space.id)

    assert report["scope_type"] == "room"
    assert report["compliance"]["score"] == 100
    assert report["compliance_findings"] == []
    assert len(report["performance_indicators"]) == 1
    assert report["performance_indicators"][0]["condition"] == "damaged"


def test_room_compliance_rejects_shared_spaces(db_session):
    residence, _landlord_user, _manager_user = _seed_residence(db_session)

    space = Space(
        residence_id=residence.id,
        name="Kitchen 1",
        space_type="kitchen",
        is_rentable=False,
        capacity=0,
        template_type="single_room",
        standard="nsfas",
    )
    db_session.add(space)
    db_session.commit()

    try:
        get_room_compliance_report(db_session, space.id)
    except ValueError as exc:
        assert str(exc) == "Room compliance only applies to room spaces"
    else:
        raise AssertionError("Expected shared space to be rejected by room compliance")


def test_room_compliance_check_persists_auditable_snapshot(db_session):
    residence, _landlord_user, _manager_user = _seed_residence(db_session)
    _item, _template, _common_issue = _seed_item_template(db_session)

    space = Space(
        residence_id=residence.id,
        name="Room 105",
        space_type="room",
        is_rentable=True,
        capacity=1,
        template_type="single_room",
        standard="nsfas",
    )
    db_session.add(space)
    db_session.commit()

    report = run_room_compliance_check(db_session, space.id)

    check = db_session.query(ComplianceCheck).filter(
        ComplianceCheck.id == report["check_id"]
    ).first()
    findings = db_session.query(ComplianceFinding).filter(
        ComplianceFinding.check_id == check.id
    ).all()

    assert check is not None
    assert check.scope_type == "room"
    assert check.scope_id == space.id
    assert check.status == "fail"
    assert len(findings) == 1
    assert findings[0].finding_type == "missing_required_item"


def test_seed_room_compliance_rules_from_templates(db_session):
    _residence, _landlord_user, _manager_user = _seed_residence(db_session)
    item, _template, _common_issue = _seed_item_template(db_session)

    created = seed_room_compliance_rules(db_session)
    created_again = seed_room_compliance_rules(db_session)

    assert created == 1
    assert created_again == 0
    rule = db_session.query(ComplianceRule).filter(
        ComplianceRule.scope_type == "room",
        ComplianceRule.standard == "nsfas",
    ).first()
    assert rule is not None
    assert rule.requirements[0].item_id == item.id


def test_residence_compliance_requires_shared_spaces_and_assignments(db_session):
    residence, _landlord_user, _manager_user = _seed_residence(db_session)

    report = get_residence_compliance_report(db_session, residence.id)

    assert report["scope_type"] == "residence"
    assert report["compliance"]["status"] == "fail"
    finding_types = {finding["finding_type"] for finding in report["compliance_findings"]}
    assert "missing_required_space" in finding_types


def test_residence_compliance_check_persists_snapshot(db_session):
    residence, _landlord_user, _manager_user = _seed_residence(db_session)

    for name, space_type in [
        ("Kitchen 1", "kitchen"),
        ("Bathroom 1", "bathroom"),
        ("TV Room", "common"),
    ]:
        db_session.add(
            Space(
                residence_id=residence.id,
                name=name,
                space_type=space_type,
                is_rentable=False,
                capacity=0,
                template_type="single_room",
                standard="nsfas",
            )
        )
    db_session.commit()

    report = run_residence_compliance_check(db_session, residence.id)

    check = db_session.query(ComplianceCheck).filter(
        ComplianceCheck.id == report["check_id"]
    ).first()

    assert check is not None
    assert check.scope_type == "residence"
    assert check.status == "warning"
    assert report["shared_space_counts"]["kitchen"] == 1


def test_residence_compliance_applies_bathroom_capacity_ratio(db_session):
    residence, _landlord_user, _manager_user = _seed_residence(db_session)
    residence.total_capacity = 16
    db_session.add(
        Space(
            residence_id=residence.id,
            name="Bathroom 1",
            space_type="bathroom",
            is_rentable=False,
            capacity=0,
            template_type="single_room",
            standard="nsfas",
        )
    )
    db_session.commit()

    report = get_residence_compliance_report(db_session, residence.id)

    ratio_findings = report["ratio_findings"]
    assert len(ratio_findings) == 1
    assert ratio_findings[0]["finding_type"] == "ratio_failed"
    assert ratio_findings[0]["expected_value"] == "2"
    assert ratio_findings[0]["actual_value"] == "1"


def test_residence_compliance_checks_shared_space_required_items(db_session):
    residence, _landlord_user, _manager_user = _seed_residence(db_session)
    item, _template, _common_issue = _seed_item_template(db_session, space_type="kitchen")
    kitchen = Space(
        residence_id=residence.id,
        name="Kitchen Missing Item",
        space_type="kitchen",
        is_rentable=False,
        capacity=0,
        template_type="single_room",
        standard="nsfas",
    )
    db_session.add(kitchen)
    db_session.commit()

    report = get_residence_compliance_report(db_session, residence.id)

    shared_item_findings = report["shared_space_item_findings"]
    assert len(shared_item_findings) == 1
    assert shared_item_findings[0]["finding_type"] == "missing_required_item"
    assert item.name in shared_item_findings[0]["message"]


def test_documentation_compliance_reports_missing_required_documents(db_session):
    residence, _landlord_user, _manager_user = _seed_residence(db_session)

    report = get_documentation_compliance_report(db_session, residence.id)

    assert report["scope_type"] == "documentation"
    assert report["compliance"]["status"] == "fail"
    assert report["compliance"]["findings_count"] == len(DEFAULT_REQUIRED_DOCUMENTS)
    assert {finding["finding_type"] for finding in report["compliance_findings"]} == {
        "missing_document"
    }


def test_documentation_compliance_passes_approved_attached_valid_documents(db_session):
    residence, _landlord_user, _manager_user = _seed_residence(db_session)

    for requirement in DEFAULT_REQUIRED_DOCUMENTS:
        attachment = _seed_media_attachment(db_session, owner_id=residence.id)
        db_session.add(
            ComplianceDocument(
                residence_id=residence.id,
                document_type=requirement["document_type"],
                document_name=requirement["document_name"],
                status="approved",
                expires_at=date.today() + timedelta(days=365)
                if requirement["requires_expiry"]
                else None,
                media_attachment_id=attachment.id,
            )
        )
    db_session.commit()

    report = get_documentation_compliance_report(db_session, residence.id)

    assert report["compliance"]["status"] == "pass"
    assert report["compliance"]["score"] == 100
    assert report["compliance_findings"] == []


def test_documentation_compliance_flags_expired_and_rejected_documents(db_session):
    residence, _landlord_user, _manager_user = _seed_residence(db_session)
    expired_attachment = _seed_media_attachment(db_session, owner_id=residence.id)
    rejected_attachment = _seed_media_attachment(db_session, owner_id=residence.id)

    db_session.add(
        ComplianceDocument(
            residence_id=residence.id,
            document_type="fire_safety_certificate",
            document_name="Fire safety certificate",
            status="approved",
            expires_at=date.today() - timedelta(days=1),
            media_attachment_id=expired_attachment.id,
        )
    )
    db_session.add(
        ComplianceDocument(
            residence_id=residence.id,
            document_type="occupancy_certificate",
            document_name="Occupancy certificate",
            status="rejected",
            media_attachment_id=rejected_attachment.id,
        )
    )
    db_session.commit()

    report = get_documentation_compliance_report(db_session, residence.id)
    finding_types = {finding["finding_type"] for finding in report["compliance_findings"]}

    assert "expired_document" in finding_types
    assert "custom" in finding_types
    assert report["compliance"]["status"] == "fail"


def test_documentation_compliance_check_persists_snapshot(db_session):
    residence, _landlord_user, _manager_user = _seed_residence(db_session)

    report = run_documentation_compliance_check(db_session, residence.id)

    check = db_session.query(ComplianceCheck).filter(
        ComplianceCheck.id == report["check_id"]
    ).first()
    findings = db_session.query(ComplianceFinding).filter(
        ComplianceFinding.check_id == check.id
    ).all()

    assert check is not None
    assert check.scope_type == "documentation"
    assert check.scope_id == residence.id
    assert check.status == "fail"
    assert len(findings) == len(DEFAULT_REQUIRED_DOCUMENTS)


def test_compliance_document_workflow_links_media_and_updates_status(db_session):
    residence, _landlord_user, manager_user = _seed_residence(db_session)
    attachment = _seed_media_attachment(db_session, owner_id=residence.id)

    document = create_compliance_document(
        db_session,
        ComplianceDocumentCreate(
            residence_id=residence.id,
            document_type="fire_safety_certificate",
            document_name="Fire safety certificate",
            status="submitted",
            expires_at=date.today() + timedelta(days=365),
        ),
    )

    attached = attach_media_to_compliance_document(
        db_session,
        document_id=document.id,
        media_attachment_id=attachment.id,
    )
    approved = update_compliance_document_status(
        db_session,
        document_id=document.id,
        payload=ComplianceDocumentStatusUpdate(
            status="approved",
            verified_by=manager_user.id,
        ),
    )

    assert attached.media_attachment_id == attachment.id
    assert approved.status == "approved"
    assert approved.verified_by == manager_user.id
    assert approved.verified_at is not None


def test_overall_compliance_combines_room_residence_and_documentation(db_session):
    residence, _landlord_user, _manager_user = _seed_residence(db_session)
    _item, _template, _common_issue = _seed_item_template(db_session)

    create_space(
        SpaceCreate(
            residence_id=residence.id,
            name="Compliant Room",
            space_type="room",
            is_rentable=True,
            capacity=1,
            template_type="single_room",
            standard="nsfas",
        ),
        db_session,
    )
    for name, space_type in [
        ("Kitchen 1", "kitchen"),
        ("Bathroom 1", "bathroom"),
        ("TV Room", "common"),
    ]:
        db_session.add(
            Space(
                residence_id=residence.id,
                name=name,
                space_type=space_type,
                is_rentable=False,
                capacity=0,
                template_type="single_room",
                standard="nsfas",
            )
        )
    for requirement in DEFAULT_REQUIRED_DOCUMENTS:
        attachment = _seed_media_attachment(db_session, owner_id=residence.id)
        db_session.add(
            ComplianceDocument(
                residence_id=residence.id,
                document_type=requirement["document_type"],
                document_name=requirement["document_name"],
                status="approved",
                expires_at=date.today() + timedelta(days=365)
                if requirement["requires_expiry"]
                else None,
                media_attachment_id=attachment.id,
            )
        )
    db_session.commit()

    report = get_overall_compliance_report(db_session, residence.id)

    assert report["scope_type"] == "overall"
    assert report["components"]["room"]["score"] == 100
    assert report["components"]["documentation"]["score"] == 100
    assert report["compliance"]["score"] == 95.0
    assert report["compliance"]["status"] == "pass"
    assert "ratings" in report["performance"]["message"]


def test_overall_compliance_persists_snapshot(db_session):
    residence, _landlord_user, _manager_user = _seed_residence(db_session)

    report = run_overall_compliance_check(db_session, residence.id)

    check = db_session.query(ComplianceCheck).filter(
        ComplianceCheck.id == report["check_id"]
    ).first()
    findings = db_session.query(ComplianceFinding).filter(
        ComplianceFinding.check_id == check.id
    ).all()

    assert check is not None
    assert check.scope_type == "overall"
    assert check.scope_id == residence.id
    assert check.status == "fail"
    assert check.extra_metadata["weights"]["room"] == 40
    assert {finding.finding_type for finding in findings} == {"custom"}


def test_performance_rating_records_space_item_experience(db_session):
    residence, _landlord_user, _manager_user = _seed_residence(db_session)
    item, _template, _common_issue = _seed_item_template(db_session)
    tenant_user = _seed_tenant_user(db_session)
    space = create_space(
        SpaceCreate(
            residence_id=residence.id,
            name="Rated Room",
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

    rating = create_performance_rating(
        db_session,
        PerformanceRatingCreate(
            target_type="space_item",
            target_id=space_item.id,
            rated_by=tenant_user.id,
            rating=2,
            category="condition",
            comment="Chair is uncomfortable",
        ),
    )

    assert rating.id is not None
    assert rating.target_type == "space_item"
    assert rating.rating == 2
    assert db_session.query(PerformanceRating).count() == 1


def test_performance_rating_summary_averages_active_ratings(db_session):
    residence, _landlord_user, _manager_user = _seed_residence(db_session)
    tenant_user = _seed_tenant_user(db_session)

    for value in [4, 2]:
        create_performance_rating(
            db_session,
            PerformanceRatingCreate(
                target_type="residence",
                target_id=residence.id,
                rated_by=tenant_user.id,
                rating=value,
                category="overall",
            ),
        )

    summary = get_target_rating_summary(
        db_session,
        target_type="residence",
        target_id=residence.id,
    )

    assert summary["ratings_count"] == 2
    assert summary["average_rating"] == 3.0


def test_performance_rating_supports_media_and_archival(db_session):
    residence, _landlord_user, _manager_user = _seed_residence(db_session)
    tenant_user = _seed_tenant_user(db_session)
    attachment = _seed_media_attachment(db_session, owner_id=residence.id)

    rating = create_performance_rating(
        db_session,
        PerformanceRatingCreate(
            target_type="residence",
            target_id=residence.id,
            rated_by=tenant_user.id,
            rating=1,
            category="cleanliness",
            media_attachment_id=attachment.id,
        ),
    )
    archived = archive_performance_rating(db_session, rating.id)
    active = list_performance_ratings(db_session, target_type="residence", target_id=residence.id)
    all_ratings = list_performance_ratings(
        db_session,
        target_type="residence",
        target_id=residence.id,
        include_archived=True,
    )

    assert rating.media_attachment_id == attachment.id
    assert archived.archived_at is not None
    assert active == []
    assert len(all_ratings) == 1


def test_performance_rating_rejects_missing_known_target(db_session):
    tenant_user = _seed_tenant_user(db_session)

    try:
        create_performance_rating(
            db_session,
            PerformanceRatingCreate(
                target_type="space",
                target_id=uuid.uuid4(),
                rated_by=tenant_user.id,
                rating=3,
            ),
        )
    except Exception as exc:
        assert getattr(exc, "status_code", None) == 404
    else:
        raise AssertionError("Expected rating creation to reject missing target")


def test_seed_core_services_creates_default_service_catalog(db_session):
    created = seed_core_services(db_session)
    created_again = seed_core_services(db_session)

    names = {
        service.name
        for service in db_session.query(ServiceCatalog).all()
    }

    assert created == 5
    assert created_again == 0
    assert {"cleaning", "wifi", "security", "laundry", "maintenance"} <= names


def test_residence_service_assignment_and_listing(db_session):
    residence, _landlord_user, _manager_user = _seed_residence(db_session)
    service = create_service(
        db_session,
        ServiceCreate(name=f"cleaning-{uuid.uuid4()}", description="Cleaning service"),
    )

    residence_service = create_residence_service(
        db_session,
        ResidenceServiceCreate(
            residence_id=residence.id,
            service_id=service.id,
            provider_type="internal",
            status="active",
        ),
    )
    listed = list_residence_services(db_session, residence_id=residence.id)

    assert residence_service.service.name == service.name
    assert listed[0].id == residence_service.id
    assert listed[0].status == "active"


def test_service_performance_summary_uses_service_ratings(db_session):
    residence, _landlord_user, _manager_user = _seed_residence(db_session)
    tenant_user = _seed_tenant_user(db_session)
    service = create_service(
        db_session,
        ServiceCreate(name=f"wifi-{uuid.uuid4()}", description="Wi-Fi"),
    )
    residence_service = create_residence_service(
        db_session,
        ResidenceServiceCreate(
            residence_id=residence.id,
            service_id=service.id,
        ),
    )

    for value in [5, 3]:
        create_performance_rating(
            db_session,
            PerformanceRatingCreate(
                target_type="service",
                target_id=residence_service.id,
                rated_by=tenant_user.id,
                rating=value,
                category="quality",
            ),
        )

    summary = get_service_performance_summary(db_session, residence_service.id)

    assert summary["service_name"] == service.name
    assert summary["ratings_count"] == 2
    assert summary["average_rating"] == 4.0


def test_residence_service_archival_removes_from_active_list(db_session):
    residence, _landlord_user, _manager_user = _seed_residence(db_session)
    service = create_service(
        db_session,
        ServiceCreate(name=f"security-{uuid.uuid4()}"),
    )
    residence_service = create_residence_service(
        db_session,
        ResidenceServiceCreate(
            residence_id=residence.id,
            service_id=service.id,
        ),
    )

    archived = archive_residence_service(db_session, residence_service.id)
    active = list_residence_services(db_session, residence_id=residence.id)
    all_services = list_residence_services(
        db_session,
        residence_id=residence.id,
        include_archived=True,
    )

    assert archived.archived_at is not None
    assert archived.status == "ended"
    assert active == []
    assert len(all_services) == 1


def test_performance_report_aggregates_ratings_for_residence(db_session):
    residence, _landlord_user, _manager_user = _seed_residence(db_session)
    tenant_user = _seed_tenant_user(db_session)

    for value in [5, 3]:
        create_performance_rating(
            db_session,
            PerformanceRatingCreate(
                target_type="residence",
                target_id=residence.id,
                rated_by=tenant_user.id,
                rating=value,
                category="overall",
            ),
        )

    report = get_performance_report(
        db_session,
        scope_type="residence",
        scope_id=residence.id,
    )

    assert report["performance"]["score"] == 89.33
    assert report["performance"]["status"] == "good"
    assert report["signals"]["ratings"]["average_rating"] == 4.0
    assert report["signals"]["issues"]["open_issues"] == 0


def test_performance_report_flags_issue_backlog_and_sla_breaches(db_session):
    residence, _landlord_user, manager_user = _seed_residence(db_session)
    item, _template, common_issue = _seed_item_template(db_session)
    tenant_user = _seed_tenant_user(db_session)
    space = create_space(
        SpaceCreate(
            residence_id=residence.id,
            name="Issue Heavy Room",
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

    for index in range(5):
        db_session.add(
            Issue(
                reported_by=tenant_user.id,
                assigned_to=manager_user.id,
                status="assigned",
                due_at=datetime.now(timezone.utc) - timedelta(days=1),
                description=f"Backlog issue {index}",
                space_id=space.id,
                space_item_id=space_item.id,
                common_issue_id=common_issue.id,
                severity="critical" if index == 0 else "medium",
                urgency="urgent",
            )
        )
    db_session.commit()

    report = get_performance_report(db_session, scope_type="space", scope_id=space.id)
    finding_types = {finding["finding_type"] for finding in report["performance_findings"]}

    assert report["signals"]["issues"]["open_issues"] == 5
    assert report["signals"]["issues"]["sla_breaches"] == 5
    assert "high_backlog" in finding_types
    assert "sla_breach" in finding_types
    assert report["performance"]["status"] == "critical"


def test_performance_report_uses_inspection_condition_signal(db_session):
    residence, _landlord_user, manager_user = _seed_residence(db_session)
    item, _template, _common_issue = _seed_item_template(db_session)
    tenant_user = _seed_tenant_user(db_session)
    space = create_space(
        SpaceCreate(
            residence_id=residence.id,
            name="Inspected Room",
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
    db_session.add(
        Inspection(
            space_item_id=space_item.id,
            inspected_by=manager_user.id,
            tenancy_id=None,
            condition="damaged",
            inspection_type="routine",
            status="completed",
            inspector_signed_off=True,
            tenant_signed_off=False,
        )
    )
    db_session.commit()

    report = get_performance_report(db_session, scope_type="space", scope_id=space.id)

    assert report["signals"]["inspections"]["score"] == 20
    assert report["signals"]["inspections"]["condition_counts"]["damaged"] == 1
    assert report["performance_findings"][0]["finding_type"] == "inspection_condition"


def test_performance_check_persists_snapshot_and_findings(db_session):
    residence, _landlord_user, _manager_user = _seed_residence(db_session)
    tenant_user = _seed_tenant_user(db_session)
    create_performance_rating(
        db_session,
        PerformanceRatingCreate(
            target_type="residence",
            target_id=residence.id,
            rated_by=tenant_user.id,
            rating=1,
            category="overall",
        ),
    )

    report = run_performance_check(
        db_session,
        scope_type="residence",
        scope_id=residence.id,
    )

    check = db_session.query(PerformanceCheck).filter(
        PerformanceCheck.id == report["check_id"]
    ).first()
    findings = db_session.query(PerformanceFinding).filter(
        PerformanceFinding.check_id == check.id
    ).all()

    assert check is not None
    assert check.scope_type == "residence"
    assert check.status == "degraded"
    assert check.extra_metadata["signals"]["ratings"]["average_rating"] == 1.0
    assert len(findings) == 1
    assert findings[0].finding_type == "low_rating"


def test_performance_finding_creates_issue_and_prevents_duplicates(db_session):
    residence, _landlord_user, manager_user = _seed_residence(db_session)
    item, _template, common_issue = _seed_item_template(db_session)
    tenant_user = _seed_tenant_user(db_session)
    space = create_space(
        SpaceCreate(
            residence_id=residence.id,
            name="Performance Issue Room",
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
    db_session.add(
        Inspection(
            space_item_id=space_item.id,
            inspected_by=manager_user.id,
            condition="damaged",
            inspection_type="routine",
            status="completed",
            inspector_signed_off=True,
        )
    )
    db_session.commit()

    report = run_performance_check(db_session, scope_type="space", scope_id=space.id)
    finding = db_session.query(PerformanceFinding).filter(
        PerformanceFinding.check_id == report["check_id"],
        PerformanceFinding.finding_type == "inspection_condition",
    ).first()

    first = create_issue_from_performance_finding(
        db_session,
        finding_id=finding.id,
        reported_by=tenant_user.id,
    )
    second = create_issue_from_performance_finding(
        db_session,
        finding_id=finding.id,
        reported_by=tenant_user.id,
    )

    db_session.refresh(finding)
    issues = db_session.query(Issue).filter(Issue.space_id == space.id).all()

    assert first["created"] is True
    assert second["created"] is False
    assert second["issue"].id == first["issue"].id
    assert finding.created_issue_id == first["issue"].id
    assert len(issues) == 1
    assert issues[0].common_issue_id == common_issue.id
    assert issues[0].space_item_id == space_item.id


def test_resolved_performance_issue_improves_future_issue_signal(db_session):
    residence, _landlord_user, manager_user = _seed_residence(db_session)
    item, _template, common_issue = _seed_item_template(db_session)
    tenant_user = _seed_tenant_user(db_session)
    space = create_space(
        SpaceCreate(
            residence_id=residence.id,
            name="Resolved Performance Room",
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
        due_at=datetime.now(timezone.utc) - timedelta(days=1),
        description="Performance issue",
        space_id=space.id,
        space_item_id=space_item.id,
        common_issue_id=common_issue.id,
        severity="critical",
        urgency="urgent",
    )
    db_session.add(issue)
    db_session.commit()

    before = get_performance_report(db_session, scope_type="space", scope_id=space.id)
    issue.status = "resolved"
    issue.resolved_at = datetime.now(timezone.utc)
    db_session.commit()
    after = get_performance_report(db_session, scope_type="space", scope_id=space.id)

    assert before["signals"]["issues"]["open_issues"] == 1
    assert before["signals"]["issues"]["sla_breaches"] == 1
    assert after["signals"]["issues"]["open_issues"] == 0
    assert after["signals"]["issues"]["sla_breaches"] == 0
    assert after["signals"]["issues"]["score"] == 100


def test_dashboard_compliance_summary_uses_latest_checks(db_session):
    residence, _landlord_user, _manager_user = _seed_residence(db_session)
    db_session.add(
        ComplianceCheck(
            scope_type="overall",
            scope_id=residence.id,
            standard="nsfas",
            score=82,
            status="warning",
            summary="Overall warning",
        )
    )
    db_session.add(
        ComplianceCheck(
            scope_type="documentation",
            scope_id=residence.id,
            standard="nsfas",
            score=100,
            status="pass",
            summary="Documents pass",
        )
    )
    db_session.commit()

    summary = get_compliance_summary(db_session, residence.id)

    assert summary["summary_type"] == "compliance"
    assert summary["components"]["overall"]["score"] == 82.0
    assert summary["components"]["documentation"]["status"] == "pass"
    assert "Compliance summary" in summary["message"]


def test_dashboard_performance_summary_uses_checks_and_active_issues(db_session):
    residence, _landlord_user, manager_user = _seed_residence(db_session)
    item, _template, common_issue = _seed_item_template(db_session)
    tenant_user = _seed_tenant_user(db_session)
    space = create_space(
        SpaceCreate(
            residence_id=residence.id,
            name="Dashboard Room",
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
    db_session.add(
        PerformanceCheck(
            scope_type="residence",
            scope_id=residence.id,
            score=71,
            status="degraded",
            summary="Residence degraded",
            extra_metadata={},
        )
    )
    db_session.add(
        Issue(
            reported_by=tenant_user.id,
            assigned_to=manager_user.id,
            status="assigned",
            description="Open dashboard issue",
            space_id=space.id,
            space_item_id=space_item.id,
            common_issue_id=common_issue.id,
            severity="medium",
            urgency="medium",
        )
    )
    db_session.commit()

    summary = get_performance_summary(db_session, residence.id)

    assert summary["summary_type"] == "performance"
    assert summary["components"]["residence"]["score"] == 71.0
    assert summary["active_issues"] == 1
    assert "Performance summary" in summary["message"]


def test_dashboard_trends_and_export_report_are_separated(db_session):
    residence, _landlord_user, _manager_user = _seed_residence(db_session)
    db_session.add(
        ComplianceCheck(
            scope_type="overall",
            scope_id=residence.id,
            standard="nsfas",
            score=90,
            status="pass",
            summary="Overall pass",
        )
    )
    db_session.add(
        PerformanceCheck(
            scope_type="residence",
            scope_id=residence.id,
            score=78,
            status="good",
            summary="Performance good",
            extra_metadata={},
        )
    )
    db_session.commit()

    dashboard = get_residence_dashboard(db_session, residence.id)
    trends = get_residence_trends(db_session, residence.id)
    export = get_export_ready_report(db_session, residence.id)

    assert dashboard["compliance"]["components"]["overall"]["status"] == "pass"
    assert dashboard["performance"]["components"]["residence"]["status"] == "good"
    assert len(trends["compliance"]) == 1
    assert len(trends["performance"]) == 1
    assert export["report_type"] == "residence_compliance_performance"
    assert "compliance_summary" in export["sections"]
    assert "performance_summary" in export["sections"]
