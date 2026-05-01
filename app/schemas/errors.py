from pydantic import BaseModel, ConfigDict


class ErrorResponse(BaseModel):
    detail: str

    model_config = ConfigDict(
        json_schema_extra={
            "examples": [
                {"detail": "Resource not found"},
                {"detail": "Validation failed"},
            ]
        }
    )
