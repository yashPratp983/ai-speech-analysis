# 📱 Frontend

A new Flutter project for recording speech, transcribing it, and displaying feedback.  
👉 **All folders and files are located inside the `lib/` folder.**

---

## 📁 Folder Structure

- `lib/`
  - `main.dart`
  - `controllers/`
    - `audio_recording_controller.dart`
  - `models/`
    - `audio_chunk.dart`
    - `audio_config.dart`
    - `feedback_response.dart`
    - `transcription_request.dart`
  - `screens/`
    - `home_screen.dart`
  - `services/`
    - `api_service.dart`
    - `audio_processor.dart`
    - `transcription_queue.dart`
    - `web_audio_service.dart`
  - `theme/`
    - `app_theme.dart`
  - `utils/`
    - `audio_utils.dart`
  - `widgets/`
    - `feedback_card.dart`
    - `recording_button.dart`
    - `recording_status.dart`
    - `transcription_display.dart`

---

## 📄 File Descriptions

### 🔹 Main File

- **main.dart**: The entry point for the Flutter application. It initializes the app by running the `SpeechFeedbackApp` widget, which sets up the main `MaterialApp` with a title, theme, and the home screen.

---

### 🔹 Controller (`lib/controllers/`)

- **audio_recording_controller.dart**: Manages the audio recording process, including initialization, starting/stopping, processing audio chunks, managing transcription, and retrieving feedback.

---

### 🔹 Models (`lib/models/`)

- **audio_chunk.dart**: Represents a segment of audio data, including properties for the audio data, chunk number, and a flag indicating if it is the final chunk.
- **audio_config.dart**: Holds configuration settings for audio processing, such as sample rate, channels, bytes per sample, chunk duration, overlap, minimum recording time, and maximum concurrent requests.
- **feedback_response.dart**: Represents the response received after processing a transcription, including success status, transcription text, feedback, and a message.
- **transcription_request.dart**: Represents a request to transcribe an audio chunk, including properties for the audio chunk, a completer for the transcription result, and a timestamp.

---

### 🔹 Screens (`lib/screens/`)

- **home_screen.dart**: The main user interface for the application, managing the `AudioRecordingController` to handle audio recording and transcription. It includes a recording button, status display, transcription display, and feedback history.

---

### 🔹 Services (`lib/services/`)

- **api_service.dart**: Handles communication with the backend API, providing methods for transcribing audio data and retrieving feedback based on text.
- **audio_processor.dart**: Processes audio data into chunks for transcription, managing an audio buffer, processing chunks, and converting audio samples to WAV format.
- **transcription_queue.dart**: Manages a queue of transcription requests, processing audio chunks by sending them to the `ApiService` for transcription.
- **web_audio_service.dart**: Manages the Web Audio API for real-time audio recording in a web environment, handling initialization, starting/stopping recording, and audio data processing.

---

### 🔹 Theme (`lib/theme/`)

- **app_theme.dart**: Provides a `lightTheme` configuration for the Flutter application, specifying the primary color, scaffold background color, card theme, app bar theme, and elevated button theme.

---

### 🔹 Utils (`lib/utils/`)

- **audio_utils.dart**: Provides utility functions for audio processing, including methods to convert audio samples to bytes, add a WAV header to PCM data, and merge transcriptions.

---

### 🔹 Widgets (`lib/widgets/`)

- **feedback_card.dart**: Displays feedback information in a card format, showing success status, message, transcription, and feedback.
- **recording_button.dart**: Provides a button for starting and stopping audio recording, with animations and state-based appearance changes.
- **recording_status.dart**: Displays the current status of the recording process, showing messages based on the recording, processing, or idle state.
- **transcription_display.dart**: Shows the current or final transcription, updating dynamically based on the recording state and displaying live transcription with chunk information or the final result.

---

## ▶️ Running the App

Make sure Flutter is installed, then run:

```bash
flutter pub get
flutter run
