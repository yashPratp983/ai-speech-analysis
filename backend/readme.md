# 🗣️ Speech Feedback Backend

This backend system provides APIs for transcribing audio and giving feedback for speech therapy applications. It is built with FastAPI and supports modular configuration and services for audio processing.

---

## 📁 Project Structure & File Descriptions

### Root Directory

- `dockerfile`: Docker configuration to containerize the backend service.
- `requirements.txt`: Python dependencies for the backend.
- `readme.md`: This file. Project documentation.

---

### `app/main.py`
Entry point for the FastAPI app. Includes application startup and routing configuration.

---

### `app/api/v1/`

- `feedback.py`: Defines API endpoints for receiving and sending speech feedback data.
- `health.py`: Provides a health check endpoint for monitoring service uptime.
- `transcribe.py`: Handles audio transcription-related endpoints.

---

### `app/core/config/`

- `initialiser.py`: Responsible for loading and initializing configuration at app startup.
- `settings.py`: Holds configuration values (e.g., environment variables, paths, constants).

---

### `app/core/prompts/`

- `speech_therepy.py`: Contains prompt templates or text used for generating or analyzing speech therapy feedback.

---

### `app/services/`

- `speech_service.py`: Core logic for processing speech input and generating feedback. Likely calls transcription and feedback modules.

---

### `app/utils/`

- `audio_processor.py`: Utility for processing and transforming raw audio input (e.g., conversion, resampling).
- `file_handler.py`: Handles file storage, reading, and cleanup operations.

---

### `test/`

The test directory contains comprehensive test suites for validating API functionality and ensuring code quality.

- **API Endpoint Tests**: Test files for validating all API endpoints including:
  - `test_feedback.py`: Tests for speech feedback API endpoints, covering valid inputs, validation errors, and edge cases
  - `test_transcribe.py`: Tests for audio transcription endpoints, including file upload validation and format handling
  - `test_health.py`: Tests for health check endpoints to ensure service monitoring works correctly

- **Service Layer Tests**: Unit tests for core business logic:
  - Tests for speech processing services
  - Audio processing utility tests
  - Configuration and initialization tests

- **Integration Tests**: End-to-end tests that validate the complete request-response cycle across multiple components

- **Test Utilities**: Helper functions and fixtures for setting up test data, mock objects, and common test scenarios

---

## 🚀 Running the Application

```bash
# Install dependencies
pip install -r requirements.txt

# Run the app
uvicorn app.main:app --reload
```

---

## 🧪 Running Tests

```bash

# Run specific test file
pytest test/test_feedback.py
```