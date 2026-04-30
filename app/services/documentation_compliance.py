from datetime import date
from uuid import UUID

from fastapi import HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.sql import func

from app.models.compliance import ComplianceCheck, ComplianceDocument, ComplianceFinding
from app.models.media import MediaAttachment
from app.models.residence import Residence
from app.schemas.compliance import ComplianceDocumentCreate, ComplianceDocumentStatusUpdate

DEFAULT_REQUIRED_DOCUMENTS = [
    {
        "document_type": "nsfas_accreditation",
        "document_name": "NSFAS accreditation",
        "severity": "critical",
        "requires_expiry": True,
    },
    {
        "document_type": "fire_safety_certificate",
        "document_name": "Fire safety certificate",
        "severity": "critical",
        "requires_expiry": True,
    },
    {
        "document_type": "occupancy_certificate",
        "document_name": "Occupancy certificate",
        "severity": "high",
        "requires_expiry": False,
    },
    {
        "document_type": "insurance_document",
        "document_name": "Insurance document",
        "severity": "high",
        "requires_expiry": True,
    },
    {
        "document_type": "landlord_verification",
        "document_name": "Landlord verification",
        "severity": "medium",
        "requires_expiry": False,
    },
]

VALID_DOCUMENT_STATUSES = {"missing", "submitted", "approved", "rejected", "expired"}


def _status_from_score(score: float):
    if score >= 90:
        return "pass"
    if score >= 70:
        return "warning"
    return "fail"


def _get_residence(db: Session, residence_id: UUID):
    residence = db.query(Residence).filter(Residence.id == residence_id).first()
    if not residence:
        raise HTTPException(404, "Residence not found")
    return residence


def _validate_document_status(status: str):
    if status not in VALID_DOCUMENT_STATUSES:
        raise HTTPException(400, "Invalid compliance document status")


def list_compliance_documents(
    db: Session,
    *,
    residence_id: UUID,
    document_type: str | None = None,
    status: str | None = None,
    include_archived: bool = False,
):
    _get_residence(db, residence_id)
    query = db.query(ComplianceDocument).filter(
        ComplianceDocument.residence_id == residence_id,
    )
    if not include_archived:
        query = query.filter(ComplianceDocument.archived_at.is_(None))
    if document_type:
        query = query.filter(ComplianceDocument.document_type == document_type)
    if status:
        query = query.filter(ComplianceDocument.status == status)
    return query.order_by(ComplianceDocument.document_type, ComplianceDocument.created_at.desc()).all()


def create_compliance_document(db: Session, payload: ComplianceDocumentCreate):
    _get_residence(db, payload.residence_id)
    _validate_document_status(payload.status)
    if payload.media_attachment_id:
        _get_media_attachment(db, payload.media_attachment_id)
    existing = db.query(ComplianceDocument).filter(
        ComplianceDocument.residence_id == payload.residence_id,
        ComplianceDocument.document_type == payload.document_type,
        ComplianceDocument.archived_at.is_(None),
    ).first()
    if existing:
        raise HTTPException(409, "Active compliance document already exists for this type")

    document = ComplianceDocument(**payload.model_dump())
    db.add(document)
    db.commit()
    db.refresh(document)
    return document


def get_compliance_document(db: Session, document_id: UUID):
    document = db.query(ComplianceDocument).filter(
        ComplianceDocument.id == document_id,
        ComplianceDocument.archived_at.is_(None),
    ).first()
    if not document:
        raise HTTPException(404, "Compliance document not found")
    return document


def update_compliance_document_status(
    db: Session,
    *,
    document_id: UUID,
    payload: ComplianceDocumentStatusUpdate,
):
    _validate_document_status(payload.status)
    document = get_compliance_document(db, document_id)
    document.status = payload.status
    document.notes = payload.notes if payload.notes is not None else document.notes
    if payload.status in {"approved", "rejected"}:
        document.verified_by = payload.verified_by
        document.verified_at = func.now()
    db.commit()
    db.refresh(document)
    return document


def attach_media_to_compliance_document(
    db: Session,
    *,
    document_id: UUID,
    media_attachment_id: UUID,
):
    document = get_compliance_document(db, document_id)
    _get_media_attachment(db, media_attachment_id)
    document.media_attachment_id = media_attachment_id
    db.commit()
    db.refresh(document)
    return document


def archive_compliance_document(db: Session, document_id: UUID):
    document = get_compliance_document(db, document_id)
    document.archived_at = func.now()
    db.commit()
    db.refresh(document)
    return document


def get_documentation_compliance_report(
    db: Session,
    residence_id: UUID,
    standard: str = "nsfas",
) -> dict:
    _get_residence(db, residence_id)

    documents = list_compliance_documents(db, residence_id=residence_id)
    documents_by_type = {
        document.document_type: document
        for document in documents
    }

    today = date.today()
    total_requirements = len(DEFAULT_REQUIRED_DOCUMENTS) * 3
    passed_requirements = 0
    findings = []
    document_results = []

    for requirement in DEFAULT_REQUIRED_DOCUMENTS:
        document_type = requirement["document_type"]
        document = documents_by_type.get(document_type)

        if not document:
            findings.append({
                "finding_type": "missing_document",
                "severity": requirement["severity"],
                "related_entity_type": "residence",
                "related_entity_id": residence_id,
                "expected_value": "submitted approved document with attachment",
                "actual_value": "missing",
                "message": f"Required document is missing: {requirement['document_name']}.",
            })
            document_results.append({
                **requirement,
                "status": "missing",
                "document_id": None,
                "media_attachment_id": None,
                "expires_at": None,
            })
            continue

        exists_with_attachment = document.media_attachment_id is not None
        if exists_with_attachment:
            passed_requirements += 1
        else:
            findings.append({
                "finding_type": "missing_document",
                "severity": requirement["severity"],
                "related_entity_type": "compliance_document",
                "related_entity_id": document.id,
                "expected_value": "media attachment",
                "actual_value": "none",
                "message": f"{document.document_name} requires an attached document file.",
            })

        if document.status == "approved":
            passed_requirements += 1
        elif document.status == "rejected":
            findings.append({
                "finding_type": "custom",
                "severity": requirement["severity"],
                "related_entity_type": "compliance_document",
                "related_entity_id": document.id,
                "expected_value": "approved",
                "actual_value": "rejected",
                "message": f"{document.document_name} was rejected and must be resubmitted.",
            })
        else:
            findings.append({
                "finding_type": "custom",
                "severity": "medium",
                "related_entity_type": "compliance_document",
                "related_entity_id": document.id,
                "expected_value": "approved",
                "actual_value": document.status,
                "message": f"{document.document_name} is not approved yet.",
            })

        is_expired = document.expires_at is not None and document.expires_at < today
        if document.status == "expired" or is_expired:
            findings.append({
                "finding_type": "expired_document",
                "severity": requirement["severity"],
                "related_entity_type": "compliance_document",
                "related_entity_id": document.id,
                "expected_value": "not expired",
                "actual_value": str(document.expires_at or "expired status"),
                "message": f"{document.document_name} is expired.",
            })
        elif not requirement["requires_expiry"] or document.expires_at:
            passed_requirements += 1
        else:
            findings.append({
                "finding_type": "custom",
                "severity": "medium",
                "related_entity_type": "compliance_document",
                "related_entity_id": document.id,
                "expected_value": "expiry date",
                "actual_value": "none",
                "message": f"{document.document_name} requires an expiry date.",
            })

        document_results.append({
            **requirement,
            "status": "expired" if is_expired else document.status,
            "document_id": document.id,
            "media_attachment_id": document.media_attachment_id,
            "expires_at": document.expires_at,
        })

    score = round((passed_requirements / total_requirements) * 100, 2)

    return {
        "scope_type": "documentation",
        "compliance_type": "documentation",
        "residence_id": residence_id,
        "standard": standard,
        "required_documents": DEFAULT_REQUIRED_DOCUMENTS,
        "document_results": document_results,
        "compliance": {
            "score": score,
            "status": _status_from_score(score),
            "passed_requirements": passed_requirements,
            "total_requirements": total_requirements,
            "findings_count": len(findings),
        },
        "compliance_findings": findings,
        "performance": {
            "message": (
                "Documentation compliance checks document presence, approval, and validity. "
                "Document processing speed or reviewer quality belongs to performance."
            )
        },
    }


def persist_documentation_compliance_check(
    db: Session,
    *,
    report: dict,
    checked_by: UUID | None = None,
):
    check = ComplianceCheck(
        scope_type="documentation",
        scope_id=report["residence_id"],
        standard=report["standard"],
        score=report["compliance"]["score"],
        status=report["compliance"]["status"],
        checked_by=checked_by,
        summary=(
            f"Documentation compliance {report['compliance']['status']} "
            f"with score {report['compliance']['score']}"
        ),
        extra_metadata={
            "required_documents_count": len(report["required_documents"]),
            "findings_count": report["compliance"]["findings_count"],
            "document_results": [
                {
                    **result,
                    "document_id": str(result["document_id"]) if result["document_id"] else None,
                    "media_attachment_id": (
                        str(result["media_attachment_id"]) if result["media_attachment_id"] else None
                    ),
                    "expires_at": str(result["expires_at"]) if result["expires_at"] else None,
                }
                for result in report["document_results"]
            ],
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


def run_documentation_compliance_check(
    db: Session,
    residence_id: UUID,
    standard: str = "nsfas",
    checked_by: UUID | None = None,
):
    report = get_documentation_compliance_report(
        db=db,
        residence_id=residence_id,
        standard=standard,
    )
    check = persist_documentation_compliance_check(db, report=report, checked_by=checked_by)
    report["check_id"] = check.id
    return report


def _get_media_attachment(db: Session, media_attachment_id: UUID):
    attachment = db.query(MediaAttachment).filter(
        MediaAttachment.id == media_attachment_id,
        MediaAttachment.archived_at.is_(None),
    ).first()
    if not attachment:
        raise HTTPException(404, "Media attachment not found")
    return attachment
