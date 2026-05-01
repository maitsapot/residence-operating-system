from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.location import Location
from app.schemas.location import LocationCreate, LocationResponse

from typing import List
from uuid import UUID
from fastapi import HTTPException

router = APIRouter(prefix="/locations", tags=["Locations"])


@router.post("/", response_model=LocationResponse)
def create_location(payload: LocationCreate, db: Session = Depends(get_db)):
    location = Location(**payload.dict())

    db.add(location)
    db.commit()
    db.refresh(location)

    return location


@router.get("/", response_model=List[LocationResponse])
def get_locations(db: Session = Depends(get_db)):
    locations = db.query(Location).all()
    return locations


@router.get("/{location_id}", response_model=LocationResponse)
def get_location(location_id: UUID, db: Session = Depends(get_db)):
    location = db.query(Location).filter(Location.id == location_id).first()

    if not location:
        raise HTTPException(status_code=404, detail="Location not found")

    return location