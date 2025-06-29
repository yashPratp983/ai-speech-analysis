# frontend

A new Flutter project.

## File Descriptions

### Main File
- **main.dart**: The entry point for the Flutter application. It initializes the app by running the `SpeechFeedbackApp` widget, which sets up the main `MaterialApp` with a title, theme, and the home screen.

### Controller
- **audio_recording_controller.dart**: Manages the audio recording process, handling initialization, starting/stopping recording, processing audio chunks, managing transcription, and retrieving feedback.

### Models
- **audio_chunk.dart**: Represents a segment of audio data, including properties for the audio data, chunk number, and a flag indicating if it is the final chunk.
- **audio_config.dart**: Holds configuration settings for audio processing, such as sample rate, channels, bytes per sample, chunk duration, overlap, minimum recording time, and maximum concurrent requests.
- **feedback_response.dart**: Represents the response received after processing a transcription, including success status, transcription text, feedback, and a message.
- **transcription_request.dart**: Represents a request to transcribe an audio chunk, including properties for the audio chunk, a completer for the transcription result, and a timestamp.

### Screens
- **home_screen.dart**: The main user interface for the application, managing the `AudioRecordingController` to handle audio recording and transcription. It includes a recording button, status display, transcription display, and feedback history.

### Services
- **api_service.dart**: Handles communication with the backend API, providing methods for transcribing audio data and retrieving feedback based on text.
- **audio_processor.dart**: Processes audio data into chunks for transcription, managing an audio buffer, processing chunks, and converting audio samples to WAV format.
- **transcription_queue.dart**: Manages a queue of transcription requests, processing audio chunks by sending them to the `ApiService` for transcription.
- **web_audio_service.dart**: Manages the Web Audio API for real-time audio recording in a web environment, handling initialization, starting/stopping recording, and audio data processing.

### Theme
- **app_theme.dart**: Provides a `lightTheme` configuration for the Flutter application, specifying the primary color, scaffold background color, card theme, app bar theme, and elevated button theme.

### Utils
- **audio_utils.dart**: Provides utility functions for audio processing, including methods to convert audio samples to bytes, add a WAV header to PCM data, and merge transcriptions.

### Widgets
- **feedback_card.dart**: Displays feedback information in a card format, showing success status, message, transcription, and feedback.
- **recording_button.dart**: Provides a button for starting and stopping audio recording, with animations and state-based appearance changes.
- **recording_status.dart**: Displays the current status of the recording process, showing messages based on the recording, processing, or idle state.
- **transcription_display.dart**: Shows the current or final transcription, updating dynamically based on the recording state and displaying live transcription with chunk information or the final result.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
