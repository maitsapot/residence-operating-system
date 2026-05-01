from sqlalchemy import Column, String, TIMESTAMP, text, Numeric
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from geoalchemy2 import Geometry

from app.core.database import Base


class Location(Base):
    __tablename__ = "locations"

    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=text("gen_random_uuid()")
    )

    country = Column(String)

    # 🔥 REQUIRED NOW
    province = Column(String, nullable=False)
    city = Column(String, nullable=False)
    suburb = Column(String, nullable=False)
    address_line_1 = Column(String, nullable=False)

    # optional
    address_line_2 = Column(String)
    postal_code = Column(String)

    latitude = Column(Numeric(10, 7))
    longitude = Column(Numeric(10, 7))

    geo_point = Column(Geometry("POINT", srid=4326))

    created_at = Column(
        TIMESTAMP(timezone=True),
        server_default=func.now()
    )

    updated_at = Column(
        TIMESTAMP(timezone=True),
        server_default=func.now(),
        onupdate=func.now()
    )
