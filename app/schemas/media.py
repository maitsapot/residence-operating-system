from datetime import datetime
from typing import Any, Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class MediaAttachmentCreate(BaseModel):
    asset_id: UUID
    owner_type: str
    owner_id: UUID
    purpose: str = "attachment"
    caption: Optional[str] = None
    sort_order: int = 0
    is_primary: bool = False
    visibility: str = "internal"
    created_by: Optional[UUID] = None


class MediaAssetResponse(BaseModel):
    id: UUID
    storage_provider: str
    storage_bucket: Optional[str]
    storage_key: str
    public_url: Optional[str]
    original_filename: str
    content_type: str
    file_extension: Optional[str]
    file_size: int
    checksum_sha256: str
    media_type: str
    status: str
    width: Optional[int]
    height: Optional[int]
    duration_seconds: Optional[int]
    uploaded_by: Optional[UUID]
    extra_metadata: dict[str, Any]
    created_at: Optional[datetime]
    updated_at: Optional[datetime]
    archived_at: Optional[datetime]

    model_config = ConfigDict(from_attributes=True)


class MediaAttachmentResponse(BaseModel):
    id: UUID
    asset_id: UUID
    owner_type: str
    owner_id: UUID
    purpose: str
    caption: Optional[str]
    sort_order: int
    is_primary: bool
    visibility: str
    created_by: Optional[UUID]
    created_at: Optional[datetime]
    updated_at: Optional[datetime]
    archived_at: Optional[datetime]
    asset: Optional[MediaAssetResponse] = None

    model_config = ConfigDict(from_attributes=True)


class MediaUploadResponse(BaseModel):
    asset: MediaAssetResponse
    attachment: Optional[MediaAttachmentResponse] = None
