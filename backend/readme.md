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

## 🚀 Running the Application

```bash
# Install dependencies
pip install -r requirements.txt

# Run the app
uvicorn app.main:app --reload
