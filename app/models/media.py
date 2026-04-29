import uuid

from sqlalchemy import Boolean, CheckConstraint, Column, ForeignKey, Index, Integer, Text, UniqueConstraint
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from sqlalchemy.types import TIMESTAMP

from app.core.database import Base


class MediaAsset(Base):
    __tablename__ = "media_assets"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    storage_provider = Column(Text, nullable=False, default="local")
    storage_bucket = Column(Text, nullable=True)
    storage_key = Column(Text, nullable=False, unique=True)
    public_url = Column(Text, nullable=True)

    original_filename = Column(Text, nullable=False)
    content_type = Column(Text, nullable=False)
    file_extension = Column(Text, nullable=True)
    file_size = Column(Integer, nullable=False)
    checksum_sha256 = Column(Text, nullable=False)

    media_type = Column(Text, nullable=False)
    status = Column(Text, nullable=False, default="available")

    width = Column(Integer, nullable=True)
    height = Column(Integer, nullable=True)
    duration_seconds = Column(Integer, nullable=True)

    uploaded_by = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"))
    extra_metadata = Column("metadata", JSONB, nullable=False, default=dict)

    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now())
    archived_at = Column(TIMESTAMP(timezone=True), nullable=True)

    attachments = relationship("MediaAttachment", back_populates="asset")

    __table_args__ = (
        CheckConstraint(
            "media_type IN ('image','video','audio','document','signature','other')",
            name="media_assets_type_check",
        ),
        CheckConstraint(
            "status IN ('pending','available','processing','failed','archived')",
            name="media_assets_status_check",
        ),
        CheckConstraint("file_size >= 0", name="media_assets_file_size_check"),
        Index("idx_media_assets_uploaded_by", "uploaded_by"),
        Index("idx_media_assets_type", "media_type"),
        Index("idx_media_assets_archived_at", "archived_at"),
    )


class MediaAttachment(Base):
    __tablename__ = "media_attachments"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    asset_id = Column(UUID(as_uuid=True), ForeignKey("media_assets.id", ondelete="CASCADE"), nullable=False)

    owner_type = Column(Text, nullable=False)
    owner_id = Column(UUID(as_uuid=True), nullable=False)

    purpose = Column(Text, nullable=False, default="attachment")
    caption = Column(Text, nullable=True)
    sort_order = Column(Integer, nullable=False, default=0)
    is_primary = Column(Boolean, nullable=False, default=False)
    visibility = Column(Text, nullable=False, default="internal")

    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"))

    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now())
    archived_at = Column(TIMESTAMP(timezone=True), nullable=True)

    asset = relationship("MediaAsset", back_populates="attachments")

    __table_args__ = (
        CheckConstraint(
            "owner_type IN ("
            "'user','issue','issue_comment','inspection','item','space','residence',"
            "'tenancy','common_issue','contractor','vendor','other'"
            ")",
            name="media_attachments_owner_type_check",
        ),
        CheckConstraint(
            "visibility IN ('internal','tenant_visible','public','private')",
            name="media_attachments_visibility_check",
        ),
        UniqueConstraint("asset_id", "owner_type", "owner_id", "purpose", name="uq_media_attachment_context"),
        Index("idx_media_attachments_owner", "owner_type", "owner_id"),
        Index("idx_media_attachments_asset", "asset_id"),
        Index("idx_media_attachments_purpose", "purpose"),
        Index("idx_media_attachments_archived_at", "archived_at"),
    )
