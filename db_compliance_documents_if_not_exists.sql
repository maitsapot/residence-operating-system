BEGIN;

CREATE TABLE IF NOT EXISTS compliance_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    residence_id UUID NOT NULL REFERENCES residences(id) ON DELETE CASCADE,
    document_type TEXT NOT NULL,
    document_name TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'submitted',
    issued_at DATE,
    expires_at DATE,
    verified_by UUID REFERENCES users(id) ON DELETE SET NULL,
    verified_at TIMESTAMPTZ,
    media_attachment_id UUID REFERENCES media_attachments(id) ON DELETE SET NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    archived_at TIMESTAMPTZ,
    CONSTRAINT compliance_documents_status_check
        CHECK (status IN ('missing','submitted','approved','rejected','expired'))
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_compliance_document_active_type
    ON compliance_documents (residence_id, document_type)
    WHERE archived_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_compliance_documents_residence
    ON compliance_documents (residence_id);
CREATE INDEX IF NOT EXISTS idx_compliance_documents_type
    ON compliance_documents (document_type);
CREATE INDEX IF NOT EXISTS idx_compliance_documents_status
    ON compliance_documents (status);
CREATE INDEX IF NOT EXISTS idx_compliance_documents_expires_at
    ON compliance_documents (expires_at);
CREATE INDEX IF NOT EXISTS idx_compliance_documents_archived_at
    ON compliance_documents (archived_at);

ALTER TABLE compliance_documents
    ALTER COLUMN id SET DEFAULT gen_random_uuid(),
    ALTER COLUMN status SET DEFAULT 'submitted';

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_compliance_documents_updated_at ON compliance_documents;
CREATE TRIGGER trg_compliance_documents_updated_at
    BEFORE UPDATE ON compliance_documents
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

COMMIT;
