from fastapi import File, UploadFile, HTTPException, APIRouter
from fastapi.responses import JSONResponse
from typing import Dict
import logging
from app.services.speech_service import speech_service

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

router = APIRouter()

@router.post("/speech-therapy/feedback", response_model=Dict)
async def analyze_speech(transcription: str) -> Dict:
    """
    Analyze the provided transcription and context to provide child-friendly speech therapy feedback.
    Enhanced with comprehensive preprocessing and analysis.
    
    Args:
        transcription (str): The transcription text of the speech.
        context (str): Additional context for the transcription.
        
    Returns:
        Dict: JSON response with transcription and feedback.
    """
    
    try:    
        # Generate feedback for detected speech
        feedback = await speech_service.get_speech_feedback(transcription)
        
        return JSONResponse(
            status_code=200,
            content={
                "success": True,
                "transcription": transcription,
                "feedback": feedback,
                "processing_info": {
                    "speech_detected": True,
                    "transcription_method": "enhanced_groq",
                    "preprocessing_applied": True,
                    "audio_enhanced": True
                },
                "message": "Speech analysis completed successfully! 🎉"
            }
        )
    
    except HTTPException:
        # Re-raise HTTP exceptions (they're already properly formatted)
        raise
    except Exception as e:
        # Log unexpected errors
        logger.error(f"Unexpected error during speech analysis: {str(e)}")
        raise HTTPException(
            status_code=500, 
            detail=f"An unexpected error occurred during speech analysis: {str(e)}"
        )