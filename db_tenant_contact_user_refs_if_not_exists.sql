BEGIN;

ALTER TABLE public.tenants
    ADD COLUMN IF NOT EXISTS emergency_contact_user_id uuid,
    ADD COLUMN IF NOT EXISTS guardian_user_id uuid,
    ADD COLUMN IF NOT EXISTS guardian_relationship text,
    ADD COLUMN IF NOT EXISTS authorized_proxy_user_id uuid,
    ADD COLUMN IF NOT EXISTS authorized_proxy_relationship text;

ALTER TABLE public.tenants
    DROP COLUMN IF EXISTS emergency_contact_name,
    DROP COLUMN IF EXISTS emergency_contact_phone,
    DROP COLUMN IF EXISTS proxy_contact_name,
    DROP COLUMN IF EXISTS proxy_contact_phone,
    DROP COLUMN IF EXISTS proxy_contact_relationship;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'tenants_emergency_contact_user_id_fkey'
          AND conrelid = 'public.tenants'::regclass
    ) THEN
        ALTER TABLE public.tenants
            ADD CONSTRAINT tenants_emergency_contact_user_id_fkey
            FOREIGN KEY (emergency_contact_user_id)
            REFERENCES public.users(id)
            ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'tenants_guardian_user_id_fkey'
          AND conrelid = 'public.tenants'::regclass
    ) THEN
        ALTER TABLE public.tenants
            ADD CONSTRAINT tenants_guardian_user_id_fkey
            FOREIGN KEY (guardian_user_id)
            REFERENCES public.users(id)
            ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'tenants_authorized_proxy_user_id_fkey'
          AND conrelid = 'public.tenants'::regclass
    ) THEN
        ALTER TABLE public.tenants
            ADD CONSTRAINT tenants_authorized_proxy_user_id_fkey
            FOREIGN KEY (authorized_proxy_user_id)
            REFERENCES public.users(id)
            ON DELETE SET NULL;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_tenants_emergency_contact_user
    ON public.tenants (emergency_contact_user_id);

CREATE INDEX IF NOT EXISTS idx_tenants_guardian_user
    ON public.tenants (guardian_user_id);

CREATE INDEX IF NOT EXISTS idx_tenants_authorized_proxy_user
    ON public.tenants (authorized_proxy_user_id);

COMMIT;
