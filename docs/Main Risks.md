  Main risks:

  - Test coverage is still thin: 9 tests is not enough for
    this many workflows.
  - No real auth/authorization layer is visible yet, which is
    a major production blocker.
  - DB migrations are SQL patch scripts, not a migration tool
    like Alembic. Fine for now, but risky as the schema grows.
  - Some route modules still contain business logic outside
    services, especially older CRUD areas.
  - Error handling is better in new areas but still
    inconsistent across the older API.
  - Media storage is local filesystem for now; production
    should move to S3/R2/MinIO.
  - No CI pipeline yet to enforce tests, lint, type checks,
    and migration checks.
