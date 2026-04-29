-- Check constraints derived from app/models.
-- Skips each constraint when the table is missing or the named constraint already exists.
-- This file intentionally excludes foreign keys, indexes, and unique constraints.

BEGIN;

-- =========================================================
-- Reference value checks
-- =========================================================
DO $$
BEGIN
    IF to_regclass('public.categories') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE conname = 'categories_name_check'
             AND conrelid = to_regclass('public.categories')
       ) THEN
        ALTER TABLE public.categories
            ADD CONSTRAINT categories_name_check
            CHECK (category_name IN ('furniture','structural','electrical','plumbing','appliance','hygiene','security','other'));
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.common_issues') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE conname = 'common_issues_severity_check'
             AND conrelid = to_regclass('public.common_issues')
       ) THEN
        ALTER TABLE public.common_issues
            ADD CONSTRAINT common_issues_severity_check
            CHECK (default_severity IN ('low','medium','high','critical'));
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.common_issues') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE conname = 'common_issues_urgency_check'
             AND conrelid = to_regclass('public.common_issues')
       ) THEN
        ALTER TABLE public.common_issues
            ADD CONSTRAINT common_issues_urgency_check
            CHECK (default_urgency IN ('low','medium','high','urgent'));
    END IF;
END $$;

-- =========================================================
-- Inspection checks
-- =========================================================
DO $$
BEGIN
    IF to_regclass('public.inspections') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE conname = 'chk_inspection_condition'
             AND conrelid = to_regclass('public.inspections')
       ) THEN
        ALTER TABLE public.inspections
            ADD CONSTRAINT chk_inspection_condition
            CHECK (condition IN ('good','fair','poor','damaged'));
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.inspections') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE conname = 'chk_inspection_type'
             AND conrelid = to_regclass('public.inspections')
       ) THEN
        ALTER TABLE public.inspections
            ADD CONSTRAINT chk_inspection_type
            CHECK (inspection_type IN ('routine','checkin','checkout','audit'));
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.inspections') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE conname = 'chk_inspection_status'
             AND conrelid = to_regclass('public.inspections')
       ) THEN
        ALTER TABLE public.inspections
            ADD CONSTRAINT chk_inspection_status
            CHECK (status IN ('draft','completed'));
    END IF;
END $$;

-- =========================================================
-- Issue and issue audit checks
-- =========================================================
DO $$
BEGIN
    IF to_regclass('public.issues') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE conname = 'issues_status_check'
             AND conrelid = to_regclass('public.issues')
       ) THEN
        ALTER TABLE public.issues
            ADD CONSTRAINT issues_status_check
            CHECK (status IN ('open','assigned','in_progress','resolved','closed','rejected'));
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.issues') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE conname = 'issues_severity_check'
             AND conrelid = to_regclass('public.issues')
       ) THEN
        ALTER TABLE public.issues
            ADD CONSTRAINT issues_severity_check
            CHECK (severity IN ('low','medium','high','critical'));
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.issues') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE conname = 'issues_urgency_check'
             AND conrelid = to_regclass('public.issues')
       ) THEN
        ALTER TABLE public.issues
            ADD CONSTRAINT issues_urgency_check
            CHECK (urgency IN ('low','medium','high','urgent'));
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.issues') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE conname = 'issues_cost_check'
             AND conrelid = to_regclass('public.issues')
       ) THEN
        ALTER TABLE public.issues
            ADD CONSTRAINT issues_cost_check
            CHECK ((estimated_cost IS NULL OR estimated_cost >= 0) AND (actual_cost IS NULL OR actual_cost >= 0));
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.issue_updates') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE conname = 'issue_updates_type_check'
             AND conrelid = to_regclass('public.issue_updates')
       ) THEN
        ALTER TABLE public.issue_updates
            ADD CONSTRAINT issue_updates_type_check
            CHECK (update_type IN ('status_change','assignment','comment','system'));
    END IF;
END $$;

-- =========================================================
-- Item and inventory checks
-- =========================================================
DO $$
BEGIN
    IF to_regclass('public.items') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE conname = 'items_condition_check'
             AND conrelid = to_regclass('public.items')
       ) THEN
        ALTER TABLE public.items
            ADD CONSTRAINT items_condition_check
            CHECK (condition IN ('good','fair','poor','damaged'));
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.items') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE conname = 'items_status_check'
             AND conrelid = to_regclass('public.items')
       ) THEN
        ALTER TABLE public.items
            ADD CONSTRAINT items_status_check
            CHECK (status IN ('active','removed','replaced'));
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.items') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE conname = 'items_qr_trackable_check'
             AND conrelid = to_regclass('public.items')
       ) THEN
        ALTER TABLE public.items
            ADD CONSTRAINT items_qr_trackable_check
            CHECK ((qr_code IS NULL) OR (is_trackable = true));
    END IF;
END $$;

-- =========================================================
-- Accreditation, space, template, and tenancy checks
-- =========================================================
DO $$
BEGIN
    IF to_regclass('public.nsfas_accreditations') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE conname = 'chk_nsfas_status'
             AND conrelid = to_regclass('public.nsfas_accreditations')
       ) THEN
        ALTER TABLE public.nsfas_accreditations
            ADD CONSTRAINT chk_nsfas_status
            CHECK (status IN ('pending','approved','rejected','expired'));
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.spaces') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE conname = 'spaces_type_check'
             AND conrelid = to_regclass('public.spaces')
       ) THEN
        ALTER TABLE public.spaces
            ADD CONSTRAINT spaces_type_check
            CHECK (space_type IN ('room','bathroom','kitchen','common','other'));
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.space_items') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE conname = 'space_items_condition_check'
             AND conrelid = to_regclass('public.space_items')
       ) THEN
        ALTER TABLE public.space_items
            ADD CONSTRAINT space_items_condition_check
            CHECK (condition IN ('good','fair','poor','damaged'));
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.space_items') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE conname = 'space_items_status_check'
             AND conrelid = to_regclass('public.space_items')
       ) THEN
        ALTER TABLE public.space_items
            ADD CONSTRAINT space_items_status_check
            CHECK (status IN ('active','removed','missing','damaged'));
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.space_items') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE conname = 'space_items_quantity_check'
             AND conrelid = to_regclass('public.space_items')
       ) THEN
        ALTER TABLE public.space_items
            ADD CONSTRAINT space_items_quantity_check
            CHECK (quantity >= 1);
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.space_item_templates') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE conname = 'chk_space_item_template_type'
             AND conrelid = to_regclass('public.space_item_templates')
       ) THEN
        ALTER TABLE public.space_item_templates
            ADD CONSTRAINT chk_space_item_template_type
            CHECK (space_type IN ('room','bathroom','kitchen','common','other'));
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.space_item_templates') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE conname = 'chk_space_item_template_quantity'
             AND conrelid = to_regclass('public.space_item_templates')
       ) THEN
        ALTER TABLE public.space_item_templates
            ADD CONSTRAINT chk_space_item_template_quantity
            CHECK (default_quantity >= 1);
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.tenancies') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE conname = 'chk_tenancy_status'
             AND conrelid = to_regclass('public.tenancies')
       ) THEN
        ALTER TABLE public.tenancies
            ADD CONSTRAINT chk_tenancy_status
            CHECK (status IN ('active','terminated','completed'));
    END IF;
END $$;

COMMIT;
