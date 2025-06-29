from fastapi.testclient import TestClient
from app.main import app

# Initialize the test client with the FastAPI app
client = TestClient(app)

def test_transcribe_valid_empty_audio():
    """
    Test the transcribe endpoint with a valid audio file format but empty content.
    
    This test verifies that the API can handle empty audio files gracefully,
    returning a successful response structure even when there's no audio content
    to transcribe. This is important for handling edge cases in real-world usage.
    """
    # Create a mock audio file with correct MIME type but no content
    file_data = ("audio.wav", b"", "audio/wav")
    
    # Make POST request with empty audio file and empty context
    response = client.post(
        "api/v1/speech-therapy/transcribe",
        files={"audio": file_data},
        data={"context": ""}
    )
    
    # Verify successful processing of empty audio
    assert response.status_code == 200
    
    # Check response structure contains expected fields
    data = response.json()
    assert "transcription" in data
    assert "success" in data

def test_transcribe_missing_file():
    """
    Test the transcribe endpoint when no audio file is provided.
    
    This test ensures proper validation of required file uploads.
    The API should return a 422 status code when the mandatory audio
    file parameter is missing from the request.
    """
    # Make request without any files - should trigger validation error
    response = client.post("api/v1/speech-therapy/transcribe")
    
    # Verify FastAPI validation error for missing required file
    assert response.status_code == 422  # FastAPI validation error

def test_transcribe_invalid_format():
    """
    Test the transcribe endpoint with an invalid file format.
    
    This test checks how the API handles non-audio files that are submitted
    to the transcription endpoint. The API should process the request but
    return success=False since the file cannot be transcribed.
    """
    # Create a text file with wrong MIME type (not audio)
    file_data = ("note.txt", b"This is not audio", "text/plain")
    
    # Submit non-audio file to transcription endpoint
    response = client.post(
        "api/v1/speech-therapy/transcribe",
        files={"audio": file_data},
        data={"context": ""}
    )
    
    # Verify the request is processed but marked as unsuccessful
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is False  # Should fail due to invalid format
    assert "transcription" in data   # Response structure should still be present