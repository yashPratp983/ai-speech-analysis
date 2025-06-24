from fastapi import HTTPException
import logging
from app.core.prompts.speech_therepy import system_speech_therepy, user_speech_therepy
from app.core.config.initialiser import initialized_dbs
# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class SpeechTherapyService:
    def __init__(self):
        self.whisper_model = initialized_dbs.get_speech_model()
        self.llm_model = initialized_dbs.get_chat_model()
        self.groq_client= initialized_dbs.get_groq_client()
    
    async def transcribe_audio(self, audio_file_path: str) -> str:
        """Convert audio to text using Groq's Whisper model"""
        try:
            with open(audio_file_path, "rb") as file:
                transcription = self.groq_client.audio.transcriptions.create(
                    file=file,
                    model=self.whisper_model,
                    language="en"  # Specify language for better accuracy
                )
            return transcription.text.strip()
        except Exception as e:
            logger.error(f"Transcription error: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Speech-to-text conversion failed: {str(e)}")
    
    async def get_speech_feedback(self, transcribed_text: str) -> str:
        """Get child-friendly feedback using Groq's Llama model"""
        try:

            chat_completion = self.groq_client.chat.completions.create(
                messages=[
                    {
                        "role": "system",
                        "content": system_speech_therepy()
                    },
                    {
                        "role": "user", 
                        "content": user_speech_therepy(transcribed_text)
                    }
                ],
                model=self.llm_model,
                temperature=0.7,
                max_tokens=200
            )
            
            return chat_completion.choices[0].message.content.strip()
        except Exception as e:
            logger.error(f"LLM feedback error: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Feedback generation failed: {str(e)}")

# Initialize service
speech_service = SpeechTherapyService()