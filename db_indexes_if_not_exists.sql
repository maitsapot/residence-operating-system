-- Indexes derived from app/models and common API query paths.
-- This file intentionally excludes foreign keys, unique constraints, and check constraints.

BEGIN;

-- =========================================================
-- Users and reference data
-- =========================================================
CREATE INDEX IF NOT EXISTS idx_users_location
    ON public.users (location_id);

CREATE INDEX IF NOT EXISTS idx_users_cellphone
    ON public.users (cellphone);

CREATE INDEX IF NOT EXISTS idx_companies_location
    ON public.companies (location_id);

CREATE INDEX IF NOT EXISTS idx_institutions_location
    ON public.institutions (location_id);

CREATE INDEX IF NOT EXISTS idx_institutions_parent
    ON public.institutions (parent_id);

-- =========================================================
-- Role profiles
-- =========================================================
CREATE INDEX IF NOT EXISTS idx_caretakers_company
    ON public.caretakers (company_id);

CREATE INDEX IF NOT EXISTS idx_landlords_company
    ON public.landlords (company_id);

CREATE INDEX IF NOT EXISTS idx_managers_company
    ON public.managers (company_id);

CREATE INDEX IF NOT EXISTS idx_staff_user
    ON public.staff (user_id);

CREATE INDEX IF NOT EXISTS idx_staff_company
    ON public.staff (company_id);

CREATE INDEX IF NOT EXISTS idx_tenants_institution
    ON public.tenants (institution_id);

-- =========================================================
-- Items and templates
-- =========================================================
CREATE INDEX IF NOT EXISTS idx_items_category
    ON public.items (category_id);

CREATE INDEX IF NOT EXISTS idx_common_issues_item
    ON public.common_issues (item_id);

CREATE INDEX IF NOT EXISTS idx_common_issues_active
    ON public.common_issues (is_active);

CREATE INDEX IF NOT EXISTS idx_space_item_templates_item
    ON public.space_item_templates (item_id);

CREATE INDEX IF NOT EXISTS idx_space_item_templates_lookup
    ON public.space_item_templates (template_type, standard, space_type);

-- =========================================================
-- Residences and role links
-- =========================================================
CREATE INDEX IF NOT EXISTS idx_residences_company
    ON public.residences (company_id);

CREATE INDEX IF NOT EXISTS idx_residences_location
    ON public.residences (location_id);

CREATE INDEX IF NOT EXISTS idx_residence_landlords_residence
    ON public.residence_landlords (residence_id);

CREATE INDEX IF NOT EXISTS idx_residence_landlords_landlord
    ON public.residence_landlords (landlord_id);

CREATE INDEX IF NOT EXISTS idx_residence_caretakers_residence
    ON public.residence_caretakers (residence_id);

CREATE INDEX IF NOT EXISTS idx_residence_caretakers_caretaker
    ON public.residence_caretakers (caretaker_id);

CREATE INDEX IF NOT EXISTS idx_residence_managers_residence
    ON public.residence_managers (residence_id);

CREATE INDEX IF NOT EXISTS idx_residence_managers_manager
    ON public.residence_managers (manager_id);

CREATE INDEX IF NOT EXISTS idx_residence_managers_primary
    ON public.residence_managers (residence_id, is_primary);

CREATE INDEX IF NOT EXISTS idx_residence_staff_residence
    ON public.residence_staff (residence_id);

CREATE INDEX IF NOT EXISTS idx_residence_staff_staff
    ON public.residence_staff (staff_id);

CREATE INDEX IF NOT EXISTS idx_nsfas_accreditations_residence
    ON public.nsfas_accreditations (residence_id);

-- =========================================================
-- Spaces, inventory, and tenancies
-- =========================================================
CREATE INDEX IF NOT EXISTS idx_spaces_residence
    ON public.spaces (residence_id);

CREATE INDEX IF NOT EXISTS idx_spaces_type
    ON public.spaces (space_type);

CREATE INDEX IF NOT EXISTS idx_spaces_rentable
    ON public.spaces (is_rentable);

CREATE INDEX IF NOT EXISTS idx_space_items_space
    ON public.space_items (space_id);

CREATE INDEX IF NOT EXISTS idx_space_items_item
    ON public.space_items (item_id);

CREATE INDEX IF NOT EXISTS idx_space_items_status
    ON public.space_items (status);

CREATE INDEX IF NOT EXISTS idx_space_items_condition_status
    ON public.space_items (condition, status);

CREATE INDEX IF NOT EXISTS idx_tenancies_user
    ON public.tenancies (user_id);

CREATE INDEX IF NOT EXISTS idx_tenancies_space
    ON public.tenancies (space_id);

CREATE INDEX IF NOT EXISTS idx_tenancies_status
    ON public.tenancies (status);

CREATE INDEX IF NOT EXISTS idx_tenancies_active_space
    ON public.tenancies (space_id, status);

CREATE INDEX IF NOT EXISTS idx_tenancies_active_user
    ON public.tenancies (user_id, status);

-- =========================================================
-- Inspections, issues, and audit history
-- =========================================================
CREATE INDEX IF NOT EXISTS idx_inspections_space_item
    ON public.inspections (space_item_id);

CREATE INDEX IF NOT EXISTS idx_inspections_inspected_by
    ON public.inspections (inspected_by);

CREATE INDEX IF NOT EXISTS idx_inspections_tenancy
    ON public.inspections (tenancy_id);

CREATE INDEX IF NOT EXISTS idx_inspections_status
    ON public.inspections (status);

CREATE INDEX IF NOT EXISTS idx_inspections_type
    ON public.inspections (inspection_type);

CREATE INDEX IF NOT EXISTS idx_issues_reported_by
    ON public.issues (reported_by);

CREATE INDEX IF NOT EXISTS idx_issues_assigned_to
    ON public.issues (assigned_to);

CREATE INDEX IF NOT EXISTS idx_issues_space
    ON public.issues (space_id);

CREATE INDEX IF NOT EXISTS idx_issues_space_item
    ON public.issues (space_item_id);

CREATE INDEX IF NOT EXISTS idx_issues_inspection
    ON public.issues (inspection_id);

CREATE INDEX IF NOT EXISTS idx_issues_tenancy
    ON public.issues (tenancy_id);

CREATE INDEX IF NOT EXISTS idx_issues_common_issue
    ON public.issues (common_issue_id);

CREATE INDEX IF NOT EXISTS idx_issues_status
    ON public.issues (status);

CREATE INDEX IF NOT EXISTS idx_issues_assigned_status
    ON public.issues (assigned_to, status);

CREATE INDEX IF NOT EXISTS idx_issue_updates_issue
    ON public.issue_updates (issue_id);

CREATE INDEX IF NOT EXISTS idx_issue_updates_updated_by
    ON public.issue_updates (updated_by);

COMMIT;
