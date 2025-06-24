import os
import sys
import logging
from groq import Groq
# Application imports
from app.core.config.settings import settings

# sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

class InitializeDbs:
    _instance = None

    def __new__(cls, *args, **kwargs):
        if not cls._instance:
            cls._instance = super(InitializeDbs, cls).__new__(cls)
            cls._instance.__init__(*args, **kwargs)
        return cls._instance

    def __init__(self):
        if hasattr(self, '_initialized'):  
            return
        self._initialized = True
        self.__speech_model = settings.speech_model
        self.__chat_model = settings.chat_model
        self.__groq_api_key = settings.groq_api_key

    def get_speech_model(self):
        return self.__speech_model
    
    def get_chat_model(self):
        return self.__chat_model
    
    def get_groq_api_key(self):
        return self.__groq_api_key
    
    def get_groq_client(self):
        return Groq(api_key=self.__groq_api_key)

# Create singleton instance
initialized_dbs = InitializeDbs()