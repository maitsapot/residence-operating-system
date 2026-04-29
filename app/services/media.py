import hashlib
import re
import uuid
from datetime import datetime
from pathlib import Path
from uuid import UUID

from fastapi import HTTPException, UploadFile
from sqlalchemy.orm import Session, joinedload
from sqlalchemy.sql import func

from app.models.media import MediaAsset, MediaAttachment
from app.schemas.media import MediaAttachmentCreate

UPLOAD_ROOT = Path("storage/uploads")
MAX_UPLOAD_BYTES = 20 * 1024 * 1024

IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp", "image/gif"}
VIDEO_TYPES = {"video/mp4", "video/quicktime", "video/webm"}
AUDIO_TYPES = {"audio/mpeg", "audio/wav", "audio/webm", "audio/mp4"}
DOCUMENT_TYPES = {
    "application/pdf",
    "text/plain",
    "application/msword",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
}


def infer_media_type(content_type: str, purpose: str | None = None):
    if purpose and "signature" in purpose:
        return "signature"
    if content_type in IMAGE_TYPES:
        return "image"
    if content_type in VIDEO_TYPES:
        return "video"
    if content_type in AUDIO_TYPES:
        return "audio"
    if content_type in DOCUMENT_TYPES:
        return "document"
    return "other"


def sanitize_filename(filename: str):
    safe = re.sub(r"[^A-Za-z0-9._-]+", "-", filename.strip()).strip(".-")
    return safe or "upload"


def _read_upload(file: UploadFile):
    content = file.file.read()
    if len(content) > MAX_UPLOAD_BYTES:
        raise HTTPException(413, "File exceeds maximum upload size")
    if not content:
        raise HTTPException(400, "Uploaded file is empty")
    return content


def create_media_asset_from_upload(
    db: Session,
    *,
    file: UploadFile,
    uploaded_by: UUID | None = None,
    purpose: str | None = None,
):
    content = _read_upload(file)
    checksum = hashlib.sha256(content).hexdigest()
    asset_id = uuid.uuid4()

    original_filename = sanitize_filename(file.filename or "upload")
    extension = Path(original_filename).suffix.lower().lstrip(".") or None
    now = datetime.utcnow()
    storage_dir = UPLOAD_ROOT / str(now.year) / f"{now.month:02d}"
    storage_dir.mkdir(parents=True, exist_ok=True)

    storage_path = storage_dir / f"{asset_id}-{original_filename}"
    storage_path.write_bytes(content)

    content_type = file.content_type or "application/octet-stream"
    asset = MediaAsset(
        id=asset_id,
        storage_provider="local",
        storage_key=storage_path.as_posix(),
        public_url=f"/api/v1/media/{asset_id}/download",
        original_filename=original_filename,
        content_type=content_type,
        file_extension=extension,
        file_size=len(content),
        checksum_sha256=checksum,
        media_type=infer_media_type(content_type, purpose),
        status="available",
        uploaded_by=uploaded_by,
        extra_metadata={},
    )
    db.add(asset)
    db.flush()
    return asset


def create_media_attachment(db: Session, payload: MediaAttachmentCreate):
    asset = db.query(MediaAsset).filter(MediaAsset.id == payload.asset_id).first()
    if not asset:
        raise HTTPException(404, "Media asset not found")

    attachment = MediaAttachment(**payload.model_dump())
    db.add(attachment)
    db.flush()
    db.refresh(attachment)
    return attachment


def upload_media(
    db: Session,
    *,
    file: UploadFile,
    uploaded_by: UUID | None = None,
    owner_type: str | None = None,
    owner_id: UUID | None = None,
    purpose: str = "attachment",
    caption: str | None = None,
    is_primary: bool = False,
    visibility: str = "internal",
):
    try:
        asset = create_media_asset_from_upload(
            db,
            file=file,
            uploaded_by=uploaded_by,
            purpose=purpose,
        )

        attachment = None
        if owner_type or owner_id:
            if not (owner_type and owner_id):
                raise HTTPException(400, "owner_type and owner_id must be provided together")
            attachment = create_media_attachment(
                db,
                MediaAttachmentCreate(
                    asset_id=asset.id,
                    owner_type=owner_type,
                    owner_id=owner_id,
                    purpose=purpose,
                    caption=caption,
                    is_primary=is_primary,
                    visibility=visibility,
                    created_by=uploaded_by,
                ),
            )

        db.commit()
        db.refresh(asset)
        if attachment:
            attachment = get_attachment(db, attachment.id)
        return asset, attachment

    except HTTPException:
        db.rollback()
        raise
    except Exception:
        db.rollback()
        raise


def get_asset(db: Session, asset_id: UUID):
    asset = db.query(MediaAsset).filter(MediaAsset.id == asset_id).first()
    if not asset:
        raise HTTPException(404, "Media asset not found")
    return asset


def get_attachment(db: Session, attachment_id: UUID):
    attachment = db.query(MediaAttachment).options(
        joinedload(MediaAttachment.asset)
    ).filter(MediaAttachment.id == attachment_id).first()
    if not attachment:
        raise HTTPException(404, "Media attachment not found")
    return attachment


def list_assets(
    db: Session,
    *,
    offset: int = 0,
    limit: int = 50,
    media_type: str | None = None,
    uploaded_by: UUID | None = None,
    include_archived: bool = False,
):
    query = db.query(MediaAsset)
    if not include_archived:
        query = query.filter(MediaAsset.archived_at.is_(None))
    if media_type:
        query = query.filter(MediaAsset.media_type == media_type)
    if uploaded_by:
        query = query.filter(MediaAsset.uploaded_by == uploaded_by)
    return query.order_by(MediaAsset.created_at.desc()).offset(offset).limit(limit).all()


def list_attachments(
    db: Session,
    *,
    owner_type: str,
    owner_id: UUID,
    purpose: str | None = None,
    include_archived: bool = False,
):
    query = db.query(MediaAttachment).options(
        joinedload(MediaAttachment.asset)
    ).filter(
        MediaAttachment.owner_type == owner_type,
        MediaAttachment.owner_id == owner_id,
    )
    if not include_archived:
        query = query.filter(MediaAttachment.archived_at.is_(None))
    if purpose:
        query = query.filter(MediaAttachment.purpose == purpose)
    return query.order_by(MediaAttachment.sort_order, MediaAttachment.created_at).all()


def archive_asset(db: Session, asset_id: UUID):
    asset = get_asset(db, asset_id)
    asset.status = "archived"
    asset.archived_at = func.now()
    db.commit()
    db.refresh(asset)
    return asset


def archive_attachment(db: Session, attachment_id: UUID):
    attachment = get_attachment(db, attachment_id)
    attachment.archived_at = func.now()
    db.commit()
    return get_attachment(db, attachment_id)
