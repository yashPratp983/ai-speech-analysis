# AI Speech Tool

## Description

AI Speech Tool is a comprehensive application designed to provide speech therapy solutions. It leverages advanced AI technologies to assist users in improving their speech capabilities through interactive and personalized sessions.

## Installation

### Backend

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Create a `.env` file in the backend folder with the following environment variables:
   ```env
   SPEECH_MODEL=
   CHAT_MODEL=
   GROQ_API_KEY=
   GEMINI_API_KEY=
   GEMINI_MODEL=
   TRANSCRIPTION_MODEL=
   ```

3. Configure the environment variables:
   - **SPEECH_MODEL**: Specifies the AI model used for speech generation and processing
   - **CHAT_MODEL**: Language model deployed on Groq platform for conversational AI capabilities
   - **GROQ_API_KEY**: API key for accessing Groq services (required for chat functionality)
   - **GEMINI_API_KEY**: API key for accessing Google's Gemini AI services
   - **GEMINI_MODEL**: Specific Gemini model variant to use (e.g., gemini-pro, gemini-pro-vision)
   - **TRANSCRIPTION_MODEL**: Choose between "gemini" or "whisper" to decide which model to use for speech-to-text transcription

4. Install the required Python packages:
   ```bash
   pip install -r requirements.txt
   ```

### Frontend

1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```

2. Install the required Dart packages:
   ```bash
   flutter pub get
   ```

## Usage

### Running the Backend

1. Ensure you are in the backend directory:
   ```bash
   cd backend
   ```

2. Run the backend server:
   ```bash
   uvicorn app.main:app
   ```

### Running the Frontend

1. Ensure you are in the frontend directory:
   ```bash
   cd frontend
   ```

2. Run the frontend application:
   ```bash
   flutter run
   ```

## Project Structure

- **backend**: Contains the server-side code and API implementations.
- **frontend**: Contains the client-side code built with Flutter.

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request for any enhancements or bug fixes.

## License

This project is licensed under the MIT License.