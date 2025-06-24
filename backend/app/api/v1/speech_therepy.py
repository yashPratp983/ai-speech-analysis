from fastapi import FastAPI, File, UploadFile, HTTPException,APIRouter
from fastapi.responses import JSONResponse
import tempfile
import os
from groq import Groq
from typing import Dict
import logging
from app.services.speech_service import speech_service

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

router = APIRouter()
# Make sure to set your GROQ_API_KEY environment variable
@router.post("/speech-therapy/feedback", response_model=Dict)
async def analyze_speech(audio: UploadFile = File(...)) -> Dict:
    """
    Analyze uploaded audio file and provide child-friendly speech therapy feedback
    
    Args:
        audio: Audio file (supports common formats like mp3, wav, m4a)
    
    Returns:
        JSON response with transcription and feedback
    """
    
    # Validate file type
    allowed_extensions = {'.mp3','.mp4', '.wav', '.m4a', '.ogg', '.flac'}
    file_extension = os.path.splitext(audio.filename.lower())[1] if audio.filename else ''
    
    if file_extension not in allowed_extensions:
        raise HTTPException(
            status_code=400, 
            detail=f"Unsupported audio format. Supported formats: {', '.join(allowed_extensions)}"
        )
    
    # Create temporary file to store uploaded audio
    temp_file = None
    try:
        # Create temporary file with proper extension
        temp_file = tempfile.NamedTemporaryFile(delete=False, suffix=file_extension)
        
        # Write uploaded content to temporary file
        content = await audio.read()
        temp_file.write(content)
        temp_file.close()
        
        # Step 1: Convert speech to text
        logger.info("Starting speech-to-text conversion...")
        transcribed_text = await speech_service.transcribe_audio(temp_file.name)
        logger.info(f"Transcription result: {transcribed_text}")
        
        if not transcribed_text:
            raise HTTPException(status_code=400, detail="No speech detected in audio file")
        
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
        raise
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {str(e)}")
    
    finally:
        # Clean up temporary file
        if temp_file and os.path.exists(temp_file.name):
            try:
                os.unlink(temp_file.name)
            except Exception as e:
                logger.warning(f"Failed to delete temporary file: {str(e)}")
