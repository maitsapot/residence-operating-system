from app.core.database import engine, Base

# This ensures all models are loaded into metadata
import app.models  

print("Creating database tables...")

Base.metadata.create_all(bind=engine)

print("Done.")