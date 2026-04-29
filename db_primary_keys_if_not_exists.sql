-- Primary key constraints derived from app/models.
-- Skips each primary key when the table is missing or already has a primary key.
-- This file intentionally excludes foreign keys, indexes, unique constraints, and check constraints.

BEGIN;

DO $$
BEGIN
    IF to_regclass('public.caretakers') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE contype = 'p'
             AND conrelid = to_regclass('public.caretakers')
       ) THEN
        ALTER TABLE public.caretakers
            ADD CONSTRAINT caretakers_pkey
            PRIMARY KEY (user_id);
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.catalog') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE contype = 'p'
             AND conrelid = to_regclass('public.catalog')
       ) THEN
        ALTER TABLE public.catalog
            ADD CONSTRAINT catalog_pkey
            PRIMARY KEY (id);
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.categories') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE contype = 'p'
             AND conrelid = to_regclass('public.categories')
       ) THEN
        ALTER TABLE public.categories
            ADD CONSTRAINT categories_pkey
            PRIMARY KEY (id);
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.common_issues') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE contype = 'p'
             AND conrelid = to_regclass('public.common_issues')
       ) THEN
        ALTER TABLE public.common_issues
            ADD CONSTRAINT common_issues_pkey
            PRIMARY KEY (id);
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.companies') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE contype = 'p'
             AND conrelid = to_regclass('public.companies')
       ) THEN
        ALTER TABLE public.companies
            ADD CONSTRAINT companies_pkey
            PRIMARY KEY (id);
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.inspections') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE contype = 'p'
             AND conrelid = to_regclass('public.inspections')
       ) THEN
        ALTER TABLE public.inspections
            ADD CONSTRAINT inspections_pkey
            PRIMARY KEY (id);
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.institutions') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE contype = 'p'
             AND conrelid = to_regclass('public.institutions')
       ) THEN
        ALTER TABLE public.institutions
            ADD CONSTRAINT institutions_pkey
            PRIMARY KEY (id);
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.issue_updates') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE contype = 'p'
             AND conrelid = to_regclass('public.issue_updates')
       ) THEN
        ALTER TABLE public.issue_updates
            ADD CONSTRAINT issue_updates_pkey
            PRIMARY KEY (id);
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.issues') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE contype = 'p'
             AND conrelid = to_regclass('public.issues')
       ) THEN
        ALTER TABLE public.issues
            ADD CONSTRAINT issues_pkey
            PRIMARY KEY (id);
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.items') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE contype = 'p'
             AND conrelid = to_regclass('public.items')
       ) THEN
        ALTER TABLE public.items
            ADD CONSTRAINT items_pkey
            PRIMARY KEY (id);
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.landlords') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE contype = 'p'
             AND conrelid = to_regclass('public.landlords')
       ) THEN
        ALTER TABLE public.landlords
            ADD CONSTRAINT landlords_pkey
            PRIMARY KEY (user_id);
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.locations') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE contype = 'p'
             AND conrelid = to_regclass('public.locations')
       ) THEN
        ALTER TABLE public.locations
            ADD CONSTRAINT locations_pkey
            PRIMARY KEY (id);
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.managers') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE contype = 'p'
             AND conrelid = to_regclass('public.managers')
       ) THEN
        ALTER TABLE public.managers
            ADD CONSTRAINT managers_pkey
            PRIMARY KEY (user_id);
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.nsfas_accreditations') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE contype = 'p'
             AND conrelid = to_regclass('public.nsfas_accreditations')
       ) THEN
        ALTER TABLE public.nsfas_accreditations
            ADD CONSTRAINT nsfas_accreditations_pkey
            PRIMARY KEY (id);
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.residence_caretakers') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE contype = 'p'
             AND conrelid = to_regclass('public.residence_caretakers')
       ) THEN
        ALTER TABLE public.residence_caretakers
            ADD CONSTRAINT residence_caretakers_pkey
            PRIMARY KEY (residence_id, caretaker_id);
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.residence_landlords') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE contype = 'p'
             AND conrelid = to_regclass('public.residence_landlords')
       ) THEN
        ALTER TABLE public.residence_landlords
            ADD CONSTRAINT residence_landlords_pkey
            PRIMARY KEY (residence_id, landlord_id);
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.residence_managers') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE contype = 'p'
             AND conrelid = to_regclass('public.residence_managers')
       ) THEN
        ALTER TABLE public.residence_managers
            ADD CONSTRAINT residence_managers_pkey
            PRIMARY KEY (residence_id, manager_id);
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.residence_staff') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE contype = 'p'
             AND conrelid = to_regclass('public.residence_staff')
       ) THEN
        ALTER TABLE public.residence_staff
            ADD CONSTRAINT residence_staff_pkey
            PRIMARY KEY (residence_id, staff_id);
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.residences') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE contype = 'p'
             AND conrelid = to_regclass('public.residences')
       ) THEN
        ALTER TABLE public.residences
            ADD CONSTRAINT residences_pkey
            PRIMARY KEY (id);
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.space_item_templates') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE contype = 'p'
             AND conrelid = to_regclass('public.space_item_templates')
       ) THEN
        ALTER TABLE public.space_item_templates
            ADD CONSTRAINT space_item_templates_pkey
            PRIMARY KEY (id);
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.space_items') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE contype = 'p'
             AND conrelid = to_regclass('public.space_items')
       ) THEN
        ALTER TABLE public.space_items
            ADD CONSTRAINT space_items_pkey
            PRIMARY KEY (id);
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.spaces') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE contype = 'p'
             AND conrelid = to_regclass('public.spaces')
       ) THEN
        ALTER TABLE public.spaces
            ADD CONSTRAINT spaces_pkey
            PRIMARY KEY (id);
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.staff') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE contype = 'p'
             AND conrelid = to_regclass('public.staff')
       ) THEN
        ALTER TABLE public.staff
            ADD CONSTRAINT staff_pkey
            PRIMARY KEY (id);
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.tenancies') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE contype = 'p'
             AND conrelid = to_regclass('public.tenancies')
       ) THEN
        ALTER TABLE public.tenancies
            ADD CONSTRAINT tenancies_pkey
            PRIMARY KEY (id);
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.tenants') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE contype = 'p'
             AND conrelid = to_regclass('public.tenants')
       ) THEN
        ALTER TABLE public.tenants
            ADD CONSTRAINT tenants_pkey
            PRIMARY KEY (user_id);
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.users') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint
           WHERE contype = 'p'
             AND conrelid = to_regclass('public.users')
       ) THEN
        ALTER TABLE public.users
            ADD CONSTRAINT users_pkey
            PRIMARY KEY (id);
    END IF;
END $$;

COMMIT;
