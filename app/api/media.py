from pathlib import Path
from uuid import UUID

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.schemas.media import (
    MediaAssetResponse,
    MediaAttachmentCreate,
    MediaAttachmentResponse,
    MediaUploadResponse,
)
from app.services import media as media_service

router = APIRouter(prefix="/media", tags=["Media"])


@router.post("/upload", response_model=MediaUploadResponse)
def upload_media(
    file: UploadFile = File(...),
    uploaded_by: UUID | None = None,
    owner_type: str | None = None,
    owner_id: UUID | None = None,
    purpose: str = "attachment",
    caption: str | None = None,
    is_primary: bool = False,
    visibility: str = "internal",
    db: Session = Depends(get_db),
):
    asset, attachment = media_service.upload_media(
        db,
        file=file,
        uploaded_by=uploaded_by,
        owner_type=owner_type,
        owner_id=owner_id,
        purpose=purpose,
        caption=caption,
        is_primary=is_primary,
        visibility=visibility,
    )
    return {"asset": asset, "attachment": attachment}


@router.post("/attachments", response_model=MediaAttachmentResponse)
def attach_media(payload: MediaAttachmentCreate, db: Session = Depends(get_db)):
    attachment = media_service.create_media_attachment(db, payload)
    db.commit()
    return media_service.get_attachment(db, attachment.id)


@router.get("/", response_model=list[MediaAssetResponse])
def list_media_assets(
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    media_type: str | None = None,
    uploaded_by: UUID | None = None,
    include_archived: bool = False,
    db: Session = Depends(get_db),
):
    return media_service.list_assets(
        db,
        offset=offset,
        limit=limit,
        media_type=media_type,
        uploaded_by=uploaded_by,
        include_archived=include_archived,
    )


@router.get("/attachments", response_model=list[MediaAttachmentResponse])
def list_media_attachments(
    owner_type: str,
    owner_id: UUID,
    purpose: str | None = None,
    include_archived: bool = False,
    db: Session = Depends(get_db),
):
    return media_service.list_attachments(
        db,
        owner_type=owner_type,
        owner_id=owner_id,
        purpose=purpose,
        include_archived=include_archived,
    )


@router.get("/{asset_id}", response_model=MediaAssetResponse)
def get_media_asset(asset_id: UUID, db: Session = Depends(get_db)):
    return media_service.get_asset(db, asset_id)


@router.get("/{asset_id}/download")
def download_media(asset_id: UUID, db: Session = Depends(get_db)):
    asset = media_service.get_asset(db, asset_id)
    if asset.storage_provider != "local":
        raise HTTPException(400, "Only local media can be downloaded by this endpoint")

    path = Path(asset.storage_key)
    if not path.exists():
        raise HTTPException(404, "Stored file not found")

    return FileResponse(
        path=path,
        media_type=asset.content_type,
        filename=asset.original_filename,
    )


@router.delete("/{asset_id}", response_model=MediaAssetResponse)
def archive_media_asset(asset_id: UUID, db: Session = Depends(get_db)):
    return media_service.archive_asset(db, asset_id)


@router.delete("/attachments/{attachment_id}", response_model=MediaAttachmentResponse)
def archive_media_attachment(attachment_id: UUID, db: Session = Depends(get_db)):
    return media_service.archive_attachment(db, attachment_id)
