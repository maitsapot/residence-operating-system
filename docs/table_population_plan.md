# Table Population Plan

Last updated: 2026-04-30

This document tracks the order for building realistic test data across the database.

Policy:

- Populate `TEST_DATABASE_URL` first.
- Verify each step before moving to the next.
- Ask before applying the same seed data to dev.
- Commit seed scripts after each stable data milestone.
- Keep compliance and performance data separate.

## Current Status

- Current step: **Step 5 - Users**
- Latest completed step: **Step 3 - Companies**
- Latest seed milestone: **Company seed data**
- Latest test DB seed: **8 categories, 16 institutions/locations, and 10 companies inserted**

## Population Progress

- [x] Step 1: Categories
- [x] Step 2: Locations
- [x] Step 3: Companies
- [x] Step 4: Institutions
- [ ] Step 5: Users
- [ ] Step 6: Role Tables
- [ ] Step 7: Residences
- [ ] Step 8: Residence Role Assignments
- [ ] Step 9: Services
- [ ] Step 10: Residence Services
- [ ] Step 11: Items
- [ ] Step 12: Common Issues
- [ ] Step 13: Spaces
- [ ] Step 14: Space Item Templates
- [ ] Step 15: Space Items
- [ ] Step 16: Tenancies
- [ ] Step 17: Compliance Rules
- [ ] Step 18: Compliance Documents And Media
- [ ] Step 19: NSFAS Accreditations
- [ ] Step 20: Inspections
- [ ] Step 21: Issues
- [ ] Step 22: Issue Updates
- [ ] Step 23: Compliance Checks And Findings
- [ ] Step 24: Performance Ratings
- [ ] Step 25: Performance Checks And Findings
- [ ] Step 26: Dashboard Verification

## Step Details

### Step 1: Categories

Status: **Complete**

Tables:

- `categories`

Seeded categories:

- `furniture`
- `appliance`
- `electrical`
- `plumbing`
- `security`
- `hygiene`
- `structural`
- `other`

Script:

- `db_seed_categories.sql`

### Step 2: Locations

Status: **Complete for institution seed data**

Tables:

- `locations`

Purpose:

- Provide reusable addresses for companies, institutions, users, and residences.

Recommended data:

- 1 company office location
- 1 institution campus location
- 3 residence locations
- 8 user home/profile locations

Seeded institution locations:

- University of Johannesburg campuses
- Central Johannesburg TVET College campuses
- Rosebank College Braamfontein campus
- University of Limpopo Turfloop location

### Step 3: Companies

Status: **Complete for initial company seed data**

Tables:

- `companies`

Depends on:

- `locations`

Purpose:

- Create property/operator companies that own or manage residences and employ staff.

Recommended data:

- 1 primary property management company
- 1 secondary service/vendor company if needed later

Seeded companies:

- Nolwazi Property Management
- Ubuntu Student Housing
- Turfloop Residence Services
- Hatfield Accommodation Group
- Berea Facilities Management
- Cape Student Living
- Mangaung Residence Operators
- Bay Campus Housing
- Lowveld Student Accommodation
- North West Residence Partners

Script:

- `db_seed_companies.sql`

### Step 4: Institutions

Status: **Complete for initial institution seed data**

Tables:

- `institutions`

Depends on:

- `locations`

Purpose:

- Create universities/colleges for student context and future reporting.

Recommended data:

- 1 university
- Optional child campus/institution if supported by current schema.

Seeded data:

- University of Johannesburg plus four campuses
- Central Johannesburg TVET College plus seven campuses
- Rosebank College plus Braamfontein campus
- University of Limpopo

Hierarchy rule:

- `parent_id IS NULL` means the legal/main institution.
- `parent_id IS NOT NULL` means the institution record is a satellite/campus.
- API responses expose `is_satellite` as a computed field.

### Step 5: Users

Tables:

- `users`

Depends on:

- `locations`

Purpose:

- Create people that can become landlords, managers, caretakers, staff, tenants, inspectors, and reporters.

Recommended data:

- 1 landlord user
- 1 manager user
- 1 caretaker user
- 1 staff user
- 4 tenant/student users
- 1 inspector/admin user if not reusing manager

### Step 6: Role Tables

Tables:

- `landlords`
- `managers`
- `caretakers`
- `staff`
- `tenants`

Depends on:

- `users`
- `companies` where applicable

Purpose:

- Assign users into operational roles.

### Step 7: Residences

Tables:

- `residences`

Depends on:

- `locations`
- `companies`

Purpose:

- Create residences for room, residence, documentation, service, issue, compliance, and performance flows.

Recommended data:

- 1 strong/compliant residence
- 1 partially compliant residence
- 1 poor-performing residence

### Step 8: Residence Role Assignments

Tables:

- `residence_landlords`
- `residence_managers`
- `residence_caretakers`
- `residence_staff`

Depends on:

- `residences`
- role tables

Purpose:

- Link landlords, managers, caretakers, and staff to residences.

### Step 9: Services

Tables:

- `services`

Purpose:

- Seed service catalog.

Recommended services:

- `cleaning`
- `wifi`
- `security`
- `laundry`
- `maintenance`

### Step 10: Residence Services

Tables:

- `residence_services`

Depends on:

- `residences`
- `services`

Purpose:

- Assign services to residences for service performance tracking.

### Step 11: Items

Tables:

- `items`

Depends on:

- `categories`

Purpose:

- Create inventory/catalog items used in spaces, templates, issues, and compliance.

Recommended data:

- Furniture: bed, mattress, study table, study chair, wardrobe
- Appliances: fridge, stove, microwave, kettle, TV
- Plumbing: toilet, shower, basin, tap, geyser
- Electrical: light, plug point, distribution board
- Security: door lock, gate, camera
- Hygiene: bin, soap dispenser
- Structural: door, window, ceiling, floor

### Step 12: Common Issues

Tables:

- `common_issues`

Depends on:

- `items`

Purpose:

- Provide issue templates for item problems and automated issue creation.

Recommended data:

- Damaged
- Missing
- Not working
- Dirty/unsafe where applicable

### Step 13: Spaces

Tables:

- `spaces`

Depends on:

- `residences`

Purpose:

- Create rooms and shared spaces.

Recommended data:

- Rooms: at least 6 rooms across residences
- Shared spaces: kitchen, bathroom, common/TV room, laundry/other

### Step 14: Space Item Templates

Tables:

- `space_item_templates`

Depends on:

- `items`

Purpose:

- Define required item templates for room and shared-space compliance.

Recommended templates:

- Room templates for NSFAS-style room compliance
- Kitchen templates
- Bathroom templates
- Common room templates

### Step 15: Space Items

Tables:

- `space_items`

Depends on:

- `spaces`
- `items`

Purpose:

- Place actual items in rooms and shared spaces.

Recommended data:

- Compliant room with full required items
- Non-compliant room missing one required item
- Room with required item present but damaged
- Shared spaces with missing/shortfall items

### Step 16: Tenancies

Tables:

- `tenancies`

Depends on:

- `users`
- `tenants`
- `spaces`

Purpose:

- Assign students to rentable rooms.

### Step 17: Compliance Rules

Tables:

- `compliance_rules`
- `compliance_rule_requirements`

Depends on:

- `items`

Purpose:

- Seed auditable compliance rules and requirements.

Recommended data:

- Room required item rules
- Residence required shared-space rules
- Documentation required document rules

### Step 18: Compliance Documents And Media

Tables:

- `media_assets`
- `media_attachments`
- `compliance_documents`

Depends on:

- `residences`
- `users`

Purpose:

- Add document records and media links for documentation compliance.

Recommended data:

- Approved valid documents
- Missing documents
- Expired documents
- Rejected documents

### Step 19: NSFAS Accreditations

Tables:

- `nsfas_accreditations`

Depends on:

- `residences`

Purpose:

- Add accreditation-specific records.

### Step 20: Inspections

Tables:

- `inspections`

Depends on:

- `space_items`
- `users`
- `tenancies`

Purpose:

- Add condition history and issue-generation signals.

Recommended data:

- Good inspection
- Fair inspection
- Damaged inspection
- Completed routine inspection

### Step 21: Issues

Tables:

- `issues`

Depends on:

- `users`
- `spaces`
- `space_items`
- `common_issues`
- `inspections`
- `tenancies`

Purpose:

- Add active and resolved maintenance issues for operational and performance flows.

### Step 22: Issue Updates

Tables:

- `issue_updates`

Depends on:

- `issues`
- `users`

Purpose:

- Add issue status history and assignment audit trail.

### Step 23: Compliance Checks And Findings

Tables:

- `compliance_checks`
- `compliance_findings`

Depends on:

- compliance modules and seeded residence/room/document data

Purpose:

- Persist room, residence, documentation, and overall compliance snapshots.

### Step 24: Performance Ratings

Tables:

- `performance_ratings`

Depends on:

- `users`
- `space_items`
- `spaces`
- `residences`
- `residence_services`

Purpose:

- Add student/service ratings for performance tracking.

### Step 25: Performance Checks And Findings

Tables:

- `performance_checks`
- `performance_findings`

Depends on:

- performance ratings
- issues
- inspections

Purpose:

- Persist performance snapshots and findings.

### Step 26: Dashboard Verification

Tables:

- Reads many tables.

Purpose:

- Verify dashboard endpoints can show meaningful compliance and performance data.

Checks:

- Compliance summary has room, residence, documentation, and overall signals.
- Performance summary has ratings, issues, inspection condition, and service signals.
- Trend endpoints return history.
- Export-ready report includes compliance and performance sections.
