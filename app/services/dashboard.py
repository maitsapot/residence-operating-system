from uuid import UUID

from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models.compliance import ComplianceCheck, ComplianceFinding
from app.models.issue import Issue
from app.models.performance import PerformanceCheck, PerformanceFinding
from app.models.residence import Residence
from app.models.service_catalog import ResidenceService
from app.models.space import Space


def get_compliance_summary(db: Session, residence_id: UUID):
    _get_residence(db, residence_id)
    room_ids = _space_ids(db, residence_id, space_type="room")

    components = {
        "overall": _latest_compliance_check(db, "overall", residence_id),
        "residence": _latest_compliance_check(db, "residence", residence_id),
        "documentation": _latest_compliance_check(db, "documentation", residence_id),
        "rooms": _aggregate_checks([
            _latest_compliance_check(db, "room", room_id)
            for room_id in room_ids
        ]),
    }

    open_findings = db.query(ComplianceFinding).join(
        ComplianceCheck,
        ComplianceCheck.id == ComplianceFinding.check_id,
    ).filter(
        ComplianceFinding.status == "open",
        (
            (ComplianceCheck.scope_type.in_(["overall", "residence", "documentation"]))
            & (ComplianceCheck.scope_id == residence_id)
        )
        | (
            (ComplianceCheck.scope_type == "room")
            & (ComplianceCheck.scope_id.in_(room_ids or [_zero_uuid()]))
        ),
    ).count()

    return {
        "residence_id": residence_id,
        "summary_type": "compliance",
        "components": components,
        "open_findings": open_findings,
        "message": "Compliance summary contains compliance checks only.",
    }


def get_performance_summary(db: Session, residence_id: UUID):
    _get_residence(db, residence_id)
    space_ids = _space_ids(db, residence_id)
    service_ids = [
        row[0]
        for row in db.query(ResidenceService.id).filter(
            ResidenceService.residence_id == residence_id,
            ResidenceService.archived_at.is_(None),
        ).all()
    ]

    components = {
        "residence": _latest_performance_check(db, "residence", residence_id),
        "spaces": _aggregate_checks([
            _latest_performance_check(db, "space", space_id)
            for space_id in space_ids
        ]),
        "services": _aggregate_checks([
            _latest_performance_check(db, "service", service_id)
            for service_id in service_ids
        ]),
    }

    active_issue_count = db.query(Issue).filter(
        Issue.space_id.in_(space_ids or [_zero_uuid()]),
        Issue.status.notin_(["resolved", "closed", "rejected"]),
        Issue.archived_at.is_(None),
    ).count()

    finding_count = db.query(PerformanceFinding).join(
        PerformanceCheck,
        PerformanceCheck.id == PerformanceFinding.check_id,
    ).filter(
        (
            (PerformanceCheck.scope_type == "residence")
            & (PerformanceCheck.scope_id == residence_id)
        )
        | (
            (PerformanceCheck.scope_type.in_(["space", "room"]))
            & (PerformanceCheck.scope_id.in_(space_ids or [_zero_uuid()]))
        )
        | (
            (PerformanceCheck.scope_type == "service")
            & (PerformanceCheck.scope_id.in_(service_ids or [_zero_uuid()]))
        ),
    ).count()

    return {
        "residence_id": residence_id,
        "summary_type": "performance",
        "components": components,
        "active_issues": active_issue_count,
        "performance_findings": finding_count,
        "message": "Performance summary contains ratings, issues, SLA, and condition signals only.",
    }


def get_residence_dashboard(db: Session, residence_id: UUID):
    residence = _get_residence(db, residence_id)
    spaces = db.query(Space).filter(
        Space.residence_id == residence_id,
        Space.archived_at.is_(None),
    ).all()
    compliance = get_compliance_summary(db, residence_id)
    performance = get_performance_summary(db, residence_id)

    return {
        "residence_id": residence_id,
        "residence_name": residence.name,
        "space_counts": _counts_by_attr(spaces, "space_type"),
        "compliance": compliance,
        "performance": performance,
        "separation_note": (
            "Compliance and performance are intentionally reported separately. "
            "Overall compliance does not include performance ratings or issue speed."
        ),
    }


def get_residence_trends(db: Session, residence_id: UUID, limit: int = 20):
    _get_residence(db, residence_id)
    compliance_rows = db.query(ComplianceCheck).filter(
        ComplianceCheck.scope_id == residence_id,
        ComplianceCheck.scope_type.in_(["overall", "residence", "documentation"]),
    ).order_by(ComplianceCheck.checked_at.desc()).limit(limit).all()
    performance_rows = db.query(PerformanceCheck).filter(
        PerformanceCheck.scope_id == residence_id,
        PerformanceCheck.scope_type == "residence",
    ).order_by(PerformanceCheck.calculated_at.desc()).limit(limit).all()

    return {
        "residence_id": residence_id,
        "compliance": [_serialize_compliance_check(row) for row in compliance_rows],
        "performance": [_serialize_performance_check(row) for row in performance_rows],
    }


def get_export_ready_report(db: Session, residence_id: UUID):
    dashboard = get_residence_dashboard(db, residence_id)
    trends = get_residence_trends(db, residence_id)
    return {
        "report_type": "residence_compliance_performance",
        "residence_id": residence_id,
        "dashboard": dashboard,
        "trends": trends,
        "sections": [
            "residence",
            "compliance_summary",
            "performance_summary",
            "trend_history",
        ],
    }


def _get_residence(db: Session, residence_id: UUID):
    residence = db.query(Residence).filter(Residence.id == residence_id).first()
    if not residence:
        raise HTTPException(404, "Residence not found")
    return residence


def _space_ids(db: Session, residence_id: UUID, space_type: str | None = None):
    query = db.query(Space.id).filter(
        Space.residence_id == residence_id,
        Space.archived_at.is_(None),
    )
    if space_type:
        query = query.filter(Space.space_type == space_type)
    return [row[0] for row in query.all()]


def _latest_compliance_check(db: Session, scope_type: str, scope_id: UUID):
    check = db.query(ComplianceCheck).filter(
        ComplianceCheck.scope_type == scope_type,
        ComplianceCheck.scope_id == scope_id,
    ).order_by(ComplianceCheck.checked_at.desc()).first()
    return _serialize_compliance_check(check) if check else None


def _latest_performance_check(db: Session, scope_type: str, scope_id: UUID):
    check = db.query(PerformanceCheck).filter(
        PerformanceCheck.scope_type == scope_type,
        PerformanceCheck.scope_id == scope_id,
    ).order_by(PerformanceCheck.calculated_at.desc()).first()
    return _serialize_performance_check(check) if check else None


def _aggregate_checks(checks: list[dict | None]):
    active = [check for check in checks if check]
    if not active:
        return {
            "count": 0,
            "average_score": None,
            "status_counts": {},
        }
    return {
        "count": len(active),
        "average_score": round(sum(float(check["score"]) for check in active) / len(active), 2),
        "status_counts": _counts_by_key(active, "status"),
    }


def _serialize_compliance_check(check: ComplianceCheck):
    return {
        "id": check.id,
        "scope_type": check.scope_type,
        "scope_id": check.scope_id,
        "score": float(check.score),
        "status": check.status,
        "checked_at": check.checked_at,
        "summary": check.summary,
    }


def _serialize_performance_check(check: PerformanceCheck):
    return {
        "id": check.id,
        "scope_type": check.scope_type,
        "scope_id": check.scope_id,
        "score": float(check.score),
        "status": check.status,
        "calculated_at": check.calculated_at,
        "summary": check.summary,
    }


def _counts_by_attr(rows, attr_name: str):
    counts = {}
    for row in rows:
        key = getattr(row, attr_name)
        counts[key] = counts.get(key, 0) + 1
    return counts


def _counts_by_key(rows: list[dict], key: str):
    counts = {}
    for row in rows:
        value = row[key]
        counts[value] = counts.get(value, 0) + 1
    return counts


def _zero_uuid():
    return UUID("00000000-0000-0000-0000-000000000000")
