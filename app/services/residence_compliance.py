from uuid import UUID

from sqlalchemy.orm import Session

from app.models.compliance import ComplianceCheck, ComplianceFinding
from app.models.item import Item
from app.models.residence import Residence
from app.models.residence_caretaker import ResidenceCaretaker
from app.models.residence_landlords import ResidenceLandlord
from app.models.residence_manager import ResidenceManager
from app.models.space import Space
from app.models.space_item import SpaceItem
from app.models.space_item_template import SpaceItemTemplate

DEFAULT_REQUIRED_SHARED_SPACES = {
    "kitchen": 1,
    "bathroom": 1,
    "common": 1,
}

DEFAULT_RATIO_REQUIREMENTS = {
    "bathroom": {"per_residents": 8, "minimum": 1},
}

SHARED_SPACE_TYPES = {"kitchen", "bathroom", "common", "other"}


def _status_from_score(score: float):
    if score >= 90:
        return "pass"
    if score >= 70:
        return "warning"
    return "fail"


def get_residence_compliance_report(
    db: Session,
    residence_id: UUID,
    standard: str = "nsfas",
    template_type: str = "single_room",
) -> dict:
    residence = db.query(Residence).filter(Residence.id == residence_id).first()
    if not residence:
        raise ValueError("Residence not found")

    spaces = db.query(Space).filter(
        Space.residence_id == residence_id,
        Space.archived_at.is_(None),
    ).all()

    counts_by_type = {}
    for space in spaces:
        counts_by_type[space.space_type] = counts_by_type.get(space.space_type, 0) + 1

    compliance_findings = []
    shared_space_item_findings = []
    ratio_findings = []
    passed_requirements = 0
    total_requirements = len(DEFAULT_REQUIRED_SHARED_SPACES) + len(DEFAULT_RATIO_REQUIREMENTS) + 3

    for space_type, minimum_required in DEFAULT_REQUIRED_SHARED_SPACES.items():
        actual = counts_by_type.get(space_type, 0)
        if actual >= minimum_required:
            passed_requirements += 1
            continue

        compliance_findings.append({
            "finding_type": "missing_required_space",
            "severity": "high",
            "related_entity_type": "residence",
            "related_entity_id": residence.id,
            "expected_value": str(minimum_required),
            "actual_value": str(actual),
            "message": (
                f"Residence requires at least {minimum_required} {space_type} "
                f"space; found {actual}."
            ),
        })

    total_capacity = residence.total_capacity or 0
    for space_type, rule in DEFAULT_RATIO_REQUIREMENTS.items():
        if total_capacity <= 0:
            expected = rule["minimum"]
        else:
            expected = max(
                rule["minimum"],
                -(-total_capacity // rule["per_residents"]),
            )
        actual = counts_by_type.get(space_type, 0)
        if actual >= expected:
            passed_requirements += 1
            continue

        finding = {
            "finding_type": "ratio_failed",
            "severity": "high",
            "related_entity_type": "residence",
            "related_entity_id": residence.id,
            "expected_value": str(expected),
            "actual_value": str(actual),
            "message": (
                f"Residence requires at least {expected} {space_type} spaces "
                f"for capacity {total_capacity}; found {actual}."
            ),
        }
        compliance_findings.append(finding)
        ratio_findings.append(finding)

    shared_spaces = [space for space in spaces if space.space_type in SHARED_SPACE_TYPES]
    templates_by_type = {}
    template_rows = db.query(SpaceItemTemplate, Item).join(
        Item,
        Item.id == SpaceItemTemplate.item_id,
    ).filter(
        SpaceItemTemplate.space_type.in_(SHARED_SPACE_TYPES),
        SpaceItemTemplate.template_type == template_type,
        SpaceItemTemplate.standard == standard,
        SpaceItemTemplate.is_required == True,
    ).all()
    for template, item in template_rows:
        templates_by_type.setdefault(template.space_type, []).append((template, item))

    for space in shared_spaces:
        required_templates = templates_by_type.get(space.space_type, [])
        total_requirements += len(required_templates)
        if not required_templates:
            continue

        space_items = db.query(SpaceItem).filter(
            SpaceItem.space_id == space.id
        ).all()
        items_by_item_id = {
            space_item.item_id: space_item
            for space_item in space_items
        }

        for template, item in required_templates:
            space_item = items_by_item_id.get(template.item_id)
            required_quantity = template.default_quantity or 1
            actual_quantity = space_item.quantity if space_item else 0
            if space_item and actual_quantity >= required_quantity:
                passed_requirements += 1
                continue

            finding_type = "missing_required_item" if not space_item else "quantity_shortfall"
            finding = {
                "finding_type": finding_type,
                "severity": "medium",
                "related_entity_type": "space",
                "related_entity_id": space.id,
                "expected_value": str(required_quantity),
                "actual_value": str(actual_quantity),
                "message": (
                    f"Shared {space.space_type} space '{space.name}' requires "
                    f"{required_quantity} {item.name}; found {actual_quantity}."
                ),
            }
            compliance_findings.append(finding)
            shared_space_item_findings.append(finding)

    landlord_count = db.query(ResidenceLandlord).filter(
        ResidenceLandlord.residence_id == residence_id
    ).count()
    manager_count = db.query(ResidenceManager).filter(
        ResidenceManager.residence_id == residence_id
    ).count()
    caretaker_count = db.query(ResidenceCaretaker).filter(
        ResidenceCaretaker.residence_id == residence_id
    ).count()

    role_requirements = [
        ("landlord", landlord_count),
        ("manager", manager_count),
        ("caretaker", caretaker_count),
    ]
    for role_name, actual in role_requirements:
        if actual > 0:
            passed_requirements += 1
            continue

        compliance_findings.append({
            "finding_type": "missing_assignment",
            "severity": "high" if role_name in {"landlord", "manager"} else "medium",
            "related_entity_type": "residence",
            "related_entity_id": residence.id,
            "expected_value": "1",
            "actual_value": "0",
            "message": f"Residence requires at least one assigned {role_name}.",
        })

    score = round((passed_requirements / total_requirements) * 100, 2)

    return {
        "scope_type": "residence",
        "compliance_type": "residence",
        "residence_id": residence_id,
        "standard": standard,
        "template_type": template_type,
        "compliance": {
            "score": score,
            "status": _status_from_score(score),
            "passed_requirements": passed_requirements,
            "total_requirements": total_requirements,
            "findings_count": len(compliance_findings),
        },
        "shared_space_counts": counts_by_type,
        "ratio_requirements": DEFAULT_RATIO_REQUIREMENTS,
        "ratio_findings": ratio_findings,
        "shared_space_item_findings": shared_space_item_findings,
        "assignment_counts": {
            "landlords": landlord_count,
            "managers": manager_count,
            "caretakers": caretaker_count,
        },
        "compliance_findings": compliance_findings,
        "performance": {
            "message": (
                "Residence compliance checks required shared spaces and assignments. "
                "Condition, cleanliness, ratings, and maintenance speed belong to performance."
            )
        },
    }


def persist_residence_compliance_check(
    db: Session,
    *,
    report: dict,
    checked_by: UUID | None = None,
):
    check = ComplianceCheck(
        scope_type="residence",
        scope_id=report["residence_id"],
        standard=report["standard"],
        score=report["compliance"]["score"],
        status=report["compliance"]["status"],
        checked_by=checked_by,
        summary=(
            f"Residence compliance {report['compliance']['status']} "
            f"with score {report['compliance']['score']}"
        ),
        extra_metadata={
            "shared_space_counts": report["shared_space_counts"],
            "assignment_counts": report["assignment_counts"],
            "ratio_requirements": report["ratio_requirements"],
            "ratio_findings_count": len(report["ratio_findings"]),
            "shared_space_item_findings_count": len(report["shared_space_item_findings"]),
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
                related_entity_type=finding.get("related_entity_type"),
                related_entity_id=finding.get("related_entity_id"),
                expected_value=finding.get("expected_value"),
                actual_value=finding.get("actual_value"),
            )
        )

    db.commit()
    db.refresh(check)
    return check


def run_residence_compliance_check(
    db: Session,
    residence_id: UUID,
    standard: str = "nsfas",
    template_type: str = "single_room",
    checked_by: UUID | None = None,
):
    report = get_residence_compliance_report(
        db=db,
        residence_id=residence_id,
        standard=standard,
        template_type=template_type,
    )
    check = persist_residence_compliance_check(db, report=report, checked_by=checked_by)
    report["check_id"] = check.id
    return report
