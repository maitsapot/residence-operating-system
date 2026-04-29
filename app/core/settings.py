import os
from functools import lru_cache

from dotenv import load_dotenv

load_dotenv()


def _csv(value: str | None, default: list[str] | None = None):
    if value is None:
        return default or []
    return [item.strip() for item in value.split(",") if item.strip()]


class Settings:
    app_name: str = os.getenv("APP_NAME", "ROS API")
    app_version: str = os.getenv("APP_VERSION", "1.0.0")
    environment: str = os.getenv("ENVIRONMENT", "dev")
    service_name: str = os.getenv("SERVICE_NAME", "ros-api")

    database_url: str | None = os.getenv("DATABASE_URL")

    cors_origins: list[str] = _csv(
        os.getenv("CORS_ALLOW_ORIGINS"),
        ["*"] if os.getenv("ENVIRONMENT", "dev") == "dev" else [],
    )
    cors_allow_credentials: bool = os.getenv("CORS_ALLOW_CREDENTIALS", "true").lower() == "true"
    cors_allow_methods: list[str] = _csv(os.getenv("CORS_ALLOW_METHODS"), ["*"])
    cors_allow_headers: list[str] = _csv(os.getenv("CORS_ALLOW_HEADERS"), ["*"])

    log_level: str = os.getenv("LOG_LEVEL", "INFO")
    log_format: str = os.getenv("LOG_FORMAT", "text")


@lru_cache
def get_settings():
    return Settings()
