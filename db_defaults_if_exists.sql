-- Column defaults derived from app/models and operational insert needs.
-- Skips each default when the table or column is missing.

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
BEGIN
    IF to_regclass('public.users') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'users'
             AND column_name = 'is_active'
       ) THEN
        ALTER TABLE public.users
            ALTER COLUMN is_active SET DEFAULT true;
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.categories') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'categories'
             AND column_name = 'id'
       ) THEN
        ALTER TABLE public.categories
            ALTER COLUMN id SET DEFAULT gen_random_uuid();
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.catalog') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'catalog'
             AND column_name = 'id'
       ) THEN
        ALTER TABLE public.catalog
            ALTER COLUMN id SET DEFAULT gen_random_uuid();
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.common_issues') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'common_issues'
             AND column_name = 'id'
       ) THEN
        ALTER TABLE public.common_issues
            ALTER COLUMN id SET DEFAULT gen_random_uuid();
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.inspections') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'inspections'
             AND column_name = 'id'
       ) THEN
        ALTER TABLE public.inspections
            ALTER COLUMN id SET DEFAULT gen_random_uuid();
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.issues') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'issues'
             AND column_name = 'id'
       ) THEN
        ALTER TABLE public.issues
            ALTER COLUMN id SET DEFAULT gen_random_uuid();
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.issue_updates') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'issue_updates'
             AND column_name = 'id'
       ) THEN
        ALTER TABLE public.issue_updates
            ALTER COLUMN id SET DEFAULT gen_random_uuid();
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.items') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'items'
             AND column_name = 'id'
       ) THEN
        ALTER TABLE public.items
            ALTER COLUMN id SET DEFAULT gen_random_uuid();
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.nsfas_accreditations') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'nsfas_accreditations'
             AND column_name = 'id'
       ) THEN
        ALTER TABLE public.nsfas_accreditations
            ALTER COLUMN id SET DEFAULT gen_random_uuid();
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.space_items') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'space_items'
             AND column_name = 'id'
       ) THEN
        ALTER TABLE public.space_items
            ALTER COLUMN id SET DEFAULT gen_random_uuid();
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.space_item_templates') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'space_item_templates'
             AND column_name = 'id'
       ) THEN
        ALTER TABLE public.space_item_templates
            ALTER COLUMN id SET DEFAULT gen_random_uuid();
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.categories') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'categories'
             AND column_name = 'is_trackable'
       ) THEN
        ALTER TABLE public.categories
            ALTER COLUMN is_trackable SET DEFAULT false;
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.categories') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'categories'
             AND column_name = 'is_active'
       ) THEN
        ALTER TABLE public.categories
            ALTER COLUMN is_active SET DEFAULT true;
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.catalog') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'catalog'
             AND column_name = 'is_trackable'
       ) THEN
        ALTER TABLE public.catalog
            ALTER COLUMN is_trackable SET DEFAULT true;
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.catalog') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'catalog'
             AND column_name = 'default_quantity'
       ) THEN
        ALTER TABLE public.catalog
            ALTER COLUMN default_quantity SET DEFAULT 1;
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.catalog') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'catalog'
             AND column_name = 'is_active'
       ) THEN
        ALTER TABLE public.catalog
            ALTER COLUMN is_active SET DEFAULT true;
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.common_issues') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'common_issues'
             AND column_name = 'default_severity'
       ) THEN
        ALTER TABLE public.common_issues
            ALTER COLUMN default_severity SET DEFAULT 'medium';
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.common_issues') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'common_issues'
             AND column_name = 'default_urgency'
       ) THEN
        ALTER TABLE public.common_issues
            ALTER COLUMN default_urgency SET DEFAULT 'medium';
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.common_issues') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'common_issues'
             AND column_name = 'is_other'
       ) THEN
        ALTER TABLE public.common_issues
            ALTER COLUMN is_other SET DEFAULT false;
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.common_issues') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'common_issues'
             AND column_name = 'is_active'
       ) THEN
        ALTER TABLE public.common_issues
            ALTER COLUMN is_active SET DEFAULT true;
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.space_item_templates') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'space_item_templates'
             AND column_name = 'template_type'
       ) THEN
        ALTER TABLE public.space_item_templates
            ALTER COLUMN template_type SET DEFAULT 'single_room';
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.space_item_templates') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'space_item_templates'
             AND column_name = 'standard'
       ) THEN
        ALTER TABLE public.space_item_templates
            ALTER COLUMN standard SET DEFAULT 'nsfas';
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.space_item_templates') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'space_item_templates'
             AND column_name = 'default_quantity'
       ) THEN
        ALTER TABLE public.space_item_templates
            ALTER COLUMN default_quantity SET DEFAULT 1;
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.space_item_templates') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'space_item_templates'
             AND column_name = 'is_required'
       ) THEN
        ALTER TABLE public.space_item_templates
            ALTER COLUMN is_required SET DEFAULT true;
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.space_items') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'space_items'
             AND column_name = 'quantity'
       ) THEN
        ALTER TABLE public.space_items
            ALTER COLUMN quantity SET DEFAULT 1;
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.space_items') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'space_items'
             AND column_name = 'is_required'
       ) THEN
        ALTER TABLE public.space_items
            ALTER COLUMN is_required SET DEFAULT true;
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.space_items') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'space_items'
             AND column_name = 'condition'
       ) THEN
        ALTER TABLE public.space_items
            ALTER COLUMN condition SET DEFAULT 'good';
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.space_items') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'space_items'
             AND column_name = 'status'
       ) THEN
        ALTER TABLE public.space_items
            ALTER COLUMN status SET DEFAULT 'active';
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.items') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'items'
             AND column_name = 'condition'
       ) THEN
        ALTER TABLE public.items
            ALTER COLUMN condition SET DEFAULT 'good';
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.items') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'items'
             AND column_name = 'status'
       ) THEN
        ALTER TABLE public.items
            ALTER COLUMN status SET DEFAULT 'active';
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.inspections') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'inspections'
             AND column_name = 'inspection_type'
       ) THEN
        ALTER TABLE public.inspections
            ALTER COLUMN inspection_type SET DEFAULT 'routine';
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.inspections') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'inspections'
             AND column_name = 'inspector_signed_off'
       ) THEN
        ALTER TABLE public.inspections
            ALTER COLUMN inspector_signed_off SET DEFAULT false;
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.inspections') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'inspections'
             AND column_name = 'tenant_signed_off'
       ) THEN
        ALTER TABLE public.inspections
            ALTER COLUMN tenant_signed_off SET DEFAULT false;
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.inspections') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'inspections'
             AND column_name = 'status'
       ) THEN
        ALTER TABLE public.inspections
            ALTER COLUMN status SET DEFAULT 'draft';
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.issues') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'issues'
             AND column_name = 'status'
       ) THEN
        ALTER TABLE public.issues
            ALTER COLUMN status SET DEFAULT 'open';
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.issues') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'issues'
             AND column_name = 'severity'
       ) THEN
        ALTER TABLE public.issues
            ALTER COLUMN severity SET DEFAULT 'medium';
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.issues') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'issues'
             AND column_name = 'urgency'
       ) THEN
        ALTER TABLE public.issues
            ALTER COLUMN urgency SET DEFAULT 'medium';
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.residence_managers') IS NOT NULL
       AND EXISTS (
           SELECT 1
           FROM information_schema.columns
           WHERE table_schema = 'public'
             AND table_name = 'residence_managers'
             AND column_name = 'is_primary'
       ) THEN
        ALTER TABLE public.residence_managers
            ALTER COLUMN is_primary SET DEFAULT false;
    END IF;
END $$;

COMMIT;
