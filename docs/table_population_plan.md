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

- Current step: **Step 21 - Issues**
- Latest completed step: **Step 20 - Inspections**
- Latest seed milestone: **Inspections applied to test and dev**
- Latest test DB seed: **8 categories, 16 institutions/locations, 14 companies, 405 seeded room tenants, role assignments, 10 residences, residence-institution links, 11 services, 110 residence-service assignments, 38 items, 190 common issues, 39 space item templates, 365 room spaces, 6,715 space items, 365 active tenancies, 57 compliance rules, 57 compliance rule requirements, 70 compliance documents, 63 linked media documents, 10 NSFAS accreditations, and 6,715 inspections inserted**

## Population Progress

- [x] Step 1: Categories
- [x] Step 2: Locations
- [x] Step 3: Companies
- [x] Step 4: Institutions
- [x] Step 5: Users
- [x] Step 6: Role Tables
- [x] Step 7: Residences
- [x] Step 8: Residence Role Assignments
- [x] Step 9: Services
- [x] Step 10: Residence Services
- [x] Step 11: Items
- [x] Step 12: Common Issues
- [x] Step 13: Spaces
- [x] Step 14: Space Item Templates
- [x] Step 15: Space Items
- [x] Step 16: Tenancies
- [x] Step 17: Compliance Rules
- [x] Step 18: Compliance Documents And Media
- [x] Step 19: NSFAS Accreditations
- [x] Step 20: Inspections
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
- Amelia Property Group
- Dimbedzi Bakwena
- Ebenizer
- Meshalu Projects

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

Status: **Complete in test and dev databases**

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

Seeded requested users:

- Ashley Mathe
- Abel Lebepe
- Merriam Lebepe
- Mololo Mathe
- Karabo Mathe
- Tebogo Maitsapo
- Nick Sebati
- Aluwani Mphaphuli
- Cindy Ramawa

Seeded additional users:

- Thabo Mokoena
- Sibusiso Dlamini
- Mandla Nkosi
- Tshepo Molefe
- Kabelo Radebe
- Lethabo Mahlangu
- Bongani Khumalo
- Mpho Maseko
- Neo Mabena
- Katlego Molepo
- Lerato Ndlovu
- Nomsa Mthembu
- Anele Sithole
- Zanele Mkhize
- Refilwe Mogale
- Buhle Ntuli
- Nokuthula Dube
- Palesa Moletsane
- Nthabiseng Mokoena
- Kgomotso Ramaloko

Script:

- `db_seed_users.sql`

Identity coverage:

- 15 users include middle names.
- 23 users include South African-style 13-digit ID numbers.
- 11 users include secondary phone numbers.
- Tebogo Isaac Maitsapo uses ID number `8509085610089` and date of birth `1985-09-08`.

### Step 6: Role Tables

Status: **Complete in test and dev databases**

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

Seeded role data:

- 9 landlords: Ashley Mathe, Abel Lebepe, Merriam Lebepe, Mololo Mathe, Karabo Mathe, Tebogo Isaac Maitsapo, Nick Sebati, Aluwani Mphaphuli, Cindy Ramawa.
- 5 managers: Thabo Mokoena, Sibusiso Dlamini, Mandla Nkosi, Tshepo Molefe, Kabelo Radebe.
- 2 staff: Lethabo Mahlangu and Bongani Khumalo.
- 13 tenants: all remaining seeded users.

Tenant contact model:

- Tenants now reference other `users` for emergency contact, guardian, and authorized proxy.
- Relationship text remains flexible, for example `older brother`, `aunt`, `residence paperwork proxy`, or `billing proxy`.
- Old embedded tenant contact name/phone/proxy columns are replaced by user foreign keys.

Scripts:

- `db_tenant_contact_user_refs_if_not_exists.sql`
- `db_seed_roles.sql`

### Step 7: Residences

Tables:

- `residences`
- `residence_institutions`

Depends on:

- `locations`
- `companies`
- `institutions`

Purpose:

- Create residences for room, residence, documentation, service, issue, compliance, and performance flows.
- Link each residence to the institution it primarily serves.

Recommended data:

- 1 strong/compliant residence
- 1 partially compliant residence
- 1 poor-performing residence

Status: **Complete in test and dev databases**

Prepared data:

- Amelia Residence
- Dimbedzi Bakwena Residence
- Mathe Residence
- Kayla Loft
- Ebinizer Student Residence
- Kingsway Student House
- Doornfontein Heights
- Parktown College Residence
- Braamfontein Rose Residence
- Mankweng Green Residence

University of Limpopo residence rules:

- Amelia Residence, Dimbedzi Bakwena Residence, Mathe Residence, Kayla Loft, and Ebinizer Student Residence are linked to University of Limpopo through `residence_institutions`.
- Their locations use province `Limpopo`, city `Mankweng`, and suburb `Turfloop`.

Scripts:

- `db_residence_institutions_if_not_exists.sql`
- `db_seed_residences.sql`

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

Status: **Complete in test and dev databases**

Prepared requested assignments:

- Amelia Residence: Tebogo Maitsapo as landlord, Tshepo Nyanga as primary manager, Kamogelo Monyepao as caretaker, Nation Mphahle as University of Limpopo student.
- Dimbedzi Bakwena Residence: Abel Lebepe and Merriam Lebepe as landlords, Karabo Morena as primary manager, Thomas Letsoalo as caretaker, Puno Puno as University of Limpopo student.
- Mathe Residence: Karabo Mathe, Ashley Mathe, and Moloko Mathe as landlords, Talent Siaka as primary manager, Patience Marumo as University of Limpopo student.
- Kayla Loft: Aluwani Mphaphuli as landlord and Ntate Mphahlele as primary manager.
- Ebinizer Student Residence: Cindy Ramawa as landlord and Nick Hugo as primary manager.

Additional random residences have landlords and primary managers assigned for broader test coverage.

### Step 9: Services

Tables:

- `services`

Status: **Complete in test and dev databases**

Purpose:

- Seed service catalog.

Recommended services:

- `Cleaning`: shared-space cleaning, room turnover cleaning, hygiene checks, and cleaning schedules.
- `WiFi`: internet availability, uptime, router issues, bandwidth complaints, and provider performance.
- `Security`: guarding, cameras, visitor logs, safety incidents, and general residence safety operations.
- `Maintenance`: general repairs for plumbing, electrical, furniture, appliances, doors, windows, and structure.
- `Laundry`: laundry room access, washing machine availability, machine faults, and related service quality.
- `Waste Management`: refuse collection, bin availability, recycling, illegal dumping, and hygiene risks.
- `Pest Control`: scheduled fumigation, pest complaints, and health or safety follow-up.
- `Fire Safety`: extinguishers, alarms, evacuation signage, fire inspections, and fire compliance support.
- `Water Supply`: water interruptions, tank supply, pressure problems, leaks, and water service quality.
- `Backup Power`: load-shedding backup, generators, inverters, battery systems, and backup power reliability.
- `Access Control`: keys, tags, biometric access, gate remotes, room access records, and entry control faults.

Script:

- `db_seed_services.sql`

### Step 10: Residence Services

Tables:

- `residence_services`

Status: **Complete in test and dev databases**

Depends on:

- `residences`
- `services`

Purpose:

- Assign services to residences for service performance tracking.

Prepared data:

- All 10 seeded residences receive all 11 seeded services.
- Provider types vary across `internal`, `company`, `contractor`, and `vendor`.
- Most assignments are active, with a few paused/ended records for workflow coverage.

Script:

- `db_seed_residence_services.sql`

### Step 11: Items

Tables:

- `items`

Status: **Complete in test and dev databases**

Depends on:

- `categories`

Purpose:

- Create inventory/catalog items used in spaces, templates, issues, and compliance.

Recommended data:

- Furniture: Bed Base, Mattress, Chair, Study Table, Wardrobe, BookShelf, Food Rack, Curtain
- Appliances: Fridge, Two-Plate Stove, Microwave, Kettle, Iron, Television
- Plumbing: Toilet, Shower, Basin, Tap, Geyser
- Electrical: Light Fitting, Plug Point, Distribution Board, Extension Lead
- Security: Door Lock, Burglar Bars, Security Gate, CCTV Camera, Fire Extinguisher
- Hygiene: Waste Bin, Mop Bucket, Soap Dispenser, Toilet Brush
- Structural: Door, Window, Ceiling, Curtain Rail, Floor
- Other: Notice Board

Script:

- `db_seed_items.sql`

### Step 12: Common Issues

Tables:

- `common_issues`

Status: **Complete in test and dev databases**

Depends on:

- `items`

Purpose:

- Provide issue templates for item problems and automated issue creation.

Recommended data:

- Damaged
- Missing
- Not working
- Dirty/unsafe where applicable

Prepared data:

- Every seeded item has concise frontend issue options.
- Each item includes an `Other issue` fallback.
- Severity and urgency defaults are prefilled for issue creation and automation.

Script:

- `db_seed_common_issues.sql`

### Step 13: Spaces

Tables:

- `spaces`

Status: **Complete in test and dev databases**

Depends on:

- `residences`

Purpose:

- Create rooms and shared spaces.

Recommended data:

- Rooms: at least 6 rooms across residences
- Shared spaces: kitchen, bathroom, common/TV room, laundry/other

Prepared data:

- Amelia Residence: 20 `single_room` rooms and 7 `ensuite` rooms.
- Dimbedzi Bakwena Residence: 40 `single_room` rooms.
- Mathe Residence: 22 `ensuite` rooms.
- Kayla Loft: 100 `single_room` rooms.
- Ebinizer Student Residence: 40 `ensuite` rooms.
- Remaining seeded residences receive random `single_room` and `ensuite` room mixes.
- All seeded rooms use `standard = nsfas`, `space_type = room`, `is_rentable = true`, and capacity `1`.

Script:

- `db_seed_spaces.sql`

### Step 14: Space Item Templates

Tables:

- `space_item_templates`

Status: **Complete in test and dev databases**

Depends on:

- `items`

Purpose:

- Define required item templates for room and shared-space compliance.

Recommended templates:

- NSFAS `single_room` template for room compliance
- NSFAS `ensuite` template with all `single_room` items plus bathroom items
- Kitchen templates
- Bathroom templates
- Common room templates

Prepared data:

- `single_room` includes essential room furniture, structure, electrical, privacy, security, and hygiene items.
- `ensuite` includes everything in `single_room`, plus Toilet, Shower, Basin, Tap, and Geyser.
- These templates use standard `nsfas` and are intended for the Limpopo University of Limpopo residence rooms when spaces are seeded.

Script:

- `db_seed_space_item_templates.sql`

### Step 15: Space Items

Tables:

- `space_items`

Status: **Complete in test and dev databases**

Depends on:

- `spaces`
- `items`

Purpose:

- Place actual items in rooms and shared spaces.
- Represent the items owned by each space or room.

Recommended data:

- Compliant room with full required items
- Non-compliant room missing one required item
- Room with required item present but damaged
- Shared spaces with missing/shortfall items

Prepared data:

- All seeded room spaces receive owned `space_items` from their assigned NSFAS template.
- `single_room` rooms receive 17 owned item rows.
- `ensuite` rooms receive 22 owned item rows.
- Most items are active/good, with deterministic fair, poor, damaged, and missing examples for testing compliance and issue flows.

Script:

- `db_seed_space_items.sql`

### Step 16: Tenancies

Tables:

- `tenancies`

Status: **Complete in test and dev databases**

Depends on:

- `users`
- `tenants`
- `spaces`

Purpose:

- Assign students to rentable rooms.

Prepared data:

- Creates one active tenancy per seeded rentable room.
- Creates synthetic student users and tenant profiles for seeded rooms.
- Each tenant profile uses an `institution_id` from the residence's primary `residence_institutions` link.

Script:

- `db_seed_tenancies.sql`

### Step 17: Compliance Rules

Tables:

- `compliance_rules`
- `compliance_rule_requirements`

Status: **Complete in test and dev databases**

Depends on:

- `items`

Purpose:

- Seed auditable compliance rules and requirements.

Recommended data:

- Room required item rules
- Residence required shared-space rules
- Documentation required document rules

Drafted data:

- NSFAS room required item rules from the seeded `single_room` and `ensuite` templates.
- Custom room usability rules for active/usable owned room items.
- Residence rules for shared spaces, bathroom ratio, role assignments, institution link, and capacity alignment.
- Documentation rules for NSFAS accreditation, fire safety, occupancy, municipal approval, house rules, pest control, and emergency planning.

Script:

- `db_seed_compliance_rules.sql`

### Step 18: Compliance Documents And Media

Tables:

- `media_assets`
- `media_attachments`
- `compliance_documents`

Status: **Complete in test and dev databases**

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

Prepared data:

- Seeds all seven NSFAS documentation rule document types for every seeded residence.
- Creates media assets and residence attachments for submitted, approved, rejected, and expired documents.
- Keeps missing compliance documents without media attachments so document compliance can report negative findings.
- Includes a realistic status spread across approved, submitted, expired, rejected, and missing.

Script:

- `db_seed_compliance_documents_media.sql`

### Step 19: NSFAS Accreditations

Tables:

- `nsfas_accreditations`

Status: **Complete in test and dev databases**

Depends on:

- `residences`

Purpose:

- Add accreditation-specific records.

Prepared data:

- One NSFAS accreditation row per seeded residence.
- Approved records for most residences, plus pending, rejected, and expired examples.
- Approved capacity follows each residence's seeded room capacity.
- Document URLs link to seeded NSFAS accreditation media where available.

Script:

- `db_seed_nsfas_accreditations.sql`

### Step 20: Inspections

Tables:

- `inspections`

Status: **Complete in test and dev databases**

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

Prepared data:

- One completed inspection per seeded room-owned `space_item`.
- Inspections are linked to the active tenancy for each room.
- The primary residence manager is used as the inspector.
- Conditions mirror seeded `space_items`, with routine, check-in, and audit inspection types.
- Poor, damaged, and missing items include inspection image URLs for later media/issue flows.

Script:

- `db_seed_inspections.sql`

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
