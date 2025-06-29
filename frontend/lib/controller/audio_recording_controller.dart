import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/audio_config.dart';
import '../models/audio_chunk.dart';
import '../models/feedback_response.dart';
import '../services/web_audio_service.dart';
import '../services/audio_processor.dart';
import '../services/transcription_queue.dart';
import '../services/api_service.dart';
import '../utils/audio_utils.dart';

class AudioRecordingController extends ChangeNotifier {
  // Configuration for audio processing
  final AudioConfig config;
  // Service for API interactions
  final ApiService apiService;

  // Services
  late final WebAudioService _webAudioService; // Manages web audio
  late final AudioProcessor _audioProcessor; // Processes audio data
  late final TranscriptionQueue _transcriptionQueue; // Manages transcription requests

  // State variables
  bool _isInitialized = false; // Indicates if the controller is initialized
  bool _isRecording = false; // Indicates if recording is in progress
  bool _isLoading = false; // Indicates if data is being processed
  String _currentTranscription = ''; // Current transcription text
  String _finalTranscription = ''; // Final transcription text
  final List<FeedbackResponse> _feedbackHistory = []; // History of feedback responses

  // Timers for managing recording and processing
  Timer? _chunkTimer;
  Timer? _minimumRecordingTimer;
  DateTime? _recordingStartTime;

  AudioRecordingController({
    this.config = const AudioConfig(),
    required this.apiService,
  }) {
    _initializeServices();
  }

  // Getters for state variables
  bool get isInitialized => _isInitialized;
  bool get isRecording => _isRecording;
  bool get isLoading => _isLoading;
  String get currentTranscription => _currentTranscription;
  String get finalTranscription => _finalTranscription;
  List<FeedbackResponse> get feedbackHistory =>
      List.unmodifiable(_feedbackHistory);

  // Getters for monitoring services
  int get queueSize => _transcriptionQueue.queueSize;
  int get activeRequests => _transcriptionQueue.activeRequests;
  int get bufferSize => _audioProcessor.bufferSize;
  int get chunkCount => _audioProcessor.chunkCount;

  // Initializes the services used by the controller
  void _initializeServices() {
    _webAudioService = WebAudioService();

    _audioProcessor = AudioProcessor(
      config: config,
      onChunkReady: _handleChunkReady,
    );

    _transcriptionQueue = TranscriptionQueue(
      apiService: apiService,
      maxConcurrentRequests: config.maxConcurrentRequests,
      onTranscriptionResult: _handleTranscriptionResult,
    );
  }

  // Initializes the audio recording system
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final success = await _webAudioService.initialize(
        onAudioData: _audioProcessor.handleAudioData,
        onError: _handleError,
        onInitialized: () {
          _isInitialized = true;
          notifyListeners();
        },
      );

      if (success) {
        _transcriptionQueue.start();
      }

      return success;
    } catch (e) {
      debugPrint('Failed to initialize audio controller: $e');
      return false;
    }
  }

  // Starts the audio recording process
  Future<void> startRecording() async {
    if (!_isInitialized || _isRecording) return;

    try {
      _resetState();

      final success = _webAudioService.startRecording();
      if (!success) {
        throw Exception('Failed to start web audio recording');
      }

      _startTimers();

      _isRecording = true;
      _recordingStartTime = DateTime.now();
      notifyListeners();

      debugPrint('Recording started successfully');
    } catch (e) {
      debugPrint('Failed to start recording: $e');
      _handleError('Recording failed to start: ${e.toString()}');
    }
  }

  // Stops the audio recording process
  Future<void> stopRecording() async {
    if (!_isRecording) return;

    try {
      final recordingDuration = _recordingStartTime != null
          ? DateTime.now().difference(_recordingStartTime!).inMilliseconds
          : 0;

      debugPrint('Stopping recording after ${recordingDuration}ms');

      _isRecording = false;
      _webAudioService.stopRecording();
      _stopTimers();

      // Process final chunk if needed
      final finalChunk = _audioProcessor.processFinalChunk();
      if (finalChunk != null) {
        _handleChunkReady(finalChunk);
      }

      _isLoading = true;
      notifyListeners();

      // Wait for transcription queue to finish
      await _waitForTranscriptionCompletion();

      // Finalize transcription
      final transcriptionToUse = _finalTranscription.isNotEmpty
          ? _finalTranscription
          : _currentTranscription;

      if (transcriptionToUse.isNotEmpty) {
        _finalTranscription = transcriptionToUse;
        _currentTranscription = '';
        await _getFeedbackForTranscription(transcriptionToUse);
      } else {
        _isLoading = false;
        _handleError(
          'No speech detected. Please try recording again with clearer speech.',
        );
      }

      debugPrint('Recording stopped successfully');
    } catch (e) {
      _isLoading = false;
      debugPrint('Stop recording error: $e');
      _handleError('Recording failed: ${e.toString()}');
    }
  }

  // Resets the state of the controller
  void _resetState() {
    _currentTranscription = '';
    _finalTranscription = '';
    _audioProcessor.reset();
    notifyListeners();
  }

  // Starts timers for chunk processing and minimum recording duration
  void _startTimers() {
    _chunkTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_audioProcessor.bufferSize >= config.samplesPerChunk &&
          !_audioProcessor.isProcessing) {
        debugPrint(
          'Timer triggered chunk processing - buffer size: ${_audioProcessor.bufferSize}',
        );
      }
    });

    _minimumRecordingTimer = Timer(
      Duration(milliseconds: config.minimumRecordingMs),
      () => debugPrint('Minimum recording time reached'),
    );
  }

  // Stops the timers
  void _stopTimers() {
    _chunkTimer?.cancel();
    _chunkTimer = null;
    _minimumRecordingTimer?.cancel();
    _minimumRecordingTimer = null;
  }

  // Handles a ready audio chunk by adding it to the transcription queue
  void _handleChunkReady(AudioChunk chunk) {
    _transcriptionQueue.addRequest(chunk, _currentTranscription);
  }

  // Handles the result of a transcription
  void _handleTranscriptionResult(String transcription, bool isFinal) {
    if (transcription.isEmpty) return;

    if (isFinal) {
      _finalTranscription = AudioUtils.mergeTranscriptions(
        _currentTranscription,
        transcription,
      );
      _currentTranscription = '';
    } else {
      _currentTranscription = AudioUtils.mergeTranscriptions(
        _currentTranscription,
        transcription,
      );
    }

    notifyListeners();
    debugPrint(
      'Transcription updated (${isFinal ? 'final' : 'chunk'}): ${transcription.substring(0, transcription.length.clamp(0, 50))}...',
    );
  }

  // Waits for the transcription queue to complete processing
  Future<void> _waitForTranscriptionCompletion() async {
    int waitTime = 0;
    while (_transcriptionQueue.queueSize > 0 ||
        _transcriptionQueue.activeRequests > 0) {
      await Future.delayed(const Duration(milliseconds: 100));
      waitTime += 100;

      if (waitTime > 10000) {
        debugPrint('Timeout waiting for transcription queue');
        break;
      }
    }

    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Retrieves feedback for the given transcription
  Future<void> _getFeedbackForTranscription(String transcription) async {
    try {
      final response = await apiService.getFeedbackForText(
        transcription,
        _currentTranscription,
      );

      _feedbackHistory.insert(0, response);
      _isLoading = false;
      notifyListeners();

      debugPrint('Feedback received successfully');
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Feedback error: $e');
      _handleError('Feedback request failed: ${e.toString()}');
    }
  }

  // Handles errors by printing a debug message
  void _handleError(String message) {
    // Emit error event - implement your error handling here
    debugPrint('Audio Controller Error: $message');
    // You might want to add an error stream or callback here
  }

  // Clears the feedback history
  void clearHistory() {
    _feedbackHistory.clear();
    _currentTranscription = '';
    _finalTranscription = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTimers();
    _transcriptionQueue.stop();
    _webAudioService.cleanup();
    super.dispose();
  }
}
