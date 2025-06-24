import tempfile
import os
import logging
from typing import Set, Optional, Tuple
from fastapi import UploadFile, HTTPException
from contextlib import asynccontextmanager

# Configure logging
logger = logging.getLogger(__name__)

class FileHandler:
    """
    Service for handling file operations including validation and temporary file management
    """
    
    # Supported audio file extensions
    ALLOWED_AUDIO_EXTENSIONS: Set[str] = {
        '.mp3', '.mp4', '.wav', '.m4a', '.ogg', '.flac', '.webm'
    }
    
    # Maximum file size (10MB)
    MAX_FILE_SIZE_BYTES: int = 10 * 1024 * 1024
    
    @classmethod
    def validate_audio_file(cls, file: UploadFile) -> Tuple[bool, Optional[str]]:
        """
        Validate uploaded audio file
        
        Args:
            file: UploadFile object from FastAPI
            
        Returns:
            Tuple of (is_valid, error_message)
        """
        try:
            # Check if filename exists
            if not file.filename:
                return False, "Filename is required"
            
            # Check file extension
            file_extension = os.path.splitext(file.filename.lower())[1]
            if file_extension not in cls.ALLOWED_AUDIO_EXTENSIONS:
                supported_formats = ', '.join(cls.ALLOWED_AUDIO_EXTENSIONS)
                return False, f"Unsupported audio format. Supported formats: {supported_formats}"
            
            # Check file size if available
            if hasattr(file, 'size') and file.size and file.size > cls.MAX_FILE_SIZE_BYTES:
                max_size_mb = cls.MAX_FILE_SIZE_BYTES / (1024 * 1024)
                return False, f"File size exceeds maximum limit of {max_size_mb}MB"
            
            return True, None
            
        except Exception as e:
            logger.error(f"Error validating file: {str(e)}")
            return False, f"File validation error: {str(e)}"
    
    @classmethod
    async def save_temporary_file(cls, file: UploadFile) -> str:
        """
        Save uploaded file to temporary location
        
        Args:
            file: UploadFile object from FastAPI
            
        Returns:
            Path to temporary file
            
        Raises:
            HTTPException: If file operations fail
        """
        temp_file = None
        try:
            # Get file extension
            file_extension = os.path.splitext(file.filename.lower())[1] if file.filename else '.tmp'
            
            # Create temporary file with proper extension
            temp_file = tempfile.NamedTemporaryFile(delete=False, suffix=file_extension)
            
            # Read and write file content
            content = await file.read()
            
            # Validate content size
            if len(content) > cls.MAX_FILE_SIZE_BYTES:
                max_size_mb = cls.MAX_FILE_SIZE_BYTES / (1024 * 1024)
                raise HTTPException(
                    status_code=413,
                    detail=f"File size exceeds maximum limit of {max_size_mb}MB"
                )
            
            temp_file.write(content)
            temp_file.close()
            
            logger.info(f"Temporary file created: {temp_file.name}")
            return temp_file.name
            
        except HTTPException:
            # Clean up on HTTP exceptions
            if temp_file and os.path.exists(temp_file.name):
                cls.cleanup_file(temp_file.name)
            raise
        except Exception as e:
            # Clean up on other exceptions
            if temp_file and os.path.exists(temp_file.name):
                cls.cleanup_file(temp_file.name)
            logger.error(f"Error saving temporary file: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Failed to save uploaded file: {str(e)}")
    
    @classmethod
    def cleanup_file(cls, file_path: str) -> bool:
        """
        Clean up temporary file
        
        Args:
            file_path: Path to file to be deleted
            
        Returns:
            True if successful, False otherwise
        """
        try:
            if file_path and os.path.exists(file_path):
                os.unlink(file_path)
                logger.info(f"Temporary file cleaned up: {file_path}")
                return True
            return False
        except Exception as e:
            logger.warning(f"Failed to delete temporary file {file_path}: {str(e)}")
            return False
    
    @classmethod
    @asynccontextmanager
    async def temporary_file_context(cls, file: UploadFile):
        """
        Context manager for handling temporary files with automatic cleanup
        
        Args:
            file: UploadFile object from FastAPI
            
        Yields:
            Path to temporary file
            
        Example:
            async with FileHandler.temporary_file_context(audio_file) as temp_path:
                # Use temp_path for processing
                transcription = await process_audio(temp_path)
        """
        temp_path = None
        try:
            # Validate file first
            is_valid, error_message = cls.validate_audio_file(file)
            if not is_valid:
                raise HTTPException(status_code=400, detail=error_message)
            
            # Save temporary file
            temp_path = await cls.save_temporary_file(file)
            yield temp_path
            
        finally:
            # Always clean up
            if temp_path:
                cls.cleanup_file(temp_path)

# Create a global instance
file_handler = FileHandler()