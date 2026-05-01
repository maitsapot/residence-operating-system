-- Normalize audit fields across existing databases.
-- Mutable tables get created_at and updated_at. Append-only join/audit tables get created_at.

BEGIN;

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

ALTER TABLE categories
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE common_issues
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE companies
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE institutions
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE locations
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE staff
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE landlords
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE managers
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE caretakers
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE tenants
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE residences
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE spaces
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE tenancies
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE items
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE space_items
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE space_item_templates
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE inspections
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE issues
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE nsfas_accreditations
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE residence_landlords
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE residence_caretakers
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE residence_staff
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE residence_managers
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE issue_updates
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

DO $$
DECLARE
    table_name text;
BEGIN
    FOREACH table_name IN ARRAY ARRAY[
        'categories',
        'common_issues',
        'companies',
        'institutions',
        'locations',
        'users',
        'staff',
        'landlords',
        'managers',
        'caretakers',
        'tenants',
        'residences',
        'spaces',
        'tenancies',
        'items',
        'space_items',
        'space_item_templates',
        'inspections',
        'issues',
        'nsfas_accreditations',
        'residence_managers'
    ]
    LOOP
        EXECUTE format(
            'ALTER TABLE public.%I ALTER COLUMN created_at SET DEFAULT NOW()',
            table_name
        );
        EXECUTE format(
            'ALTER TABLE public.%I ALTER COLUMN updated_at SET DEFAULT NOW()',
            table_name
        );
        EXECUTE format(
            'UPDATE public.%I SET created_at = COALESCE(created_at, NOW()), updated_at = COALESCE(updated_at, created_at, NOW())',
            table_name
        );
        EXECUTE format(
            'DROP TRIGGER IF EXISTS trg_%I_updated_at ON public.%I',
            table_name,
            table_name
        );
        EXECUTE format(
            'CREATE TRIGGER trg_%I_updated_at BEFORE UPDATE ON public.%I FOR EACH ROW EXECUTE FUNCTION public.set_updated_at()',
            table_name,
            table_name
        );
    END LOOP;
END $$;

UPDATE residence_landlords SET created_at = COALESCE(created_at, NOW());
UPDATE residence_caretakers SET created_at = COALESCE(created_at, NOW());
UPDATE residence_staff SET created_at = COALESCE(created_at, NOW());
UPDATE issue_updates SET created_at = COALESCE(created_at, NOW());

COMMIT;
