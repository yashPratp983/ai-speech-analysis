import os
import sys
import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

# Application Imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Setup logging
log_file_path = os.path.join(os.path.dirname(__file__), 'app.log')
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[logging.FileHandler(log_file_path), logging.StreamHandler()]
)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="Ai speech therapy",
    version="1.0.0",
    root_path="/sppech-therapy",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def include_routers(app):
    """
    Includes API routers for different endpoints.
    
    Args:
        app (FastAPI): The FastAPI application instance.
    """
    from app.api.v1 import feedback, transcribe, health
    
    app.include_router(feedback.router, prefix="/api/v1", tags=["feedback"])
    app.include_router(transcribe.router, prefix="/api/v1", tags=["transcribe"])
    app.include_router(health.router, prefix="/api/v1", tags=["health"])

include_routers(app)
logger.info("Application startup complete. Ready to serve requests.")