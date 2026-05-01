# Compliance And Performance Roadmap

This document tracks the planned expansion of the ROS compliance and performance system.

## Current Progress

- Current phase: **Complete - Compliance And Performance Roadmap**
- Phase 1 status: **Complete**
- Phase 2 status: **Complete**
- Phase 3 status: **Complete - residence shared spaces, bathroom ratio, assignments, shared-space item requirements, persistence, endpoints, and tests implemented**
- Phase 4 status: **Complete - compliance documents, required document checks, media links, expiry/review workflow, persisted documentation checks, endpoints, and tests implemented**
- Phase 5 status: **Complete - weighted overall compliance combines room, residence, and documentation compliance without performance signals**
- Phase 6 status: **Complete - performance ratings with target categories, media support, summaries, archival, endpoints, and tests implemented**
- Phase 7 status: **Complete - service catalog, residence service assignments, service ratings, performance summaries, endpoints, and tests implemented**
- Phase 8 status: **Complete - performance checks aggregate ratings, issue backlog, SLA breaches, and inspection condition into persisted findings**
- Phase 9 status: **Complete - performance findings create linked issues, prevent duplicates, and resolved issues improve future performance checks**
- Phase 10 status: **Complete - dashboard summaries, trend history, and export-ready reports keep compliance and performance separated**
- Latest verification: **2026-04-30 - `venv/bin/python -m pytest` passed with 41 tests**
- Latest DB update: **2026-04-30 - Phase 8 `performance_checks` and `performance_findings` patch applied and verified on both `TEST_DATABASE_URL` and dev `DATABASE_URL`**
- Last updated: **2026-04-30**
- DB policy: schema changes are applied to `TEST_DATABASE_URL` first. Apply to dev only after explicit approval.

### Phase Progress

- [x] Phase 1: Rename And Clarify Existing Compliance
- [x] Phase 2: Add Compliance Persistence
- [x] Phase 3: Build Residence Compliance
- [x] Phase 4: Add Documentation Compliance
- [x] Phase 5: Add Overall Compliance
- [x] Phase 6: Add Performance Ratings
- [x] Phase 7: Add Services And Service Performance
- [x] Phase 8: Add Performance Aggregation
- [x] Phase 9: Connect Performance To Issues
- [x] Phase 10: Dashboards And Reporting

The core principle:

- **Compliance** answers: does the room, residence, document, or service meet the required standard?
- **Performance** answers: how well is the asset, space, service, or provider performing over time?

Compliance and performance must remain separate, even when they influence each other.

## 1. Define The Domain Boundaries

### 1.1 Room Compliance

Room compliance applies to private/rentable student rooms.

Scope:

- `space_type = room`
- Room inventory requirements
- Room capacity requirements
- Room template requirements

Examples:

- Bed exists.
- Mattress exists.
- Study table exists.
- Study chair exists.
- Wardrobe/cupboard exists.
- Required quantity matches room capacity.
- Required space items are generated from the correct template.

Important distinction:

- A study chair being present is compliance.
- A study chair being broken is performance, unless the standard explicitly requires it to be usable/good for compliance.

### 1.2 Residence Compliance

Residence compliance applies to shared spaces, residence facilities, operational readiness, and residence-wide rules.

Scope:

- `space_type = kitchen`
- `space_type = bathroom`
- `space_type = common`
- `space_type = other`
- Residence-level entities and assignments

Examples:

- Kitchen exists.
- TV room/common room exists.
- Bathrooms exist.
- Toilet/shower ratios satisfy resident capacity.
- Fire equipment exists.
- Laundry area exists if required.
- Residence has assigned landlord/manager/caretaker.
- Total capacity is defined.
- Shared spaces satisfy required templates.

Important distinction:

- A kitchen existing is residence compliance.
- A dirty kitchen or broken stove is performance.

### 1.3 Documentation And Certification Compliance

Documentation compliance applies to required proof, licenses, accreditations, and recurring certificates.

Scope:

- NSFAS accreditation documents
- Fire safety certificate
- Occupancy certificate
- Lease/operating documents
- Company/landlord verification
- Inspection certificates
- Insurance documents
- Municipal or institutional approval documents

Examples:

- Certificate exists.
- Certificate is valid.
- Certificate is not expired.
- Certificate is attached to the correct residence.
- Required document has been reviewed/approved.

### 1.4 Overall Compliance

Overall compliance combines compliance components only.

Inputs:

- Room compliance
- Residence compliance
- Documentation/certification compliance
- Future compliance modules

It should not include student satisfaction, broken-item ratings, or service responsiveness unless a legal/standard rule explicitly requires it.

### 1.5 Performance

Performance measures condition, quality, responsiveness, and student experience.

Scope:

- Space item condition
- Space condition
- Residence condition
- Maintenance performance
- Contractor/vendor performance
- Service quality
- Student ratings
- Issue resolution performance
- SLA performance

Examples:

- Bed condition.
- Kitchen cleanliness.
- Wi-Fi service quality.
- Maintenance response time.
- Open issue backlog.
- Student rating for a stove, kitchen, TV room, room, or cleaning service.

## 2. Define Score Types And Statuses

### 2.1 Compliance Scores

Compliance scores should be rule-based.

Recommended statuses:

- `pass`
- `warning`
- `fail`
- `not_applicable`
- `not_checked`

Recommended score range:

- `0` to `100`

Recommended meaning:

- `90-100`: pass
- `70-89`: warning
- `<70`: fail

These thresholds can become configurable later.

### 2.2 Performance Scores

Performance scores should be operational and experience-based.

Recommended statuses:

- `excellent`
- `good`
- `degraded`
- `poor`
- `critical`
- `not_enough_data`

Recommended inputs:

- Student ratings
- Inspection condition
- Open issue count
- SLA breaches
- Repeat issues
- Maintenance completion time
- Service availability

## 3. Database Model Plan

### 3.1 Compliance Rule Tables

Create configurable rule tables instead of hardcoding all requirements.

Recommended table: `compliance_rules`

Fields:

- `id`
- `standard`: `nsfas`, `internal`, etc.
- `scope_type`: `room`, `residence`, `documentation`, `overall`
- `rule_code`
- `rule_name`
- `description`
- `severity`: `low`, `medium`, `high`, `critical`
- `is_active`
- `effective_from`
- `effective_to`
- `created_at`
- `updated_at`

Recommended table: `compliance_rule_requirements`

Fields:

- `id`
- `rule_id`
- `requirement_type`: `required_item`, `required_space`, `ratio`, `document`, `assignment`, `capacity`, `custom`
- `item_id`
- `space_type`
- `document_type`
- `minimum_quantity`
- `ratio_numerator`
- `ratio_denominator`
- `metadata`
- `created_at`
- `updated_at`

### 3.2 Compliance Check Tables

Recommended table: `compliance_checks`

Fields:

- `id`
- `scope_type`: `room`, `residence`, `documentation`, `overall`
- `scope_id`
- `standard`
- `score`
- `status`
- `checked_at`
- `checked_by`
- `summary`
- `metadata`
- `created_at`
- `updated_at`

Recommended table: `compliance_findings`

Fields:

- `id`
- `check_id`
- `rule_id`
- `finding_type`: `missing_required_item`, `missing_required_space`, `quantity_shortfall`, `ratio_failed`, `missing_document`, `expired_document`, `missing_assignment`, `capacity_issue`
- `severity`
- `status`: `open`, `resolved`, `waived`
- `message`
- `related_entity_type`
- `related_entity_id`
- `expected_value`
- `actual_value`
- `created_issue_id`
- `created_at`
- `updated_at`

### 3.3 Documentation Tables

Recommended table: `compliance_documents`

Fields:

- `id`
- `residence_id`
- `document_type`
- `document_name`
- `status`: `missing`, `submitted`, `approved`, `rejected`, `expired`
- `issued_at`
- `expires_at`
- `verified_by`
- `verified_at`
- `media_attachment_id`
- `notes`
- `created_at`
- `updated_at`
- `archived_at`

### 3.4 Performance Rating Tables

Recommended table: `performance_ratings`

Fields:

- `id`
- `target_type`: `space_item`, `space`, `service`, `residence`, `contractor`, `vendor`, `issue`
- `target_id`
- `rated_by`
- `rating`: `1` to `5`
- `category`: `overall`, `cleanliness`, `comfort`, `safety`, `maintenance`, `availability`, `responsiveness`, `quality`
- `comment`
- `media_attachment_id`
- `created_at`
- `updated_at`
- `archived_at`

Recommended table: `performance_checks`

Fields:

- `id`
- `scope_type`: `room`, `space`, `residence`, `service`, `contractor`, `vendor`
- `scope_id`
- `score`
- `status`
- `calculated_at`
- `summary`
- `metadata`
- `created_at`
- `updated_at`

Recommended table: `performance_findings`

Fields:

- `id`
- `check_id`
- `finding_type`: `low_rating`, `broken_item`, `dirty_space`, `sla_breach`, `repeat_issue`, `high_backlog`, `poor_service`
- `severity`
- `message`
- `related_entity_type`
- `related_entity_id`
- `created_issue_id`
- `created_at`
- `updated_at`

### 3.5 Service Catalog Tables

Recommended table: `services`

Fields:

- `id`
- `name`: `cleaning`, `wifi`, `security`, `laundry`, `maintenance`, etc.
- `description`
- `is_active`
- `created_at`
- `updated_at`
- `archived_at`

Recommended table: `residence_services`

Fields:

- `id`
- `residence_id`
- `service_id`
- `provider_type`: `internal`, `contractor`, `vendor`
- `provider_id`
- `status`: `active`, `paused`, `cancelled`
- `started_at`
- `ended_at`
- `created_at`
- `updated_at`

## 4. API Plan

### 4.1 Room Compliance Endpoints

Endpoints:

- `GET /api/v1/compliance/rooms/{space_id}`
- `POST /api/v1/compliance/rooms/{space_id}/check`
- `GET /api/v1/compliance/rooms/{space_id}/history`
- `GET /api/v1/compliance/rooms/{space_id}/findings`

Responsibilities:

- Evaluate required room items.
- Evaluate required quantities.
- Produce room compliance score.
- Create findings for missing/shortfall requirements.

### 4.2 Residence Compliance Endpoints

Endpoints:

- `GET /api/v1/compliance/residences/{residence_id}`
- `POST /api/v1/compliance/residences/{residence_id}/check`
- `GET /api/v1/compliance/residences/{residence_id}/history`
- `GET /api/v1/compliance/residences/{residence_id}/findings`

Responsibilities:

- Evaluate required shared spaces.
- Evaluate required residence facilities.
- Evaluate ratios such as toilet/shower/capacity.
- Evaluate assigned roles.
- Produce residence compliance score.

### 4.3 Documentation Compliance Endpoints

Endpoints:

- `POST /api/v1/compliance/documents`
- `GET /api/v1/compliance/residences/{residence_id}/documents`
- `PATCH /api/v1/compliance/documents/{document_id}/status`
- `POST /api/v1/compliance/documents/{document_id}/attach-media`
- `POST /api/v1/compliance/residences/{residence_id}/documents/check`

Responsibilities:

- Track required documents.
- Link uploaded media.
- Validate expiry.
- Support document review.

### 4.4 Overall Compliance Endpoints

Endpoints:

- `GET /api/v1/compliance/overall/residences/{residence_id}`
- `POST /api/v1/compliance/overall/residences/{residence_id}/check`

Responsibilities:

- Combine room compliance.
- Combine residence compliance.
- Combine documentation compliance.
- Produce overall compliance status.

### 4.5 Performance Rating Endpoints

Endpoints:

- `POST /api/v1/performance/ratings`
- `GET /api/v1/performance/ratings`
- `GET /api/v1/performance/targets/{target_type}/{target_id}/ratings`
- `DELETE /api/v1/performance/ratings/{rating_id}`

Responsibilities:

- Allow students to rate space items.
- Allow students to rate spaces.
- Allow students to rate services.
- Allow ratings with comments and media.

### 4.6 Performance Reporting Endpoints

Endpoints:

- `GET /api/v1/performance/rooms/{space_id}`
- `GET /api/v1/performance/spaces/{space_id}`
- `GET /api/v1/performance/residences/{residence_id}`
- `GET /api/v1/performance/services/{service_id}`
- `POST /api/v1/performance/residences/{residence_id}/calculate`

Responsibilities:

- Aggregate ratings.
- Aggregate issue performance.
- Aggregate inspection condition.
- Produce separate performance score.

## 5. Service Layer Plan

### 5.1 Room Compliance Service

File:

- `app/services/room_compliance.py`

Responsibilities:

- Load room template requirements.
- Compare required items to actual `space_items`.
- Identify missing required items.
- Identify quantity shortfalls.
- Calculate room compliance score.
- Persist compliance check and findings.

### 5.2 Residence Compliance Service

File:

- `app/services/residence_compliance.py`

Responsibilities:

- Load residence-level rules.
- Check required shared spaces.
- Check required ratios.
- Check role assignments.
- Check residence capacity requirements.
- Check shared-space item requirements.
- Persist compliance check and findings.

### 5.3 Documentation Compliance Service

File:

- `app/services/documentation_compliance.py`

Responsibilities:

- Define required document set.
- Check missing documents.
- Check expired documents.
- Check approval status.
- Persist documentation compliance check and findings.

### 5.4 Overall Compliance Service

File:

- `app/services/overall_compliance.py`

Responsibilities:

- Combine room, residence, and documentation compliance.
- Weight compliance components.
- Produce overall compliance status.
- Store overall compliance snapshot.

### 5.5 Performance Service

File:

- `app/services/performance.py`

Responsibilities:

- Record ratings.
- Aggregate ratings by target.
- Calculate performance score.
- Add issue/SLA signals.
- Add inspection condition signals.
- Produce performance findings.

## 6. Scoring Plan

### 6.1 Room Compliance Score

Inputs:

- Required item presence.
- Required item quantity.
- Room capacity rules.

Initial weighting:

- Required item presence: `70%`
- Quantity correctness: `20%`
- Room metadata/capacity correctness: `10%`

Excluded unless rule says otherwise:

- Broken condition.
- Student rating.
- Open issues.

### 6.2 Residence Compliance Score

Inputs:

- Required shared spaces: `35%`
- Facility ratios: `25%`
- Role assignments: `15%`
- Shared-space required items: `15%`
- Residence metadata completeness: `10%`

Excluded unless rule says otherwise:

- Dirty spaces.
- Broken items.
- Slow maintenance.
- Student rating.

### 6.3 Documentation Compliance Score

Inputs:

- Required document exists.
- Required document approved.
- Required document not expired.

Initial weighting:

- Existence: `40%`
- Approval: `30%`
- Validity/not expired: `30%`

### 6.4 Performance Score

Inputs:

- Student rating average.
- Inspection condition.
- Open issue count.
- SLA breach count.
- Repeat issue count.
- Maintenance resolution time.

Initial weighting:

- Ratings: `30%`
- Inspection condition: `25%`
- Issue backlog: `20%`
- SLA performance: `15%`
- Repeat issues: `10%`

## 7. Implementation Phases

### Phase 1: Rename And Clarify Existing Compliance

Steps:

1. [x] Rename current compliance service concepts to room compliance where appropriate.
2. [x] Keep existing endpoints temporarily compatible.
3. [x] Add new room-specific endpoints.
4. [x] Update OpenAPI docs to explain room compliance.
5. [x] Add tests for room compliance pass/fail cases.

Deliverable:

- Clear room compliance module.

### Phase 2: Add Compliance Persistence

Steps:

1. [x] Create `compliance_rules`.
2. [x] Create `compliance_rule_requirements`.
3. [x] Create `compliance_checks`.
4. [x] Create `compliance_findings`.
5. [x] Add DB patch script.
6. [x] Add models and schemas.
7. [x] Add seed/default rules for room compliance.
8. [x] Update room compliance service to persist checks.

Deliverable:

- Room compliance checks become auditable historical records.

### Phase 3: Build Residence Compliance

Steps:

1. [x] Define residence-level rules.
2. [x] Define required shared spaces.
3. [x] Define bathroom/toilet/shower ratio rules.
4. [x] Define required role assignment rules.
5. [x] Define shared-space item requirements.
6. [x] Build residence compliance service.
7. [x] Add residence compliance endpoints.
8. [x] Add findings for missing shared spaces and failed ratios.
9. [x] Add tests for residence compliance.

Deliverable:

- Residence compliance exists separately from room compliance.

### Phase 4: Add Documentation Compliance

Steps:

1. [x] Create `compliance_documents`.
2. [x] Define required document types.
3. [x] Link documents to media attachments.
4. [x] Add expiry tracking.
5. [x] Add approval/rejection workflow.
6. [x] Build documentation compliance service.
7. [x] Add document compliance endpoints.
8. [x] Add tests for missing/expired/rejected documents.

Deliverable:

- Certification/documentation compliance module.

### Phase 5: Add Overall Compliance

Steps:

1. [x] Define component weights.
2. [x] Combine room compliance.
3. [x] Combine residence compliance.
4. [x] Combine documentation compliance.
5. [x] Add overall compliance endpoint.
6. [x] Add overall compliance check persistence.
7. [x] Add tests for weighted overall scoring.

Deliverable:

- Overall compliance score that does not mix in performance.

### Phase 6: Add Performance Ratings

Steps:

1. [x] Create `performance_ratings`.
2. [x] Add target types: `space_item`, `space`, `service`, `residence`.
3. [x] Add rating categories.
4. [x] Add student rating endpoint.
5. [x] Add media attachment support for ratings.
6. [x] Add archive endpoint for ratings.
7. [x] Add tests for ratings.

Deliverable:

- Students can rate items, spaces, services, and residences.

### Phase 7: Add Services And Service Performance

Steps:

1. [x] Create `services`.
2. [x] Create `residence_services`.
3. [x] Add core service types: cleaning, Wi-Fi, security, laundry, maintenance.
4. [x] Allow services to be linked to vendors/contractors later.
5. [x] Allow service ratings.
6. [x] Add service performance reports.

Deliverable:

- Service-level performance tracking.

### Phase 8: Add Performance Aggregation

Steps:

1. [x] Create `performance_checks`.
2. [x] Create `performance_findings`.
3. [x] Aggregate ratings by target.
4. [x] Aggregate inspection condition by target.
5. [x] Aggregate issue/SLA signals.
6. [x] Calculate performance score.
7. [x] Add performance endpoints.
8. [x] Add tests for aggregation.

Deliverable:

- Separate performance score for rooms, shared spaces, services, and residences.

### Phase 9: Connect Performance To Issues

Steps:

1. [x] Define thresholds that create issue recommendations.
2. [x] Low rating can suggest issue creation.
3. [x] Repeated low ratings can escalate.
4. [x] Broken item findings can link to issues.
5. [x] SLA failures can affect contractor/vendor performance.

Deliverable:

- Performance signals drive operational workflows without becoming compliance.

### Phase 10: Dashboards And Reporting

Steps:

1. [x] Add compliance summary endpoint.
2. [x] Add performance summary endpoint.
3. [x] Add residence dashboard endpoint.
4. [x] Add trend history.
5. [x] Add export-ready report structures.

Deliverable:

- Clear dashboard separation between compliance and performance.

## 8. Rule Examples

### 8.1 Room Compliance Rule Example

Rule:

- Room must have one bed per resident.

Finding:

- `quantity_shortfall`

Compliance impact:

- Room compliance score drops.

Performance impact:

- None unless the bed is broken, rated poorly, or has open issues.

### 8.2 Residence Compliance Rule Example

Rule:

- Residence must have at least one kitchen.

Finding:

- `missing_required_space`

Compliance impact:

- Residence compliance score drops.

Performance impact:

- None unless kitchen exists and performs poorly.

### 8.3 Performance Example

Signal:

- Kitchen exists but students rate cleanliness `2/5`.

Compliance impact:

- No compliance failure.

Performance impact:

- Kitchen performance score drops.
- Residence performance score drops.

### 8.4 Dual Impact Example

Signal:

- Fire extinguisher exists but is expired.

Compliance impact:

- Residence compliance may fail if the rule requires valid fire equipment.

Performance impact:

- Safety performance may also drop.

Rule-driven decision:

- Only mark both when the compliance rule explicitly requires operational validity.

## 9. Tracking Checklist

- [x] Finalize room compliance requirements.
- [ ] Finalize residence compliance requirements.
- [x] Finalize documentation compliance requirements.
- [x] Finalize performance rating categories.
- [x] Build compliance rule tables.
- [x] Build compliance check/finding tables.
- [x] Refactor current compliance to room compliance.
- [x] Add tests for room compliance pass/fail cases.
- [x] Build residence compliance service.
- [x] Build documentation compliance service.
- [x] Build overall compliance service.
- [x] Build performance ratings.
- [x] Build service catalog.
- [x] Build performance aggregation.
- [ ] Add tests for every compliance level.
- [x] Add tests for performance ratings and aggregation.
- [ ] Add dashboard summary endpoints.

## 10. Guiding Principle

Never collapse compliance and performance into one vague score.

Use this mental model:

- **Compliance**: required standard met.
- **Performance**: lived condition and service quality.
- **Overall compliance**: combination of compliance modules.
- **Overall performance**: combination of operational and student-experience signals.
