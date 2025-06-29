from groq import Groq
# Application imports
from app.core.config.settings import settings
from google import genai

class InitializeDbs:
    _instance = None

    def __new__(cls, *args, **kwargs):
        # Implement singleton pattern
        if not cls._instance:
            cls._instance = super(InitializeDbs, cls).__new__(cls)
            cls._instance.__init__(*args, **kwargs)
        return cls._instance

    def __init__(self):
        # Initialize the database settings
        if hasattr(self, '_initialized'):  
            return
        self._initialized = True
        self.__speech_model = settings.speech_model
        self.__chat_model = settings.chat_model
        self.__groq_api_key = settings.groq_api_key
        self.__gemini_api_key = settings.gemini_api_key
        self.__gemini_model = settings.gemini_model
        self.__transcription_model = settings.transcription_model

    def get_speech_model(self):
        # Returns the speech model setting
        return self.__speech_model
    
    def get_chat_model(self):
        # Returns the chat model setting
        return self.__chat_model
    
    def get_groq_api_key(self):
        # Returns the Groq API key
        return self.__groq_api_key
    
    def get_groq_client(self):
        # Returns a Groq client instance
        return Groq(api_key=self.__groq_api_key)
    
    def get_gemini_client(self):
        # Returns a Gemini client instance
        return genai.Client(api_key=self.__gemini_api_key)
    
    def get_gemini_model(self):
        # Returns the Gemini model setting
        return self.__gemini_model
    
    def get_transcription_model(self):
        # Returns the transcription model setting
        return self.__transcription_model

# Create singleton instance
initialized_dbs = InitializeDbs()