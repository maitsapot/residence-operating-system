BEGIN;

CREATE TABLE IF NOT EXISTS media_assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    storage_provider TEXT NOT NULL DEFAULT 'local',
    storage_bucket TEXT,
    storage_key TEXT NOT NULL UNIQUE,
    public_url TEXT,
    original_filename TEXT NOT NULL,
    content_type TEXT NOT NULL,
    file_extension TEXT,
    file_size INTEGER NOT NULL,
    checksum_sha256 TEXT NOT NULL,
    media_type TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'available',
    width INTEGER,
    height INTEGER,
    duration_seconds INTEGER,
    uploaded_by UUID REFERENCES users(id) ON DELETE SET NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    archived_at TIMESTAMPTZ,
    CONSTRAINT media_assets_type_check
        CHECK (media_type IN ('image','video','audio','document','signature','other')),
    CONSTRAINT media_assets_status_check
        CHECK (status IN ('pending','available','processing','failed','archived')),
    CONSTRAINT media_assets_file_size_check CHECK (file_size >= 0)
);

CREATE TABLE IF NOT EXISTS media_attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id UUID NOT NULL REFERENCES media_assets(id) ON DELETE CASCADE,
    owner_type TEXT NOT NULL,
    owner_id UUID NOT NULL,
    purpose TEXT NOT NULL DEFAULT 'attachment',
    caption TEXT,
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    visibility TEXT NOT NULL DEFAULT 'internal',
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    archived_at TIMESTAMPTZ,
    CONSTRAINT media_attachments_owner_type_check
        CHECK (
            owner_type IN (
                'user','issue','issue_comment','inspection','item','space','residence',
                'tenancy','common_issue','contractor','vendor','other'
            )
        ),
    CONSTRAINT media_attachments_visibility_check
        CHECK (visibility IN ('internal','tenant_visible','public','private')),
    CONSTRAINT uq_media_attachment_context
        UNIQUE (asset_id, owner_type, owner_id, purpose)
);

CREATE INDEX IF NOT EXISTS idx_media_assets_uploaded_by ON media_assets (uploaded_by);
CREATE INDEX IF NOT EXISTS idx_media_assets_type ON media_assets (media_type);
CREATE INDEX IF NOT EXISTS idx_media_assets_archived_at ON media_assets (archived_at);
CREATE INDEX IF NOT EXISTS idx_media_attachments_owner ON media_attachments (owner_type, owner_id);
CREATE INDEX IF NOT EXISTS idx_media_attachments_asset ON media_attachments (asset_id);
CREATE INDEX IF NOT EXISTS idx_media_attachments_purpose ON media_attachments (purpose);
CREATE INDEX IF NOT EXISTS idx_media_attachments_archived_at ON media_attachments (archived_at);

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_media_assets_updated_at ON media_assets;
CREATE TRIGGER trg_media_assets_updated_at
    BEFORE UPDATE ON media_assets
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_media_attachments_updated_at ON media_attachments;
CREATE TRIGGER trg_media_attachments_updated_at
    BEFORE UPDATE ON media_attachments
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

COMMIT;
