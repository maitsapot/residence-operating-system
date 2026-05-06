# Mobile Refactor Tasks

## Current Focus

- [x] Decouple `main.dart` into a lean app bootstrap.
- [x] Introduce typed mobile models for API responses.

## Next Tasks

- [x] Make `ApiService` injectable for tests and future environment switching.
- [x] Add a routing layer for landing, tenant home, and profile navigation.
- [x] Split `TenantHomeScreen` into smaller dashboard, menu, and action modules.
- [x] Replace placeholder profile data with API-backed tenant profile content.
- [x] Add focused widget tests for residence selection and tenant navigation.
- [ ] Add API parsing tests for mobile models.

## Backlog

- [ ] Centralize API base URL configuration by environment.
- [ ] Add loading and empty states for tenants, issues, and profile reads.
- [ ] Normalize issue status display rules in one shared place.
- [ ] Review visual consistency across the legacy profile prototype and tenant home.
