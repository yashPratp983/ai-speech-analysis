from fastapi import APIRouter
from fastapi.responses import JSONResponse
from typing import Dict

# Configure logging
router = APIRouter()
@router.get("/health", response_model=Dict)
async def health_check() -> Dict:
    """
    Health check endpoint for the speech therapy service
    
    Returns:
        JSON response with service status
    """
    return JSONResponse(
        status_code=200,
        content={
            "service": "speech-therapy",
            "status": "healthy",
            "message": "Speech therapy service is running"
        }
    )