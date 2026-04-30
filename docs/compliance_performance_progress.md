# Compliance And Performance Progress

Last updated: 2026-04-30

## Current Status

- Current phase: **Complete - Compliance And Performance Roadmap**
- Phase 10 status: **Complete - compliance summaries, performance summaries, residence dashboard, trend history, and export-ready reports implemented**
- Phase 9 status: **Complete - performance findings can create linked issues, duplicate issue creation is prevented, and resolved issues improve future performance checks**
- Phase 8 status: **Complete - ratings, issue backlog, SLA breaches, and inspection condition now aggregate into persisted performance checks and findings**
- Phase 7 status: **Complete - service catalog, residence service assignments, service ratings, performance summaries, endpoints, and tests implemented**
- Phase 6 status: **Complete - performance ratings added for targets with categories, media support, summaries, archival, endpoints, and tests**
- Phase 5 status: **Complete - overall compliance combines room, residence, and documentation compliance with weighted scoring and persisted snapshots**
- Latest verification: **`venv/bin/python -m pytest` passed with 41 tests**
- Latest DB update: **Phase 8 `performance_checks` and `performance_findings` patch applied and verified on both `TEST_DATABASE_URL` and dev `DATABASE_URL`**
- DB policy: schema changes are applied to `TEST_DATABASE_URL` first. Apply to dev only after explicit approval.

## Phase Progress

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

## Completed Work

### Phase 1: Room Compliance

- Current compliance behavior was clarified as room compliance.
- Room-specific endpoints were added.
- Room compliance now tracks required inventory and quantities.
- Broken/damaged room items are treated as performance indicators, not compliance failures.
- Room compliance tests are passing.

### Phase 2: Compliance Persistence

- Added `compliance_rules`.
- Added `compliance_rule_requirements`.
- Added `compliance_checks`.
- Added `compliance_findings`.
- Added persisted room compliance checks.
- Added room compliance rule seeding.
- DB patch was applied and verified on both test and dev databases.

### Phase 3: Residence Compliance

- Added residence compliance service.
- Added required shared-space checks.
- Added bathroom capacity ratio checks.
- Added required landlord/manager/caretaker assignment checks.
- Added shared-space item requirement checks.
- Added persisted residence compliance checks and findings.
- Added residence compliance endpoints and tests.

### Phase 4: Documentation Compliance

- Added `compliance_documents`.
- Added required documentation/certification types.
- Added media attachment linking.
- Added expiry tracking.
- Added approval/rejection workflow.
- Added documentation compliance service.
- Added documentation compliance endpoints.
- Added persisted documentation compliance checks and findings.
- Added tests for missing, expired, rejected, approved, media-linked, and persisted documentation checks.
- DB patch was applied and verified on both test and dev databases.

### Phase 5: Overall Compliance

- Added overall compliance service.
- Added weighted component scoring for room, residence, and documentation compliance.
- Added overall compliance endpoints.
- Added persisted overall compliance checks and component findings.
- Kept performance signals explicitly excluded from overall compliance.
- Added tests for weighted scoring and persisted overall checks.

### Phase 6: Performance Ratings

- Added `performance_ratings`.
- Added rating targets for space items, spaces, services, residences, contractors, vendors, and issues.
- Added rating categories such as overall, cleanliness, safety, maintenance, responsiveness, quality, and condition.
- Added performance rating service.
- Added performance rating endpoints.
- Added media attachment support.
- Added rating summaries with count and average.
- Added soft archival for ratings.
- Added tests for rating creation, summaries, media linkage, archival, and missing-target validation.

### Phase 7: Services And Service Performance

- Added `services`.
- Added `residence_services`.
- Added core service seeding for cleaning, Wi-Fi, security, laundry, and maintenance.
- Added residence service assignment workflow.
- Added service rating support through performance ratings.
- Added service performance summaries.
- Added service catalog and residence-service endpoints.
- Added tests for service seeding, assignment, ratings, summaries, and archival.

### Phase 8: Performance Aggregation

- Added `performance_checks`.
- Added `performance_findings`.
- Aggregated performance from ratings, issue backlog, SLA breaches, and inspection condition.
- Added performance reports for spaces, rooms, residences, and services.
- Added persisted performance checks.
- Added performance findings for low ratings, high backlog, SLA breaches, and poor inspection condition.
- Added tests for aggregation and persisted checks/findings.

### Phase 9: Connect Performance To Issues

- Added workflow to create issues from actionable performance findings.
- Linked created issues back to `performance_findings.created_issue_id`.
- Prevented duplicate issue creation when a finding already has a linked issue.
- Inferred issue context from inspection and space-item findings where possible.
- Confirmed resolved issues are excluded from future active issue performance signals.
- Added tests for issue creation, duplicate prevention, and performance improvement after resolution.

### Phase 10: Dashboards And Reporting

- Added compliance summary dashboard endpoint.
- Added performance summary dashboard endpoint.
- Added combined residence dashboard endpoint.
- Added compliance and performance trend history endpoint.
- Added export-ready residence report payload.
- Kept compliance and performance visibly separated in dashboard responses.
- Added tests for summaries, trends, and export-ready report structure.

## Next Phase

### Roadmap Complete

Completed scope:

1. Added compliance summary endpoint.
2. Added performance summary endpoint.
3. Added residence dashboard endpoint.
4. Added trend history.
5. Added export-ready report structures.

Goal:

- Maintain clear dashboard separation between compliance and performance.
