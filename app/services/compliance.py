from uuid import UUID

from sqlalchemy.sql import func
from sqlalchemy.orm import Session

from app.models.item import Item
from app.models.common_issue import CommonIssue
from app.models.issue import Issue
from app.models.issue_update import IssueUpdate
from app.models.residence_manager import ResidenceManager
from app.models.space import Space
from app.models.space_item import SpaceItem
from app.models.space_item_template import SpaceItemTemplate
from app.models.tenancy import Tenancy


def _get_primary_manager_id(db: Session, residence_id: UUID):
    primary_manager = db.query(ResidenceManager).filter(
        ResidenceManager.residence_id == residence_id,
        ResidenceManager.is_primary == True
    ).first()

    if primary_manager:
        return primary_manager.manager_id

    fallback_manager = db.query(ResidenceManager).filter(
        ResidenceManager.residence_id == residence_id
    ).first()

    return fallback_manager.manager_id if fallback_manager else None


def get_space_compliance_report(
    db: Session,
    space_id: UUID,
    template_type: str = "single_room",
    standard: str = "nsfas"
) -> dict:
    space = db.query(Space).filter(Space.id == space_id).first()
    if not space:
        raise ValueError("Space not found")

    templates = db.query(SpaceItemTemplate, Item).join(
        Item,
        Item.id == SpaceItemTemplate.item_id
    ).filter(
        SpaceItemTemplate.space_type == space.space_type,
        SpaceItemTemplate.template_type == template_type,
        SpaceItemTemplate.standard == standard,
        SpaceItemTemplate.is_required == True
    ).all()

    space_items = db.query(SpaceItem, Item).join(
        Item,
        Item.id == SpaceItem.item_id
    ).filter(
        SpaceItem.space_id == space_id
    ).all()

    item_by_item_id = {
        space_item.item_id: (space_item, item)
        for space_item, item in space_items
    }
    template_item_ids = {
        template.item_id
        for template, _item in templates
    }

    missing_items = []
    bad_items = []

    for template, item in templates:
        item_entry = item_by_item_id.get(template.item_id)

        if not item_entry:
            missing_items.append({
                "item_id": template.item_id,
                "item_name": item.name,
                "required_quantity": template.default_quantity
            })
            continue

        space_item, _item_item = item_entry
        if space_item.condition != "good" or space_item.status != "active":
            bad_items.append({
                "space_item_id": space_item.id,
                "item_id": space_item.item_id,
                "item_name": item.name,
                "condition": space_item.condition,
                "status": space_item.status,
                "quantity": space_item.quantity
            })

    extra_items = [
        {
            "space_item_id": space_item.id,
            "item_id": space_item.item_id,
            "item_name": item.name,
            "condition": space_item.condition,
            "status": space_item.status,
            "quantity": space_item.quantity
        }
        for space_item, item in space_items
        if space_item.item_id not in template_item_ids
    ]

    total_required = len(templates)
    missing_count = len(missing_items)
    bad_count = len(bad_items)
    compliant_count = max(total_required - missing_count - bad_count, 0)
    compliance_percentage = (
        round((compliant_count / total_required) * 100, 2)
        if total_required
        else 100
    )

    return {
        "space_id": space_id,
        "template_type": template_type,
        "standard": standard,
        "missing_items": missing_items,
        "extra_items": extra_items,
        "bad_items": bad_items,
        "score": {
            "total_required": total_required,
            "compliant_items": compliant_count,
            "missing_items": missing_count,
            "bad_items": bad_count,
            "extra_items": len(extra_items),
            "compliance_percentage": compliance_percentage
        }
    }


def fetch_space_compliance(
    db: Session,
    space_id: UUID,
    template_type: str = "single_room",
    standard: str = "nsfas"
):
    return get_space_compliance_report(
        db=db,
        space_id=space_id,
        template_type=template_type,
        standard=standard
    )


def generate_issues_from_space(
    db: Session,
    space_id: UUID,
    template_type: str = "single_room",
    standard: str = "nsfas",
    reported_by: UUID = None
) -> int:
    if not reported_by:
        raise ValueError("reported_by is required")

    space = db.query(Space).filter(Space.id == space_id).first()
    if not space:
        raise ValueError("Space not found")

    active_tenancy = db.query(Tenancy).filter(
        Tenancy.space_id == space_id,
        Tenancy.status == "active"
    ).first()

    assigned_to = _get_primary_manager_id(db, space.residence_id)

    bad_items = db.query(
        SpaceItem,
        Item.name.label("item_name"),
        CommonIssue
    ).join(
        Item,
        Item.id == SpaceItem.item_id
    ).join(
        SpaceItemTemplate,
        (SpaceItemTemplate.item_id == SpaceItem.item_id)
        & (SpaceItemTemplate.space_type == "room")
        & (SpaceItemTemplate.template_type == template_type)
        & (SpaceItemTemplate.standard == standard)
        & (SpaceItemTemplate.is_required == True)
    ).join(
        CommonIssue,
        (CommonIssue.item_id == SpaceItem.item_id)
        & (CommonIssue.issue_name == "Condition Issue")
        & (CommonIssue.is_active == True)
    ).filter(
        SpaceItem.space_id == space_id,
        (
            (SpaceItem.condition != "good")
            | (SpaceItem.status != "active")
        )
    ).all()

    issues_created = 0

    for space_item, item_name, common_issue in bad_items:
        existing_issue = db.query(Issue).filter(
            Issue.space_item_id == space_item.id,
            Issue.common_issue_id == common_issue.id,
            Issue.status.in_(["open", "assigned", "in_progress"])
        ).first()

        if existing_issue:
            continue

        status = "assigned" if assigned_to else "open"
        issue = Issue(
            reported_by=reported_by,
            assigned_to=assigned_to,
            status=status,
            description=(
                f"{item_name} has condition/status issue. "
                f"Condition={space_item.condition}, Status={space_item.status}"
            ),
            space_id=space_id,
            space_item_id=space_item.id,
            tenancy_id=active_tenancy.id if active_tenancy else None,
            common_issue_id=common_issue.id,
            severity=common_issue.default_severity,
            urgency=common_issue.default_urgency
        )

        db.add(issue)
        db.flush()

        db.add(
            IssueUpdate(
                issue_id=issue.id,
                updated_by=reported_by,
                update_type="system",
                comment="Issue auto-created from space compliance check",
                old_status=None,
                new_status=status,
                status=status,
                new_assigned_to=assigned_to
            )
        )

        issues_created += 1

    return issues_created


def auto_resolve_issues_for_space(
    db: Session,
    space_id: UUID,
    updated_by: UUID = None
) -> int:
    candidates = db.query(Issue).join(
        SpaceItem,
        Issue.space_item_id == SpaceItem.id
    ).filter(
        SpaceItem.space_id == space_id,
        SpaceItem.condition == "good",
        SpaceItem.status == "active",
        Issue.status.in_(["open", "assigned", "in_progress"])
    ).all()

    issues_resolved = 0

    for issue in candidates:
        updater_id = updated_by or issue.assigned_to
        if not updater_id:
            raise ValueError(
                "updated_by is required when an issue has no assignee"
            )

        old_status = issue.status
        issue.status = "resolved"
        issue.resolved_at = func.now()
        issue.updated_at = func.now()

        db.add(
            IssueUpdate(
                issue_id=issue.id,
                updated_by=updater_id,
                update_type="system",
                comment="Auto-resolved: item condition restored to good",
                old_status=old_status,
                new_status="resolved",
                status="resolved"
            )
        )

        issues_resolved += 1

    return issues_resolved
