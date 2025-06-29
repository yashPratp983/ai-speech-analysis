from fastapi import File, UploadFile, HTTPException, APIRouter
from fastapi.responses import JSONResponse
from typing import Dict
import logging
from app.services.speech_service import speech_service
from app.utils.file_handler import file_handler
from app.utils.audio_processor import AudioPreprocessor

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

router = APIRouter()

# Initialize the audio preprocessor
audio_preprocessor = AudioPreprocessor()

@router.post("/speech-therapy/transcribe", response_model=Dict)
async def transcribe_audio_chunk(audio: UploadFile = File(...), context: str='') -> Dict:
    """
    Transcribe an audio chunk for real-time transcription, enhanced with comprehensive preprocessing.
    
    Args:
        audio (UploadFile): Audio chunk (wav format recommended).
        context (str): Additional context for the transcription.
        
    Returns:
        Dict: JSON response with transcription only.
    """
    
    try:
        # Use the file handler context manager for automatic cleanup
        async with file_handler.temporary_file_context(audio) as temp_file_path:
            logger.info("Starting enhanced real-time transcription...")
            
            # Enhanced transcription for real-time chunks
            transcribed_text, analysis_results = await audio_preprocessor.enhanced_transcribe_audio(
                temp_file_path,
                context=context
            )
            
            # Return transcription (empty string if no speech detected)
            return JSONResponse(
                status_code=200,
                content={
                    "success": True,
                    "transcription": transcribed_text or "",
                    "processing_info": {
                        "method": "enhanced_groq",
                        "preprocessing_applied": True
                    },
                    "message": "Enhanced transcription completed"
                }
            )
    
    except Exception as e:
        # Log errors during transcription
        logger.error(f"Error during enhanced transcription: {str(e)}")
        # Don't raise HTTPException for transcription errors to avoid disrupting real-time flow
        return JSONResponse(
            status_code=200,
            content={
                "success": False,
                "transcription": "",
                "analysis_results": {"error": str(e)},
                "processing_info": {
                    "method": "enhanced_groq",
                    "error": True
                },
                "message": f"Enhanced transcription failed: {str(e)}"
            }
        )


