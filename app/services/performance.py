from datetime import datetime, timezone
from uuid import UUID

from fastapi import HTTPException
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models.inspection import Inspection
from app.models.issue import Issue
from app.models.media import MediaAttachment
from app.models.performance import PerformanceCheck, PerformanceFinding, PerformanceRating
from app.models.residence import Residence
from app.models.service_catalog import ResidenceService
from app.models.space import Space
from app.models.space_item import SpaceItem
from app.models.user import User
from app.models.common_issue import CommonIssue
from app.schemas.issue import IssueCreate
from app.services.issue import create_issue
from app.schemas.performance import PerformanceRatingCreate

VALID_TARGET_TYPES = {"space_item", "space", "service", "residence", "contractor", "vendor", "issue"}
VALID_CATEGORIES = {
    "overall",
    "cleanliness",
    "comfort",
    "safety",
    "maintenance",
    "availability",
    "responsiveness",
    "quality",
    "condition",
}


def create_performance_rating(db: Session, payload: PerformanceRatingCreate):
    _validate_payload(db, payload)
    rating = PerformanceRating(**payload.model_dump())
    db.add(rating)
    db.commit()
    db.refresh(rating)
    return rating


def list_performance_ratings(
    db: Session,
    *,
    target_type: str | None = None,
    target_id: UUID | None = None,
    rated_by: UUID | None = None,
    category: str | None = None,
    include_archived: bool = False,
    offset: int = 0,
    limit: int = 50,
):
    query = db.query(PerformanceRating)
    if not include_archived:
        query = query.filter(PerformanceRating.archived_at.is_(None))
    if target_type:
        query = query.filter(PerformanceRating.target_type == target_type)
    if target_id:
        query = query.filter(PerformanceRating.target_id == target_id)
    if rated_by:
        query = query.filter(PerformanceRating.rated_by == rated_by)
    if category:
        query = query.filter(PerformanceRating.category == category)
    return query.order_by(PerformanceRating.created_at.desc()).offset(offset).limit(limit).all()


def get_target_ratings(
    db: Session,
    *,
    target_type: str,
    target_id: UUID,
    category: str | None = None,
    include_archived: bool = False,
):
    _validate_target_type(target_type)
    return list_performance_ratings(
        db,
        target_type=target_type,
        target_id=target_id,
        category=category,
        include_archived=include_archived,
    )


def get_target_rating_summary(
    db: Session,
    *,
    target_type: str,
    target_id: UUID,
    category: str | None = None,
):
    _validate_target_type(target_type)
    query = db.query(
        func.count(PerformanceRating.id),
        func.avg(PerformanceRating.rating),
    ).filter(
        PerformanceRating.target_type == target_type,
        PerformanceRating.target_id == target_id,
        PerformanceRating.archived_at.is_(None),
    )
    if category:
        query = query.filter(PerformanceRating.category == category)
    count, average = query.one()
    return {
        "target_type": target_type,
        "target_id": target_id,
        "ratings_count": count,
        "average_rating": round(float(average), 2) if average is not None else None,
        "category": category,
    }


def archive_performance_rating(db: Session, rating_id: UUID):
    rating = db.query(PerformanceRating).filter(
        PerformanceRating.id == rating_id,
        PerformanceRating.archived_at.is_(None),
    ).first()
    if not rating:
        raise HTTPException(404, "Performance rating not found")
    rating.archived_at = func.now()
    db.commit()
    db.refresh(rating)
    return rating


def get_performance_report(db: Session, *, scope_type: str, scope_id: UUID):
    _validate_performance_scope_exists(db, scope_type, scope_id)
    rating_signal = _rating_signal(db, scope_type, scope_id)
    issue_signal = _issue_signal(db, scope_type, scope_id)
    inspection_signal = _inspection_signal(db, scope_type, scope_id)

    weighted_inputs = []
    if rating_signal["score"] is not None:
        weighted_inputs.append(("ratings", rating_signal["score"], 40))
    if issue_signal["score"] is not None:
        weighted_inputs.append(("issues", issue_signal["score"], 35))
    if inspection_signal["score"] is not None:
        weighted_inputs.append(("inspections", inspection_signal["score"], 25))

    if weighted_inputs:
        total_weight = sum(weight for _name, _score, weight in weighted_inputs)
        score = round(
            sum(signal_score * weight for _name, signal_score, weight in weighted_inputs) / total_weight,
            2,
        )
        status = _performance_status_from_score(score)
    else:
        total_weight = 0
        score = 0
        status = "not_enough_data"

    findings = []
    findings.extend(rating_signal["findings"])
    findings.extend(issue_signal["findings"])
    findings.extend(inspection_signal["findings"])

    return {
        "scope_type": scope_type,
        "scope_id": scope_id,
        "performance": {
            "score": score,
            "status": status,
            "findings_count": len(findings),
            "active_weight_total": total_weight,
        },
        "signals": {
            "ratings": rating_signal,
            "issues": issue_signal,
            "inspections": inspection_signal,
        },
        "performance_findings": findings,
        "compliance": {
            "message": (
                "Performance is calculated separately from compliance. Low ratings, "
                "open issues, SLA breaches, and poor inspection condition do not "
                "change compliance scores unless a compliance rule explicitly says so."
            )
        },
    }


def persist_performance_check(db: Session, *, report: dict):
    check = PerformanceCheck(
        scope_type=report["scope_type"],
        scope_id=report["scope_id"],
        score=report["performance"]["score"],
        status=report["performance"]["status"],
        summary=(
            f"{report['scope_type'].title()} performance "
            f"{report['performance']['status']} with score {report['performance']['score']}"
        ),
        extra_metadata={
            "signals": _json_safe(report["signals"]),
            "active_weight_total": report["performance"]["active_weight_total"],
        },
    )
    db.add(check)
    db.flush()

    for finding in report["performance_findings"]:
        db.add(
            PerformanceFinding(
                check_id=check.id,
                finding_type=finding["finding_type"],
                severity=finding["severity"],
                message=finding["message"],
                related_entity_type=finding.get("related_entity_type"),
                related_entity_id=finding.get("related_entity_id"),
                created_issue_id=finding.get("created_issue_id"),
            )
        )

    db.commit()
    db.refresh(check)
    return check


def run_performance_check(db: Session, *, scope_type: str, scope_id: UUID):
    report = get_performance_report(db, scope_type=scope_type, scope_id=scope_id)
    check = persist_performance_check(db, report=report)
    report["check_id"] = check.id
    return report


def create_issue_from_performance_finding(
    db: Session,
    *,
    finding_id: UUID,
    reported_by: UUID,
    common_issue_id: UUID | None = None,
    space_id: UUID | None = None,
    description: str | None = None,
):
    finding = db.query(PerformanceFinding).filter(
        PerformanceFinding.id == finding_id,
    ).first()
    if not finding:
        raise HTTPException(404, "Performance finding not found")

    if finding.created_issue_id:
        existing = db.query(Issue).filter(Issue.id == finding.created_issue_id).first()
        if existing:
            return {
                "issue": existing,
                "created": False,
                "message": "Performance finding already has a linked issue.",
            }

    resolved = _resolve_issue_context_from_finding(
        db,
        finding=finding,
        common_issue_id=common_issue_id,
        space_id=space_id,
    )
    issue = create_issue(
        db,
        IssueCreate(
            reported_by=reported_by,
            space_id=resolved["space_id"],
            space_item_id=resolved.get("space_item_id"),
            common_issue_id=resolved["common_issue_id"],
            description=description or finding.message,
            severity=_issue_severity_from_finding(finding.severity),
            urgency=_issue_urgency_from_finding(finding.severity),
        ),
    )

    finding = db.query(PerformanceFinding).filter(PerformanceFinding.id == finding_id).first()
    finding.created_issue_id = issue.id
    db.commit()
    db.refresh(finding)

    return {
        "issue": issue,
        "created": True,
        "message": "Issue created from performance finding.",
    }


def _performance_status_from_score(score: float):
    if score >= 90:
        return "excellent"
    if score >= 75:
        return "good"
    if score >= 55:
        return "degraded"
    if score >= 35:
        return "poor"
    return "critical"


def _rating_signal(db: Session, scope_type: str, scope_id: UUID):
    target_type = "service" if scope_type == "service" else scope_type
    ratings = list_performance_ratings(
        db,
        target_type=target_type,
        target_id=scope_id,
        include_archived=False,
        limit=1000,
    )
    if not ratings:
        return {
            "score": None,
            "ratings_count": 0,
            "average_rating": None,
            "findings": [],
        }

    average_rating = round(sum(rating.rating for rating in ratings) / len(ratings), 2)
    score = round((average_rating / 5) * 100, 2)
    findings = []
    if average_rating < 3:
        findings.append({
            "finding_type": "low_rating",
            "severity": "high" if average_rating < 2 else "medium",
            "message": f"Average rating is low at {average_rating}/5.",
            "related_entity_type": target_type,
            "related_entity_id": scope_id,
        })
    return {
        "score": score,
        "ratings_count": len(ratings),
        "average_rating": average_rating,
        "findings": findings,
    }


def _issue_signal(db: Session, scope_type: str, scope_id: UUID):
    if scope_type not in {"space", "room", "residence"}:
        return {"score": None, "open_issues": 0, "sla_breaches": 0, "critical_issues": 0, "findings": []}

    query = db.query(Issue).filter(Issue.archived_at.is_(None))
    if scope_type in {"space", "room"}:
        query = query.filter(Issue.space_id == scope_id)
    else:
        space_ids = [
            row[0]
            for row in db.query(Space.id).filter(
                Space.residence_id == scope_id,
                Space.archived_at.is_(None),
            ).all()
        ]
        if not space_ids:
            return {"score": 100, "open_issues": 0, "sla_breaches": 0, "critical_issues": 0, "findings": []}
        query = query.filter(Issue.space_id.in_(space_ids))

    active_issues = query.filter(Issue.status.notin_(["resolved", "closed", "rejected"])).all()
    open_count = len(active_issues)
    now = datetime.now(timezone.utc)
    sla_breaches = sum(1 for issue in active_issues if issue.due_at and issue.due_at < now)
    critical_count = sum(1 for issue in active_issues if issue.severity == "critical")
    score = max(0, 100 - (open_count * 8) - (sla_breaches * 12) - (critical_count * 10))

    findings = []
    if open_count >= 5:
        findings.append({
            "finding_type": "high_backlog",
            "severity": "high",
            "message": f"{open_count} active issues are affecting performance.",
            "related_entity_type": scope_type,
            "related_entity_id": scope_id,
        })
    if sla_breaches:
        findings.append({
            "finding_type": "sla_breach",
            "severity": "high",
            "message": f"{sla_breaches} active issues are past due.",
            "related_entity_type": scope_type,
            "related_entity_id": scope_id,
        })
    return {
        "score": round(score, 2),
        "open_issues": open_count,
        "sla_breaches": sla_breaches,
        "critical_issues": critical_count,
        "findings": findings,
    }


def _inspection_signal(db: Session, scope_type: str, scope_id: UUID):
    if scope_type not in {"space", "room", "residence"}:
        return {"score": None, "inspections_count": 0, "condition_counts": {}, "findings": []}

    query = db.query(Inspection).join(SpaceItem, SpaceItem.id == Inspection.space_item_id)
    if scope_type in {"space", "room"}:
        query = query.filter(SpaceItem.space_id == scope_id)
    else:
        query = query.join(Space, Space.id == SpaceItem.space_id).filter(
            Space.residence_id == scope_id,
            Space.archived_at.is_(None),
        )

    inspections = query.filter(Inspection.status == "completed").all()
    if not inspections:
        return {"score": None, "inspections_count": 0, "condition_counts": {}, "findings": []}

    condition_scores = {"good": 100, "fair": 75, "poor": 40, "damaged": 20}
    condition_counts = {}
    score_total = 0
    findings = []
    for inspection in inspections:
        condition_counts[inspection.condition] = condition_counts.get(inspection.condition, 0) + 1
        score_total += condition_scores.get(inspection.condition, 0)
        if inspection.condition in {"poor", "damaged"}:
            findings.append({
                "finding_type": "inspection_condition",
                "severity": "high" if inspection.condition == "damaged" else "medium",
                "message": f"Inspection recorded {inspection.condition} condition.",
                "related_entity_type": "inspection",
                "related_entity_id": inspection.id,
            })

    return {
        "score": round(score_total / len(inspections), 2),
        "inspections_count": len(inspections),
        "condition_counts": condition_counts,
        "findings": findings,
    }


def _validate_performance_scope_exists(db: Session, scope_type: str, scope_id: UUID):
    if scope_type not in {"room", "space", "residence", "service", "contractor", "vendor"}:
        raise HTTPException(400, "Invalid performance scope type")
    model_by_scope = {
        "room": Space,
        "space": Space,
        "residence": Residence,
        "service": ResidenceService,
    }
    model = model_by_scope.get(scope_type)
    if model and not db.query(model).filter(model.id == scope_id).first():
        raise HTTPException(404, "Performance scope not found")


def _json_safe(value):
    if isinstance(value, UUID):
        return str(value)
    if isinstance(value, dict):
        return {key: _json_safe(item) for key, item in value.items()}
    if isinstance(value, list):
        return [_json_safe(item) for item in value]
    return value


def _resolve_issue_context_from_finding(
    db: Session,
    *,
    finding: PerformanceFinding,
    common_issue_id: UUID | None,
    space_id: UUID | None,
):
    resolved_space_id = space_id
    resolved_space_item_id = None
    resolved_common_issue_id = common_issue_id

    if finding.related_entity_type == "inspection" and finding.related_entity_id:
        inspection = db.query(Inspection).filter(Inspection.id == finding.related_entity_id).first()
        if inspection:
            space_item = db.query(SpaceItem).filter(SpaceItem.id == inspection.space_item_id).first()
            if space_item:
                resolved_space_id = space_item.space_id
                resolved_space_item_id = space_item.id
                resolved_common_issue_id = resolved_common_issue_id or _find_common_issue_for_item(
                    db,
                    space_item.item_id,
                )

    if finding.related_entity_type == "space_item" and finding.related_entity_id:
        space_item = db.query(SpaceItem).filter(SpaceItem.id == finding.related_entity_id).first()
        if space_item:
            resolved_space_id = space_item.space_id
            resolved_space_item_id = space_item.id
            resolved_common_issue_id = resolved_common_issue_id or _find_common_issue_for_item(
                db,
                space_item.item_id,
            )

    if finding.related_entity_type in {"space", "room"} and finding.related_entity_id:
        resolved_space_id = resolved_space_id or finding.related_entity_id

    if not resolved_space_id:
        raise HTTPException(
            400,
            "space_id is required when the performance finding is not tied to a space or space item",
        )
    if not resolved_common_issue_id:
        raise HTTPException(
            400,
            "common_issue_id is required when no matching item issue can be inferred",
        )

    return {
        "space_id": resolved_space_id,
        "space_item_id": resolved_space_item_id,
        "common_issue_id": resolved_common_issue_id,
    }


def _find_common_issue_for_item(db: Session, item_id: UUID):
    row = db.query(CommonIssue.id).filter(
        CommonIssue.item_id == item_id,
        CommonIssue.is_active == True,
    ).first()
    return row[0] if row else None


def _issue_severity_from_finding(severity: str):
    if severity in {"low", "medium", "high", "critical"}:
        return severity
    return "medium"


def _issue_urgency_from_finding(severity: str):
    return {
        "low": "low",
        "medium": "medium",
        "high": "high",
        "critical": "urgent",
    }.get(severity, "medium")


def _validate_payload(db: Session, payload: PerformanceRatingCreate):
    _validate_target_type(payload.target_type)
    if payload.category not in VALID_CATEGORIES:
        raise HTTPException(400, "Invalid performance rating category")
    if payload.rated_by and not db.query(User.id).filter(User.id == payload.rated_by).first():
        raise HTTPException(404, "Rating user not found")
    if payload.media_attachment_id:
        attachment = db.query(MediaAttachment.id).filter(
            MediaAttachment.id == payload.media_attachment_id,
            MediaAttachment.archived_at.is_(None),
        ).first()
        if not attachment:
            raise HTTPException(404, "Media attachment not found")
    _validate_target_exists(db, payload.target_type, payload.target_id)


def _validate_target_type(target_type: str):
    if target_type not in VALID_TARGET_TYPES:
        raise HTTPException(400, "Invalid performance rating target type")


def _validate_target_exists(db: Session, target_type: str, target_id: UUID):
    model_by_target = {
        "space_item": SpaceItem,
        "space": Space,
        "service": ResidenceService,
        "residence": Residence,
        "issue": Issue,
    }
    model = model_by_target.get(target_type)
    if not model:
        return
    if not db.query(model).filter(model.id == target_id).first():
        raise HTTPException(404, "Performance rating target not found")
