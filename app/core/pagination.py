from fastapi import Query

DEFAULT_LIMIT = 50
MAX_LIMIT = 100


def pagination_params():
    return {
        "offset": Query(0, ge=0, description="Number of records to skip."),
        "limit": Query(
            DEFAULT_LIMIT,
            ge=1,
            le=MAX_LIMIT,
            description=f"Maximum number of records to return, capped at {MAX_LIMIT}.",
        ),
    }


def apply_pagination(query, offset: int, limit: int):
    return query.offset(offset).limit(limit)
