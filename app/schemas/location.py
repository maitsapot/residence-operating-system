from pydantic import BaseModel
from typing import Optional, Literal
from decimal import Decimal
from uuid import UUID


# 🔥 Controlled province list
ProvinceEnum = Literal[
    "Eastern Cape",
    "Free State",
    "Gauteng",
    "KwaZulu-Natal",
    "Limpopo",
    "Mpumalanga",
    "Northern Cape",
    "North West",
    "Western Cape"
]


class LocationCreate(BaseModel):
    country: Optional[str] = "South Africa"

    province: ProvinceEnum   # 🔥 enforced
    city: str
    suburb: str
    address_line_1: str

    address_line_2: Optional[str] = None
    postal_code: Optional[str] = None

    latitude: Optional[Decimal] = None
    longitude: Optional[Decimal] = None


class LocationResponse(BaseModel):
    id: UUID
    province: Optional[str] = None
    city: Optional[str] = None
    suburb: Optional[str] = None
    address_line_1: Optional[str] = None

    class Config:
        from_attributes = True
