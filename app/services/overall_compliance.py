from uuid import UUID

from sqlalchemy.orm import Session

from app.models.compliance import ComplianceCheck, ComplianceFinding
from app.models.residence import Residence
from app.models.space import Space
from app.services.documentation_compliance import get_documentation_compliance_report
from app.services.residence_compliance import get_residence_compliance_report
from app.services.room_compliance import get_room_compliance_report

DEFAULT_COMPONENT_WEIGHTS = {
    "room": 40,
    "residence": 35,
    "documentation": 25,
}


def _status_from_score(score: float):
    if score >= 90:
        return "pass"
    if score >= 70:
        return "warning"
    return "fail"


def _component_status(score: float | None):
    if score is None:
        return "not_applicable"
    return _status_from_score(score)


def get_overall_compliance_report(
    db: Session,
    residence_id: UUID,
    standard: str = "nsfas",
    template_type: str = "single_room",
) -> dict:
    residence = db.query(Residence).filter(Residence.id == residence_id).first()
    if not residence:
        raise ValueError("Residence not found")

    active_rooms = db.query(Space).filter(
        Space.residence_id == residence_id,
        Space.space_type == "room",
        Space.archived_at.is_(None),
    ).all()

    room_reports = [
        get_room_compliance_report(
            db=db,
            space_id=room.id,
            template_type=template_type,
            standard=standard,
        )
        for room in active_rooms
    ]
    room_score = (
        round(
            sum(report["compliance"]["score"] for report in room_reports) / len(room_reports),
            2,
        )
        if room_reports
        else None
    )

    residence_report = get_residence_compliance_report(
        db=db,
        residence_id=residence_id,
        standard=standard,
        template_type=template_type,
    )
    documentation_report = get_documentation_compliance_report(
        db=db,
        residence_id=residence_id,
        standard=standard,
    )

    component_scores = {
        "room": room_score,
        "residence": residence_report["compliance"]["score"],
        "documentation": documentation_report["compliance"]["score"],
    }
    active_weights = {
        name: DEFAULT_COMPONENT_WEIGHTS[name]
        for name, score in component_scores.items()
        if score is not None
    }
    total_weight = sum(active_weights.values())
    overall_score = (
        round(
            sum(component_scores[name] * weight for name, weight in active_weights.items()) / total_weight,
            2,
        )
        if total_weight
        else 0
    )

    components = {
        "room": {
            "score": room_score,
            "status": _component_status(room_score),
            "weight": DEFAULT_COMPONENT_WEIGHTS["room"],
            "active_weight": active_weights.get("room", 0),
            "rooms_checked": len(room_reports),
            "findings_count": sum(
                report["compliance"]["findings_count"] for report in room_reports
            ),
        },
        "residence": {
            "score": component_scores["residence"],
            "status": residence_report["compliance"]["status"],
            "weight": DEFAULT_COMPONENT_WEIGHTS["residence"],
            "active_weight": active_weights.get("residence", 0),
            "findings_count": residence_report["compliance"]["findings_count"],
        },
        "documentation": {
            "score": component_scores["documentation"],
            "status": documentation_report["compliance"]["status"],
            "weight": DEFAULT_COMPONENT_WEIGHTS["documentation"],
            "active_weight": active_weights.get("documentation", 0),
            "findings_count": documentation_report["compliance"]["findings_count"],
        },
    }

    findings = []
    for component_name, component in components.items():
        if component["status"] in {"pass", "not_applicable"}:
            continue
        findings.append({
            "finding_type": "custom",
            "severity": "high" if component["status"] == "fail" else "medium",
            "related_entity_type": "residence",
            "related_entity_id": residence_id,
            "expected_value": "component pass",
            "actual_value": component["status"],
            "message": (
                f"{component_name.title()} compliance is {component['status']} "
                f"with score {component['score']}."
            ),
        })

    return {
        "scope_type": "overall",
        "compliance_type": "overall",
        "residence_id": residence_id,
        "standard": standard,
        "template_type": template_type,
        "weights": DEFAULT_COMPONENT_WEIGHTS,
        "active_weight_total": total_weight,
        "components": components,
        "component_reports": {
            "room": {
                "rooms_checked": len(room_reports),
                "room_scores": [
                    {
                        "space_id": report["space_id"],
                        "score": report["compliance"]["score"],
                        "status": report["compliance"]["status"],
                        "findings_count": report["compliance"]["findings_count"],
                    }
                    for report in room_reports
                ],
            },
            "residence": residence_report,
            "documentation": documentation_report,
        },
        "compliance": {
            "score": overall_score,
            "status": _status_from_score(overall_score),
            "findings_count": len(findings),
        },
        "compliance_findings": findings,
        "performance": {
            "message": (
                "Overall compliance combines compliance modules only. Student ratings, "
                "condition, response times, and service quality remain performance signals."
            )
        },
    }


def persist_overall_compliance_check(
    db: Session,
    *,
    report: dict,
    checked_by: UUID | None = None,
):
    check = ComplianceCheck(
        scope_type="overall",
        scope_id=report["residence_id"],
        standard=report["standard"],
        score=report["compliance"]["score"],
        status=report["compliance"]["status"],
        checked_by=checked_by,
        summary=(
            f"Overall compliance {report['compliance']['status']} "
            f"with score {report['compliance']['score']}"
        ),
        extra_metadata={
            "weights": report["weights"],
            "active_weight_total": report["active_weight_total"],
            "components": report["components"],
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


def run_overall_compliance_check(
    db: Session,
    residence_id: UUID,
    standard: str = "nsfas",
    template_type: str = "single_room",
    checked_by: UUID | None = None,
):
    report = get_overall_compliance_report(
        db=db,
        residence_id=residence_id,
        standard=standard,
        template_type=template_type,
    )
    check = persist_overall_compliance_check(db, report=report, checked_by=checked_by)
    report["check_id"] = check.id
    return report
