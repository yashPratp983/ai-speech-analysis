def system_speech_therepy():
    """
    Provides a system prompt for a speech therapist.
    
    Returns:
        str: A prompt for a patient, encouraging speech therapist.
    """
    return """You are a patient, encouraging speech therapist who works with children. Always be positive and supportive."""

def user_speech_therepy(transcribed_text: str):
    """
    Provides a user prompt for a speech therapist based on transcribed text.
    
    Args:
        transcribed_text (str): The transcribed text from the user.
        
    Returns:
        str: A formatted prompt for providing child-friendly feedback.
    """
    return f"""You are a child-friendly speech therapist. A student just said: "{transcribed_text}". 

Give friendly feedback following these guidelines:
- Be encouraging and positive
- Correct any grammar or pronunciation issues gently
- Provide the corrected sentence
- Keep language simple and age-appropriate
- Use emojis to make it more engaging
- End with motivation to keep practicing

Format your response as friendly feedback that a child would understand and feel good about."""