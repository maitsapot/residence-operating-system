-- Unique constraints derived from app/models.
-- Skips each constraint when the table is missing or the named constraint already exists.
-- This file intentionally excludes foreign keys, indexes, and check constraints.

BEGIN;

-- =========================================================
-- Reference data uniqueness
-- =========================================================
DO $$
BEGIN
    IF to_regclass('public.users') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE conname = 'users_email_key'
             AND conrelid = to_regclass('public.users')
       ) THEN
        ALTER TABLE public.users
            ADD CONSTRAINT users_email_key
            UNIQUE (email);
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.companies') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE conname = 'companies_registration_number_key'
             AND conrelid = to_regclass('public.companies')
       ) THEN
        ALTER TABLE public.companies
            ADD CONSTRAINT companies_registration_number_key
            UNIQUE (registration_number);
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.institutions') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE conname = 'institutions_name_key'
             AND conrelid = to_regclass('public.institutions')
       ) THEN
        ALTER TABLE public.institutions
            ADD CONSTRAINT institutions_name_key
            UNIQUE (name);
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.categories') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE conname = 'categories_category_name_key'
             AND conrelid = to_regclass('public.categories')
       ) THEN
        ALTER TABLE public.categories
            ADD CONSTRAINT categories_category_name_key
            UNIQUE (category_name);
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.items') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE conname = 'items_name_key'
             AND conrelid = to_regclass('public.items')
       ) THEN
        ALTER TABLE public.items
            ADD CONSTRAINT items_name_key
            UNIQUE (name);
    END IF;
END $$;

-- =========================================================
-- Template and items issue uniqueness
-- =========================================================
DO $$
BEGIN
    IF to_regclass('public.common_issues') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE conname = 'common_issues_unique'
             AND conrelid = to_regclass('public.common_issues')
       ) THEN
        ALTER TABLE public.common_issues
            ADD CONSTRAINT common_issues_unique
            UNIQUE (item_id, issue_name);
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.space_item_templates') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE conname = 'uq_space_item_template_item'
             AND conrelid = to_regclass('public.space_item_templates')
       ) THEN
        ALTER TABLE public.space_item_templates
            ADD CONSTRAINT uq_space_item_template_item
            UNIQUE (template_type, standard, space_type, item_id);
    END IF;
END $$;

-- =========================================================
-- Space inventory uniqueness
-- =========================================================
DO $$
BEGIN
    IF to_regclass('public.space_items') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE conname = 'uq_space_item'
             AND conrelid = to_regclass('public.space_items')
       ) THEN
        ALTER TABLE public.space_items
            ADD CONSTRAINT uq_space_item
            UNIQUE (space_id, item_id);
    END IF;
END $$;

COMMIT;
