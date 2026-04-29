-- Foreign key relationships derived from app/models.
-- This file intentionally excludes indexes, unique constraints, and check constraints.

BEGIN;

-- =========================================================
-- Role profiles
-- =========================================================
ALTER TABLE public.caretakers
    ADD CONSTRAINT caretakers_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES public.users(id)
    ON DELETE CASCADE;

ALTER TABLE public.caretakers
    ADD CONSTRAINT caretakers_company_id_fkey
    FOREIGN KEY (company_id)
    REFERENCES public.companies(id)
    ON DELETE SET NULL;

ALTER TABLE public.landlords
    ADD CONSTRAINT landlords_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES public.users(id)
    ON DELETE CASCADE;

ALTER TABLE public.landlords
    ADD CONSTRAINT landlords_company_id_fkey
    FOREIGN KEY (company_id)
    REFERENCES public.companies(id)
    ON DELETE SET NULL;

ALTER TABLE public.managers
    ADD CONSTRAINT managers_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES public.users(id)
    ON DELETE CASCADE;

ALTER TABLE public.managers
    ADD CONSTRAINT managers_company_id_fkey
    FOREIGN KEY (company_id)
    REFERENCES public.companies(id)
    ON DELETE SET NULL;

ALTER TABLE public.staff
    ADD CONSTRAINT staff_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES public.users(id)
    ON DELETE CASCADE;

ALTER TABLE public.staff
    ADD CONSTRAINT staff_company_id_fkey
    FOREIGN KEY (company_id)
    REFERENCES public.companies(id)
    ON DELETE SET NULL;

ALTER TABLE public.tenants
    ADD CONSTRAINT tenants_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES public.users(id)
    ON DELETE CASCADE;

ALTER TABLE public.tenants
    ADD CONSTRAINT tenants_institution_id_fkey
    FOREIGN KEY (institution_id)
    REFERENCES public.institutions(id)
    ON DELETE SET NULL;

-- =========================================================
-- Reference and ownership
-- =========================================================
ALTER TABLE public.users
    ADD CONSTRAINT users_location_id_fkey
    FOREIGN KEY (location_id)
    REFERENCES public.locations(id);

ALTER TABLE public.companies
    ADD CONSTRAINT companies_location_id_fkey
    FOREIGN KEY (location_id)
    REFERENCES public.locations(id);

ALTER TABLE public.institutions
    ADD CONSTRAINT institutions_parent_id_fkey
    FOREIGN KEY (parent_id)
    REFERENCES public.institutions(id);

ALTER TABLE public.institutions
    ADD CONSTRAINT institutions_location_id_fkey
    FOREIGN KEY (location_id)
    REFERENCES public.locations(id);

-- =========================================================
-- Catalog and templates
-- =========================================================
ALTER TABLE public.catalog
    ADD CONSTRAINT catalog_category_id_fkey
    FOREIGN KEY (category_id)
    REFERENCES public.categories(id)
    ON DELETE RESTRICT;

ALTER TABLE public.common_issues
    ADD CONSTRAINT common_issues_catalog_id_fkey
    FOREIGN KEY (catalog_id)
    REFERENCES public.catalog(id)
    ON DELETE CASCADE;

ALTER TABLE public.space_item_templates
    ADD CONSTRAINT space_item_templates_catalog_id_fkey
    FOREIGN KEY (catalog_id)
    REFERENCES public.catalog(id)
    ON DELETE RESTRICT;

-- =========================================================
-- Residences and residence role links
-- =========================================================
ALTER TABLE public.residences
    ADD CONSTRAINT residences_company_id_fkey
    FOREIGN KEY (company_id)
    REFERENCES public.companies(id);

ALTER TABLE public.residences
    ADD CONSTRAINT residences_location_id_fkey
    FOREIGN KEY (location_id)
    REFERENCES public.locations(id);

ALTER TABLE public.residence_landlords
    ADD CONSTRAINT residence_landlords_residence_id_fkey
    FOREIGN KEY (residence_id)
    REFERENCES public.residences(id)
    ON DELETE CASCADE;

ALTER TABLE public.residence_landlords
    ADD CONSTRAINT residence_landlords_landlord_id_fkey
    FOREIGN KEY (landlord_id)
    REFERENCES public.landlords(user_id)
    ON DELETE CASCADE;

ALTER TABLE public.residence_caretakers
    ADD CONSTRAINT residence_caretakers_residence_id_fkey
    FOREIGN KEY (residence_id)
    REFERENCES public.residences(id)
    ON DELETE CASCADE;

ALTER TABLE public.residence_caretakers
    ADD CONSTRAINT residence_caretakers_caretaker_id_fkey
    FOREIGN KEY (caretaker_id)
    REFERENCES public.caretakers(user_id)
    ON DELETE CASCADE;

ALTER TABLE public.residence_managers
    ADD CONSTRAINT residence_managers_residence_id_fkey
    FOREIGN KEY (residence_id)
    REFERENCES public.residences(id)
    ON DELETE CASCADE;

ALTER TABLE public.residence_managers
    ADD CONSTRAINT residence_managers_manager_id_fkey
    FOREIGN KEY (manager_id)
    REFERENCES public.managers(user_id)
    ON DELETE CASCADE;

ALTER TABLE public.residence_staff
    ADD CONSTRAINT residence_staff_residence_id_fkey
    FOREIGN KEY (residence_id)
    REFERENCES public.residences(id)
    ON DELETE CASCADE;

ALTER TABLE public.residence_staff
    ADD CONSTRAINT residence_staff_staff_id_fkey
    FOREIGN KEY (staff_id)
    REFERENCES public.staff(id)
    ON DELETE CASCADE;

ALTER TABLE public.nsfas_accreditations
    ADD CONSTRAINT nsfas_accreditations_residence_id_fkey
    FOREIGN KEY (residence_id)
    REFERENCES public.residences(id)
    ON DELETE CASCADE;

-- =========================================================
-- Spaces, items, and tenancies
-- =========================================================
ALTER TABLE public.spaces
    ADD CONSTRAINT spaces_residence_id_fkey
    FOREIGN KEY (residence_id)
    REFERENCES public.residences(id)
    ON DELETE CASCADE;

ALTER TABLE public.space_items
    ADD CONSTRAINT space_items_space_id_fkey
    FOREIGN KEY (space_id)
    REFERENCES public.spaces(id)
    ON DELETE CASCADE;

ALTER TABLE public.space_items
    ADD CONSTRAINT space_items_catalog_id_fkey
    FOREIGN KEY (catalog_id)
    REFERENCES public.catalog(id)
    ON DELETE RESTRICT;

ALTER TABLE public.items
    ADD CONSTRAINT items_space_id_fkey
    FOREIGN KEY (space_id)
    REFERENCES public.spaces(id)
    ON DELETE CASCADE;

ALTER TABLE public.items
    ADD CONSTRAINT items_catalog_id_fkey
    FOREIGN KEY (catalog_id)
    REFERENCES public.catalog(id)
    ON DELETE RESTRICT;

ALTER TABLE public.tenancies
    ADD CONSTRAINT tenancies_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES public.users(id)
    ON DELETE CASCADE;

ALTER TABLE public.tenancies
    ADD CONSTRAINT tenancies_space_id_fkey
    FOREIGN KEY (space_id)
    REFERENCES public.spaces(id)
    ON DELETE CASCADE;

-- =========================================================
-- Inspections, issues, and issue updates
-- =========================================================
ALTER TABLE public.inspections
    ADD CONSTRAINT inspections_space_item_id_fkey
    FOREIGN KEY (space_item_id)
    REFERENCES public.space_items(id);

ALTER TABLE public.inspections
    ADD CONSTRAINT inspections_inspected_by_fkey
    FOREIGN KEY (inspected_by)
    REFERENCES public.users(id);

ALTER TABLE public.inspections
    ADD CONSTRAINT inspections_tenancy_id_fkey
    FOREIGN KEY (tenancy_id)
    REFERENCES public.tenancies(id);

ALTER TABLE public.issues
    ADD CONSTRAINT issues_reported_by_fkey
    FOREIGN KEY (reported_by)
    REFERENCES public.users(id);

ALTER TABLE public.issues
    ADD CONSTRAINT issues_assigned_to_fkey
    FOREIGN KEY (assigned_to)
    REFERENCES public.users(id);

ALTER TABLE public.issues
    ADD CONSTRAINT issues_space_id_fkey
    FOREIGN KEY (space_id)
    REFERENCES public.spaces(id);

ALTER TABLE public.issues
    ADD CONSTRAINT issues_space_item_id_fkey
    FOREIGN KEY (space_item_id)
    REFERENCES public.space_items(id);

ALTER TABLE public.issues
    ADD CONSTRAINT issues_inspection_id_fkey
    FOREIGN KEY (inspection_id)
    REFERENCES public.inspections(id);

ALTER TABLE public.issues
    ADD CONSTRAINT issues_tenancy_id_fkey
    FOREIGN KEY (tenancy_id)
    REFERENCES public.tenancies(id);

ALTER TABLE public.issues
    ADD CONSTRAINT issues_common_issue_id_fkey
    FOREIGN KEY (common_issue_id)
    REFERENCES public.common_issues(id);

ALTER TABLE public.issue_updates
    ADD CONSTRAINT issue_updates_issue_id_fkey
    FOREIGN KEY (issue_id)
    REFERENCES public.issues(id)
    ON DELETE CASCADE;

ALTER TABLE public.issue_updates
    ADD CONSTRAINT issue_updates_updated_by_fkey
    FOREIGN KEY (updated_by)
    REFERENCES public.users(id)
    ON DELETE SET NULL;

COMMIT;
