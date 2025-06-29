import 'package:flutter/material.dart';
import '../controller/audio_recording_controller.dart';
import '../services/api_service.dart';
import '../widgets/recording_button.dart';
import '../widgets/feedback_card.dart';
import '../widgets/transcription_display.dart';
import '../widgets/recording_status.dart';

class HomeScreen extends StatefulWidget {
  // Main screen of the application
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AudioRecordingController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize the audio recording controller
    _controller = AudioRecordingController(apiService: ApiService());
    _controller.addListener(_onControllerStateChanged);
    _initializeController();
  }

  // Updates the UI when the controller's state changes
  void _onControllerStateChanged() {
    setState(() {});
  }

  // Initializes the audio controller and handles errors
  Future<void> _initializeController() async {
    final success = await _controller.initialize();
    if (!success && mounted) {
      _showErrorDialog(
        'Failed to initialize audio system. Please refresh the page.',
      );
    }
  }

  // Displays an error dialog
  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Retry'),
            onPressed: () {
              Navigator.pop(context);
              _initializeController();
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerStateChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Initializing audio system...'),
              SizedBox(height: 10),
              Text(
                'Please allow microphone access when prompted',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech Feedback'),
        actions: [
          if (_controller.feedbackHistory.isNotEmpty ||
              _controller.currentTranscription.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _controller.clearHistory,
              tooltip: 'Clear History',
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                RecordingStatus(
                  isRecording: _controller.isRecording,
                  isLoading: _controller.isLoading,
                  queueSize: _controller.queueSize,
                  activeRequests: _controller.activeRequests,
                ),
                const SizedBox(height: 24),
                RecordingButton(
                  onStartRecording: _controller.startRecording,
                  onStopRecording: _controller.stopRecording,
                  isRecording: _controller.isRecording,
                  isLoading: _controller.isLoading,
                ),
                const SizedBox(height: 16),
                if (_controller.isLoading) const CircularProgressIndicator(),
                if (!_controller.isRecording && !_controller.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Using Web Audio API with queue system for reliable processing',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),

          // Real-time transcription display
          if (_controller.isRecording ||
              _controller.currentTranscription.isNotEmpty ||
              _controller.finalTranscription.isNotEmpty)
            TranscriptionDisplay(
              isRecording: _controller.isRecording,
              currentTranscription: _controller.currentTranscription,
              finalTranscription: _controller.finalTranscription,
              chunkCount: _controller.chunkCount,
              isProcessing:
                  _controller.isLoading ||
                  (_controller.queueSize > 0 || _controller.activeRequests > 0),
            ),

          // Feedback history
          Expanded(
            child: _controller.feedbackHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.history, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No feedback yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Record your speech to get real-time transcription and feedback!\n\n'
                          'Transcription updates every ${_controller.config.chunkDurationMs / 1000} seconds '
                          'with ${_controller.config.overlapMs / 1000}-second overlap.\n'
                          'Minimum recording time: ${_controller.config.minimumRecordingMs / 1000} seconds.',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _controller.feedbackHistory.length,
                    itemBuilder: (context, index) {
                      return FeedbackCard(
                        feedback: _controller.feedbackHistory[index],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
