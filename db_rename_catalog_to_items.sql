BEGIN;

DO $$
BEGIN
    IF to_regclass('public.catalog') IS NOT NULL THEN
        DROP TABLE IF EXISTS public.items CASCADE;

        ALTER TABLE public.catalog
            RENAME TO items;
    END IF;
END $$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'common_issues'
          AND column_name = 'catalog_id'
    ) THEN
        ALTER TABLE public.common_issues
            RENAME COLUMN catalog_id TO item_id;
    END IF;
END $$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'space_items'
          AND column_name = 'catalog_id'
    ) THEN
        ALTER TABLE public.space_items
            RENAME COLUMN catalog_id TO item_id;
    END IF;
END $$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'space_item_templates'
          AND column_name = 'catalog_id'
    ) THEN
        ALTER TABLE public.space_item_templates
            RENAME COLUMN catalog_id TO item_id;
    END IF;
END $$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'catalog_pkey'
          AND conrelid = 'public.items'::regclass
    ) THEN
        ALTER TABLE public.items
            RENAME CONSTRAINT catalog_pkey TO items_pkey;
    END IF;
END $$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'catalog_category_id_fkey'
          AND conrelid = 'public.items'::regclass
    ) THEN
        ALTER TABLE public.items
            RENAME CONSTRAINT catalog_category_id_fkey TO items_category_id_fkey;
    END IF;
END $$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'catalog_name_key'
          AND conrelid = 'public.items'::regclass
    ) THEN
        ALTER TABLE public.items
            RENAME CONSTRAINT catalog_name_key TO items_name_key;
    END IF;
END $$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'common_issues_catalog_id_fkey'
          AND conrelid = 'public.common_issues'::regclass
    ) THEN
        ALTER TABLE public.common_issues
            RENAME CONSTRAINT common_issues_catalog_id_fkey TO common_issues_item_id_fkey;
    END IF;
END $$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'space_item_templates_catalog_id_fkey'
          AND conrelid = 'public.space_item_templates'::regclass
    ) THEN
        ALTER TABLE public.space_item_templates
            RENAME CONSTRAINT space_item_templates_catalog_id_fkey TO space_item_templates_item_id_fkey;
    END IF;
END $$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_space_item_template_catalog'
          AND conrelid = 'public.space_item_templates'::regclass
    ) THEN
        ALTER TABLE public.space_item_templates
            RENAME CONSTRAINT uq_space_item_template_catalog TO uq_space_item_template_item;
    END IF;
END $$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'space_items_catalog_id_fkey'
          AND conrelid = 'public.space_items'::regclass
    ) THEN
        ALTER TABLE public.space_items
            RENAME CONSTRAINT space_items_catalog_id_fkey TO space_items_item_id_fkey;
    END IF;
END $$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_space_catalog'
          AND conrelid = 'public.space_items'::regclass
    ) THEN
        ALTER TABLE public.space_items
            RENAME CONSTRAINT uq_space_catalog TO uq_space_item;
    END IF;
END $$;

ALTER INDEX IF EXISTS public.idx_catalog_category
    RENAME TO idx_items_category;

ALTER INDEX IF EXISTS public.idx_common_issues_catalog
    RENAME TO idx_common_issues_item;

ALTER INDEX IF EXISTS public.idx_space_item_templates_catalog
    RENAME TO idx_space_item_templates_item;

ALTER INDEX IF EXISTS public.idx_space_items_catalog
    RENAME TO idx_space_items_item;

ALTER TABLE public.items
    DROP CONSTRAINT IF EXISTS catalog_space_type_check;

DROP INDEX IF EXISTS public.idx_catalog_allowed_space_type;

ALTER TABLE public.items
    DROP COLUMN IF EXISTS allowed_space_type;

COMMIT;
