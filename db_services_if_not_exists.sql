BEGIN;

CREATE TABLE IF NOT EXISTS services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    archived_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS residence_services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    residence_id UUID NOT NULL REFERENCES residences(id) ON DELETE CASCADE,
    service_id UUID NOT NULL REFERENCES services(id) ON DELETE RESTRICT,
    provider_type TEXT NOT NULL DEFAULT 'internal',
    provider_id UUID,
    status TEXT NOT NULL DEFAULT 'active',
    started_at DATE,
    ended_at DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    archived_at TIMESTAMPTZ,
    CONSTRAINT residence_services_provider_type_check
        CHECK (provider_type IN ('internal','contractor','vendor','company','other')),
    CONSTRAINT residence_services_status_check
        CHECK (status IN ('active','paused','cancelled','ended'))
);

CREATE INDEX IF NOT EXISTS idx_services_name
    ON services (name);
CREATE INDEX IF NOT EXISTS idx_services_archived_at
    ON services (archived_at);
CREATE INDEX IF NOT EXISTS idx_residence_services_residence
    ON residence_services (residence_id);
CREATE INDEX IF NOT EXISTS idx_residence_services_service
    ON residence_services (service_id);
CREATE INDEX IF NOT EXISTS idx_residence_services_status
    ON residence_services (status);
CREATE INDEX IF NOT EXISTS idx_residence_services_provider
    ON residence_services (provider_type, provider_id);
CREATE INDEX IF NOT EXISTS idx_residence_services_archived_at
    ON residence_services (archived_at);

ALTER TABLE services
    ALTER COLUMN id SET DEFAULT gen_random_uuid(),
    ALTER COLUMN is_active SET DEFAULT TRUE;

ALTER TABLE residence_services
    ALTER COLUMN id SET DEFAULT gen_random_uuid(),
    ALTER COLUMN provider_type SET DEFAULT 'internal',
    ALTER COLUMN status SET DEFAULT 'active';

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_services_updated_at ON services;
CREATE TRIGGER trg_services_updated_at
    BEFORE UPDATE ON services
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_residence_services_updated_at ON residence_services;
CREATE TRIGGER trg_residence_services_updated_at
    BEFORE UPDATE ON residence_services
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

COMMIT;
