# Repository Guidelines

## Project Structure & Module Organization

This repository contains the Residence Operating System API and a Flutter mobile client. Backend source lives in `app/`: `app/main.py` creates the FastAPI app, `app/api/` contains route modules, `app/models/` SQLAlchemy models, `app/schemas/` Pydantic schemas, `app/services/` business logic, and `app/core/` shared settings, database, logging, and utilities. Database SQL is organized under `db/schema/`, `db/constraints/`, `db/seeds/`, and `db/migrations/`. Tests are in `tests/`. Project notes and images are in `assets/`. The Flutter app is under `mobile/`, with Dart code in `mobile/lib/` and widget tests in `mobile/test/`.

## Build, Test, and Development Commands

Create a Python environment and install backend dependencies:

```bash
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

Run the API locally with:

```bash
uvicorn app.main:app --reload
```

Run API and PostGIS together with:

```bash
docker compose up --build
```

Run backend tests with `pytest`. For mobile work, run commands from `mobile/`: `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter run`.

## Coding Style & Naming Conventions

Use Python 3.12-compatible code and keep modules aligned with the existing API/model/schema/service split. Prefer four-space indentation, snake_case for Python files, functions, and fields, and PascalCase for SQLAlchemy and Pydantic classes. Keep route handlers thin; put reusable workflow logic in `app/services/`. For Dart, follow `flutter_lints`, use `lower_snake_case.dart` filenames, PascalCase widgets/classes, and keep UI code in `mobile/lib/`.

## Testing Guidelines

Backend tests use pytest, configured in `pytest.ini` with `tests` as the test path and repository root on `pythonpath`. Name new tests `test_*.py` and group them around observable behavior, such as status transitions, enum normalization, or core API flows. Run `pytest` before backend commits. For mobile changes, add or update widget tests in `mobile/test/` and run `flutter test`.

## Commit & Pull Request Guidelines

Recent commits use short imperative subjects such as `Update gitignore to exclude DB and runtime data`, with occasional scoped prefixes like `Refactor:`. Keep subjects concise and describe the resulting change, not the process. Pull requests should include a brief summary, test results (`pytest`, `flutter test`, or `flutter analyze` as relevant), linked issues when available, and screenshots for visible mobile UI changes.

## Security & Configuration Tips

Do not commit local databases, runtime uploads, virtual environments, or secrets. Configure service settings through environment variables such as `API_DATABASE_URL`, `ENVIRONMENT`, `CORS_ALLOW_ORIGINS`, `POSTGRES_DB`, `POSTGRES_USER`, and `POSTGRES_PASSWORD`. Keep generated media in the Docker `media_uploads` volume or another ignored runtime location.
