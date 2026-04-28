from pydantic import BaseModel, EmailStr, ConfigDict, field_validator
from typing import Optional, Literal
from datetime import date
from uuid import UUID
from app.schemas.location import LocationResponse,LocationCreate



# ===============================
# ENUMS (STRICT VALIDATION)
# ===============================
GenderEnum = Literal["male", "female", "other"]
RaceEnum = Literal["african", "coloured", "indian", "white", "other"]


# ===============================
# CREATE SCHEMA
# ===============================
class UserCreate(BaseModel):
    first_name: str
    middle_name: Optional[str] = None
    last_name: str

    email: Optional[EmailStr] = None
    cellphone: str
    phone: Optional[str] = None

    id_number: Optional[str] = None
    date_of_birth: date
    gender: GenderEnum
    race: RaceEnum

  
    location: LocationCreate  # 🔥 REQUIRED


    # ===============================
    # VALIDATORS
    # ===============================
    @field_validator("cellphone")
    @classmethod
    def validate_cellphone(cls, v: str) -> str:
        v = v.strip()

        if not v.isdigit():
            raise ValueError("Cellphone must contain only digits")

        if len(v) < 10:
            raise ValueError("Cellphone must be at least 10 digits")

        return v

class UserFullNameResponse(BaseModel):
    id: UUID
    full_name: str
# ===============================
# RESPONSE SCHEMA
# ===============================
class UserResponse(BaseModel):
    id: UUID

    first_name: str
    middle_name: Optional[str]
    last_name: str
    full_name: str

    email: Optional[str]
    cellphone: str

  

    # 🔥 NESTED RELATION
    location: Optional[LocationResponse]


    # ===============================
    # CONFIG (Pydantic v2)
    # ===============================
    model_config = ConfigDict(from_attributes=True)