from uuid import UUID

from sqlalchemy.orm import Session

from app.models.compliance import (
    ComplianceCheck,
    ComplianceFinding,
    ComplianceRule,
    ComplianceRuleRequirement,
)
from app.models.item import Item
from app.models.space import Space
from app.models.space_item import SpaceItem
from app.models.space_item_template import SpaceItemTemplate


def _status_from_score(score: float):
    if score >= 90:
        return "pass"
    if score >= 70:
        return "warning"
    return "fail"


def get_room_compliance_report(
    db: Session,
    space_id: UUID,
    template_type: str = "single_room",
    standard: str = "nsfas",
) -> dict:
    space = db.query(Space).filter(Space.id == space_id).first()
    if not space:
        raise ValueError("Space not found")

    if space.space_type != "room":
        raise ValueError("Room compliance only applies to room spaces")

    templates = db.query(SpaceItemTemplate, Item).join(
        Item,
        Item.id == SpaceItemTemplate.item_id,
    ).filter(
        SpaceItemTemplate.space_type == "room",
        SpaceItemTemplate.template_type == template_type,
        SpaceItemTemplate.standard == standard,
        SpaceItemTemplate.is_required == True,
    ).all()

    space_items = db.query(SpaceItem, Item).join(
        Item,
        Item.id == SpaceItem.item_id,
    ).filter(
        SpaceItem.space_id == space_id,
    ).all()

    item_by_item_id = {
        space_item.item_id: (space_item, item)
        for space_item, item in space_items
    }
    template_item_ids = {
        template.item_id
        for template, _item in templates
    }

    compliance_findings = []
    performance_indicators = []
    missing_items = []
    quantity_shortfalls = []
    present_required_items = []
    bad_items = []

    required_quantity_total = 0
    compliant_quantity_total = 0

    for template, item in templates:
        required_quantity = template.default_quantity or 1
        required_quantity_total += required_quantity
        item_entry = item_by_item_id.get(template.item_id)

        if not item_entry:
            finding = {
                "finding_type": "missing_required_item",
                "severity": "high",
                "item_id": template.item_id,
                "item_name": item.name,
                "expected_quantity": required_quantity,
                "actual_quantity": 0,
                "message": f"Required room item missing: {item.name}",
            }
            compliance_findings.append(finding)
            missing_items.append({
                "item_id": template.item_id,
                "item_name": item.name,
                "required_quantity": required_quantity,
            })
            continue

        space_item, _item = item_entry
        actual_quantity = space_item.quantity or 0
        compliant_quantity_total += min(actual_quantity, required_quantity)

        if actual_quantity < required_quantity:
            finding = {
                "finding_type": "quantity_shortfall",
                "severity": "medium",
                "space_item_id": space_item.id,
                "item_id": space_item.item_id,
                "item_name": item.name,
                "expected_quantity": required_quantity,
                "actual_quantity": actual_quantity,
                "message": (
                    f"Required quantity shortfall for {item.name}: "
                    f"expected {required_quantity}, found {actual_quantity}"
                ),
            }
            compliance_findings.append(finding)
            quantity_shortfalls.append(finding)
        else:
            present_required_items.append({
                "space_item_id": space_item.id,
                "item_id": space_item.item_id,
                "item_name": item.name,
                "quantity": actual_quantity,
            })

        if space_item.condition != "good" or space_item.status != "active":
            indicator = {
                "indicator_type": "item_condition_or_status",
                "space_item_id": space_item.id,
                "item_id": space_item.item_id,
                "item_name": item.name,
                "condition": space_item.condition,
                "status": space_item.status,
                "quantity": actual_quantity,
                "message": (
                    f"{item.name} is present for compliance, but performance is affected "
                    f"by condition={space_item.condition}, status={space_item.status}"
                ),
            }
            performance_indicators.append(indicator)
            bad_items.append({
                "space_item_id": space_item.id,
                "item_id": space_item.item_id,
                "item_name": item.name,
                "condition": space_item.condition,
                "status": space_item.status,
                "quantity": actual_quantity,
            })

    extra_items = [
        {
            "space_item_id": space_item.id,
            "item_id": space_item.item_id,
            "item_name": item.name,
            "condition": space_item.condition,
            "status": space_item.status,
            "quantity": space_item.quantity,
        }
        for space_item, item in space_items
        if space_item.item_id not in template_item_ids
    ]

    compliance_score = (
        round((compliant_quantity_total / required_quantity_total) * 100, 2)
        if required_quantity_total
        else 100
    )

    return {
        "scope_type": "room",
        "compliance_type": "room",
        "space_id": space_id,
        "template_type": template_type,
        "standard": standard,
        "compliance": {
            "score": compliance_score,
            "status": _status_from_score(compliance_score),
            "required_quantity_total": required_quantity_total,
            "compliant_quantity_total": compliant_quantity_total,
            "findings_count": len(compliance_findings),
        },
        "performance": {
            "indicators_count": len(performance_indicators),
            "message": (
                "Performance indicators are reported separately and do not reduce "
                "room compliance unless a rule explicitly requires usable condition."
            ),
        },
        "compliance_findings": compliance_findings,
        "performance_indicators": performance_indicators,
        "present_required_items": present_required_items,
        "missing_items": missing_items,
        "quantity_shortfalls": quantity_shortfalls,
        "extra_items": extra_items,
        "bad_items": bad_items,
        "score": {
            "total_required": len(templates),
            "compliant_items": len(templates) - len(missing_items) - len(quantity_shortfalls),
            "missing_items": len(missing_items),
            "quantity_shortfalls": len(quantity_shortfalls),
            "bad_items": len(bad_items),
            "extra_items": len(extra_items),
            "compliance_percentage": compliance_score,
        },
    }


def persist_room_compliance_check(
    db: Session,
    *,
    report: dict,
    checked_by: UUID | None = None,
):
    check = ComplianceCheck(
        scope_type="room",
        scope_id=report["space_id"],
        standard=report["standard"],
        score=report["compliance"]["score"],
        status=report["compliance"]["status"],
        checked_by=checked_by,
        summary=(
            f"Room compliance {report['compliance']['status']} "
            f"with score {report['compliance']['score']}"
        ),
        extra_metadata={
            "template_type": report["template_type"],
            "required_quantity_total": report["compliance"]["required_quantity_total"],
            "compliant_quantity_total": report["compliance"]["compliant_quantity_total"],
            "performance_indicators_count": report["performance"]["indicators_count"],
        },
    )
    db.add(check)
    db.flush()

    for finding in report["compliance_findings"]:
        db.add(
            ComplianceFinding(
                check_id=check.id,
                finding_type=finding["finding_type"],
                severity=finding["severity"],
                status="open",
                message=finding["message"],
                related_entity_type="space_item" if finding.get("space_item_id") else "item",
                related_entity_id=finding.get("space_item_id") or finding.get("item_id"),
                expected_value=str(finding.get("expected_quantity")),
                actual_value=str(finding.get("actual_quantity")),
            )
        )

    db.commit()
    db.refresh(check)
    return check


def run_room_compliance_check(
    db: Session,
    space_id: UUID,
    template_type: str = "single_room",
    standard: str = "nsfas",
    checked_by: UUID | None = None,
):
    report = get_room_compliance_report(
        db=db,
        space_id=space_id,
        template_type=template_type,
        standard=standard,
    )
    check = persist_room_compliance_check(db, report=report, checked_by=checked_by)
    report["check_id"] = check.id
    return report


def seed_room_compliance_rules(
    db: Session,
    *,
    template_type: str = "single_room",
    standard: str = "nsfas",
):
    templates = db.query(SpaceItemTemplate, Item).join(
        Item,
        Item.id == SpaceItemTemplate.item_id,
    ).filter(
        SpaceItemTemplate.space_type == "room",
        SpaceItemTemplate.template_type == template_type,
        SpaceItemTemplate.standard == standard,
        SpaceItemTemplate.is_required == True,
    ).all()

    created = 0
    for template, item in templates:
        rule_code = f"room_required_item_{template_type}_{standard}_{item.id}"
        existing = db.query(ComplianceRule).filter(
            ComplianceRule.standard == standard,
            ComplianceRule.scope_type == "room",
            ComplianceRule.rule_code == rule_code,
        ).first()
        if existing:
            continue

        rule = ComplianceRule(
            standard=standard,
            scope_type="room",
            rule_code=rule_code,
            rule_name=f"Room requires {item.name}",
            description=f"Room compliance requires {item.name} to be present.",
            severity="high",
            is_active=True,
        )
        db.add(rule)
        db.flush()

        db.add(
            ComplianceRuleRequirement(
                rule_id=rule.id,
                requirement_type="required_item",
                item_id=item.id,
                space_type="room",
                minimum_quantity=template.default_quantity or 1,
                extra_metadata={
                    "template_type": template_type,
                    "standard": standard,
                    "source": "space_item_template",
                    "space_item_template_id": str(template.id),
                },
            )
        )
        created += 1

    db.commit()
    return created
