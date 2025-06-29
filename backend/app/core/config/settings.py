import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings): 
    # Configuration for application settings
    speech_model: str
    chat_model: str
    groq_api_key: str
    gemini_api_key: str
    gemini_model: str
    transcription_model: str

    class Config:
        # Configuration for environment variables
        env_file = ".env"
        case_sensitive = False

    @classmethod
    def get_settings(cls):
        # Returns an instance of the settings
        return cls()

# Use this to get the settings
settings = Settings.get_settings()