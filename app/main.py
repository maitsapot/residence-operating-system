from fastapi import FastAPI
from datetime import datetime
from app.api import api_router
from app.core.logger import setup_logging
from fastapi.middleware.cors import CORSMiddleware

setup_logging()


app = FastAPI(title="ROS API")
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="ROS API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # for now (dev)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 👇 ADD IT HERE
@app.get("/")
def root():
    return {
        "detail": "ROS API is running"
    }

@app.get("/health")
def health():
    return {
        "detail":"Residence Operating System Running",
        "status": "ok",
        "service": "ros-api",
        "timestamp:": datetime.utcnow().isoformat(),
        "version": "1.0",
        "environment": "dev"}
    
app.include_router(api_router)