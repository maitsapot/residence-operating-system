BEGIN;

ALTER TABLE institutions
    ALTER COLUMN institution_type TYPE TEXT,
    ALTER COLUMN institution_type SET NOT NULL;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM institutions
        WHERE institution_type NOT IN ('university','tvet','private_college')
    ) THEN
        RAISE EXCEPTION 'Cannot add institutions_type_check while invalid institution_type values exist';
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.institutions') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE conname = 'institutions_type_check'
             AND conrelid = to_regclass('public.institutions')
       ) THEN
        ALTER TABLE public.institutions
            ADD CONSTRAINT institutions_type_check
            CHECK (institution_type IN ('university','tvet','private_college'));
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.institutions') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE conname = 'institutions_parent_not_self_check'
             AND conrelid = to_regclass('public.institutions')
       ) THEN
        ALTER TABLE public.institutions
            ADD CONSTRAINT institutions_parent_not_self_check
            CHECK (parent_id IS NULL OR parent_id <> id);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_institutions_type
    ON institutions (institution_type);
CREATE INDEX IF NOT EXISTS idx_institutions_parent_type
    ON institutions (parent_id, institution_type);

COMMIT;
