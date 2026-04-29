from datetime import datetime, timezone
from time import perf_counter

from fastapi import FastAPI, Response, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from app.api import api_router
from app.core.database import engine
from app.core.logger import setup_logging
from app.core.settings import get_settings

setup_logging()
settings = get_settings()
STARTED_AT = datetime.now(timezone.utc)
STARTED_MONOTONIC = perf_counter()


app = FastAPI(
    title=settings.app_name,
    description="Residence Operating System API for residences, tenancy, inspections, issues, and compliance.",
    version=settings.app_version,
    openapi_tags=[
        {"name": "Tenancies", "description": "Tenant occupancy lifecycle operations."},
        {"name": "Inspections", "description": "Inspection capture, sign-off, and completion workflows."},
        {"name": "Issues", "description": "Maintenance issue reporting, assignment, and lifecycle updates."},
        {"name": "Compliance", "description": "Space compliance scoring and remediation automation."},
    ],
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=settings.cors_allow_credentials,
    allow_methods=settings.cors_allow_methods,
    allow_headers=settings.cors_allow_headers,
)

@app.get(
    "/",
    summary="API root",
    description="Returns a lightweight liveness message for the API service.",
    responses={
        200: {
            "description": "API service is reachable.",
            "content": {
                "application/json": {
                    "example": {"detail": "ROS API is running"}
                }
            },
        }
    },
)
def root():
    return {
        "detail": "ROS API is running",
        "version": settings.app_version,
        "environment": settings.environment,
    }


@app.get(
    "/health",
    summary="Health check",
    description="Returns operational health metadata for the ROS API service.",
    responses={
        200: {
            "description": "Service health payload.",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "Residence Operating System Running",
                        "status": "ok",
                        "service": "ros-api",
                        "timestamp": "2026-04-29T00:00:00+00:00",
                        "version": "1.0.0",
                        "environment": "dev",
                        "checks": {
                            "api": {"status": "ok"},
                            "database": {"status": "ok", "latency_ms": 4.2},
                        },
                    }
                }
            },
        }
    },
)
def health(response: Response):
    checked_at = datetime.now(timezone.utc)
    uptime_seconds = round(perf_counter() - STARTED_MONOTONIC, 3)
    checks = {
        "api": {
            "status": "ok",
            "started_at": STARTED_AT.isoformat(),
            "uptime_seconds": uptime_seconds,
        }
    }

    overall_status = "ok"
    db_started = perf_counter()
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        checks["database"] = {
            "status": "ok",
            "latency_ms": round((perf_counter() - db_started) * 1000, 2),
        }
    except Exception as exc:
        overall_status = "degraded"
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
        checks["database"] = {
            "status": "error",
            "latency_ms": round((perf_counter() - db_started) * 1000, 2),
            "error": exc.__class__.__name__,
        }

    return {
        "detail": "Residence Operating System health report",
        "status": overall_status,
        "service": settings.service_name,
        "timestamp": checked_at.isoformat(),
        "version": settings.app_version,
        "environment": settings.environment,
        "checks": checks,
    }

app.include_router(api_router)
