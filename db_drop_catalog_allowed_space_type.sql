BEGIN;

ALTER TABLE public.catalog
    DROP CONSTRAINT IF EXISTS catalog_space_type_check;

DROP INDEX IF EXISTS public.idx_catalog_allowed_space_type;

ALTER TABLE public.catalog
    DROP COLUMN IF EXISTS allowed_space_type;

COMMIT;
