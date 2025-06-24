from fastapi import FastAPI, File, UploadFile, HTTPException,APIRouter
from fastapi.responses import JSONResponse
import tempfile
import os
from groq import Groq
from typing import Dict
import logging
from app.services.speech_service import speech_service
from app.utils.file_handler import file_handler
# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

router = APIRouter()
@router.post("/speech-therapy/feedback", response_model=Dict)
async def analyze_speech(audio: UploadFile = File(...)) -> Dict:
    """
    Analyze uploaded audio file and provide child-friendly speech therapy feedback
    
    Args:
        audio: Audio file (supports common formats like mp3, wav, m4a)
        
    Returns:
        JSON response with transcription and feedback
    """
    
    try:
        # Use the file handler context manager for automatic cleanup
        async with file_handler.temporary_file_context(audio) as temp_file_path:
            logger.info("Starting speech analysis process...")
            
            # Step 1: Convert speech to text
            logger.info("Starting speech-to-text conversion...")
            transcribed_text = await speech_service.transcribe_audio(temp_file_path)
            logger.info(f"Transcription result: {transcribed_text}")
            
            if not transcribed_text:
                raise HTTPException(
                    status_code=400, 
                    detail="No speech detected in audio file"
                )
            
            # Step 2: Get AI feedback
            logger.info("Generating speech therapy feedback...")
            feedback = await speech_service.get_speech_feedback(transcribed_text)
            logger.info("Feedback generated successfully")
            
            # Step 3: Return friendly response
            return JSONResponse(
                status_code=200,
                content={
                    "success": True,
                    "transcription": transcribed_text,
                    "feedback": feedback,
                    "message": "Speech analysis completed successfully! 🎉"
                }
            )
    
    except HTTPException:
        # Re-raise HTTP exceptions (they're already properly formatted)
        raise
    except Exception as e:
        logger.error(f"Unexpected error during speech analysis: {str(e)}")
        raise HTTPException(
            status_code=500, 
            detail=f"An unexpected error occurred during speech analysis: {str(e)}"
        )
