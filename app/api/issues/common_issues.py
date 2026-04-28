from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.core.database import get_db
from app.core.logger import get_logger

from app.models.common_issue import CommonIssue
from app.schemas.common_issue import CommonIssueCreate, CommonIssueResponse

logger = get_logger(__name__)

router = APIRouter(prefix="/common-issues", tags=["Common Issues"])


@router.post("/", response_model=CommonIssueResponse)
def create_common_issue(payload: CommonIssueCreate, db: Session = Depends(get_db)):

    logger.info(f"Creating common issue: {payload.issue_name}")

    try:
        item = CommonIssue(**payload.dict())

        db.add(item)
        db.commit()
        db.refresh(item)

        logger.info(f"Common issue created: {item.id}")

        return item

    except IntegrityError as e:
        db.rollback()
        logger.error(f"Integrity error: {e}")
        raise HTTPException(400, "Duplicate or invalid data")


@router.get("/{catalog_id}", response_model=list[CommonIssueResponse])
def get_common_issues_by_catalog(catalog_id: str, db: Session = Depends(get_db)):

    logger.info(f"Fetching common issues for catalog: {catalog_id}")

    return db.query(CommonIssue).filter(
        CommonIssue.catalog_id == catalog_id,
        CommonIssue.is_active == True
    ).all()