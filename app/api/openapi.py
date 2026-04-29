from app.schemas.errors import ErrorResponse


BAD_REQUEST = {
    "model": ErrorResponse,
    "description": "The request is syntactically valid but violates a business rule.",
    "content": {
        "application/json": {
            "example": {"detail": "Invalid status transition"}
        }
    },
}

NOT_FOUND = {
    "model": ErrorResponse,
    "description": "The requested resource does not exist.",
    "content": {
        "application/json": {
            "example": {"detail": "Resource not found"}
        }
    },
}

SERVER_ERROR = {
    "model": ErrorResponse,
    "description": "An unexpected server error occurred.",
    "content": {
        "application/json": {
            "example": {"detail": "Internal server error"}
        }
    },
}

COMMON_ERROR_RESPONSES = {
    400: BAD_REQUEST,
    404: NOT_FOUND,
    500: SERVER_ERROR,
}
