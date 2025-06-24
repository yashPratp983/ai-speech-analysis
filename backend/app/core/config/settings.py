import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings): 
    speech_model: str
    chat_model: str
    groq_api_key: str
    
    
    class Config:
        env_file = ".env"
        case_sensitive = False

    @classmethod
    def get_settings(cls):
        return cls()

# Use this to get the settings
settings = Settings.get_settings()