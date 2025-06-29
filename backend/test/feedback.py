from fastapi.testclient import TestClient
from app.main import app

# Initialize the test client with the FastAPI app
client = TestClient(app)

def test_feedback_valid_transcription():
    """
    Test the feedback endpoint with a valid transcription.
    
    This test verifies that the API correctly processes a normal transcription
    string and returns the expected response structure with success status,
    feedback content, and the original transcription.
    """
    # Using params - clean and readable approach for query parameters
    params = {"transcription": "Hello, how are you today?"}
    
    # Make POST request to the speech therapy feedback endpoint
    response = client.post("/api/v1/speech-therapy/feedback", params=params)
    
    # Verify successful response
    assert response.status_code == 200
    
    # Parse response data and verify structure
    data = response.json()
    assert data["success"] is True
    assert "feedback" in data
    assert "transcription" in data

def test_feedback_missing_transcription_field():
    """
    Test the feedback endpoint when transcription parameter is missing.
    
    This test ensures the API properly validates required fields and returns
    a 422 Unprocessable Entity status when mandatory parameters are absent.
    """
    # No transcription parameter - should return 422
    response = client.post("/api/v1/speech-therapy/feedback")
    
    # Verify validation error response
    assert response.status_code == 422  # Required field missing

def test_feedback_empty_transcription():
    """
    Test the feedback endpoint with an empty transcription string.
    
    This test checks how the API handles empty strings, which should still
    be processed successfully (empty string is valid but different from missing).
    """
    # Empty transcription string
    params = {"transcription": ""}
    
    # Make request with empty transcription
    response = client.post("/api/v1/speech-therapy/feedback", params=params)
    
    # Verify the API still processes empty strings successfully
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "feedback" in data

# Additional test cases for robustness and edge case coverage
def test_feedback_whitespace_transcription():
    """
    Test the feedback endpoint with whitespace-only transcription.
    
    This edge case test ensures the API handles strings containing only
    whitespace characters, which may require different processing logic
    than completely empty strings.
    """
    # Test with whitespace-only transcription
    params = {"transcription": "   "}
    
    # Make request with whitespace-only transcription
    response = client.post("/api/v1/speech-therapy/feedback", params=params)
    
    # Verify whitespace strings are processed successfully
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "feedback" in data