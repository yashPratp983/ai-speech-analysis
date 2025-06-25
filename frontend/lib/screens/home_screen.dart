import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../models/feedback_response.dart';
import '../services/api_service.dart';
import '../widgets/recording_button.dart';
import '../widgets/feedback_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Recorder and stream controller
  FlutterSoundRecorder? _recorder;
  final StreamController<Uint8List> _recordingStreamController = StreamController<Uint8List>.broadcast();
  
  // State variables
  bool _isRecording = false;
  bool _isLoading = false;
  bool _isRecorderInitialized = false;
  bool _isInitializing = false;
  
  // Audio data and feedback
  Uint8List? _recordedAudio;
  String? _recordingPath;
  final List<FeedbackResponse> _feedbackHistory = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _initRecorderWithRetry();
  }

  Future<void> _initRecorderWithRetry({int retries = 3}) async {
    if (_isInitializing) return;
    
    setState(() => _isInitializing = true);
    int attempt = 0;
    
    while (attempt < retries && !_isRecorderInitialized) {
      attempt++;
      try {
        await _initRecorder();
        if (_isRecorderInitialized) break;
        
        await Future.delayed(Duration(seconds: attempt));
      } catch (e) {
        debugPrint('Initialization attempt $attempt failed: $e');
      }
    }
    
    setState(() => _isInitializing = false);
    
    if (!_isRecorderInitialized && mounted) {
      _showErrorDialog('Audio system initialization failed after $retries attempts');
    }
  }

  Future<void> _initRecorder() async {
    try {
      // Clean up existing recorder
      if (_recorder != null) {
        await _recorder?.closeRecorder();
        await Future.delayed(Duration(milliseconds: 200));
      }

      _recorder = FlutterSoundRecorder();
      await Future.delayed(Duration(milliseconds: 300));
      await _recorder!.openRecorder();
      
      // Request permissions for mobile
      if (!kIsWeb) {
        final status = await Permission.microphone.request();
        if (status != PermissionStatus.granted) {
          throw Exception('Microphone permission denied');
        }
      }

      // Verify encoder support - prefer pcm16WAV for better compatibility
      if (!await _recorder!.isEncoderSupported(Codec.pcm16WAV)) {
        // Fallback to AAC if PCM is not supported
        if (!await _recorder!.isEncoderSupported(Codec.aacADTS)) {
          throw Exception('No supported audio format found');
        }
      }

      setState(() => _isRecorderInitialized = true);
    } catch (e) {
      debugPrint('Recorder initialization error: $e');
      _recorder = null;
      rethrow;
    }
  }

  Future<String> _getRecordingPath() async {
    if (kIsWeb) {
      return ''; // Web doesn't use file paths
    }
    
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${directory.path}/recording_$timestamp.wav';
  }

  void _handleRecordingData(Uint8List data) {
    if (!mounted) return;
    
    setState(() {
      if (_recordedAudio == null) {
        _recordedAudio = Uint8List.fromList(data);
      } else {
        // Efficiently combine audio data
        final combined = Uint8List(_recordedAudio!.length + data.length);
        combined.setAll(0, _recordedAudio!);
        combined.setAll(_recordedAudio!.length, data);
        _recordedAudio = combined;
      }
    });
  }

  Future<void> _startRecording() async {
    if (!_isRecorderInitialized) {
      await _initRecorderWithRetry();
      if (!_isRecorderInitialized) return;
    }

    try {
      // Clear previous recording data
      setState(() {
        _recordedAudio = null;
        _recordingPath = null;
      });

      if (kIsWeb) {
        // Web recording - use stream
        await _recorder!.startRecorder(
          toStream: _recordingStreamController.sink,
          codec: Codec.pcm16WAV,
          sampleRate: 44100, // Ensure consistent sample rate
          numChannels: 1,    // Mono recording
        );
        
        // Listen to the stream
        _recordingStreamController.stream.listen(
          _handleRecordingData,
          onError: (error) {
            debugPrint('Recording stream error: $error');
            _showErrorDialog('Recording stream error: $error');
          },
        );
      } else {
        // Mobile recording - use file
        _recordingPath = await _getRecordingPath();
        await _recorder!.startRecorder(
          toFile: _recordingPath,
          codec: Codec.pcm16WAV,
          sampleRate: 44100, // Ensure consistent sample rate
          numChannels: 1,    // Mono recording
          bitRate: 128000,   // Good quality bitrate
        );
      }

      setState(() => _isRecording = true);
      debugPrint('Recording started successfully');
    } catch (e) {
      debugPrint('Failed to start recording: $e');
      _showErrorDialog('Recording failed to start: ${e.toString()}');
    }
  }

  Future<void> _stopRecording() async {
    if (_recorder == null || !_isRecording) return;
    
    try {
      setState(() => _isRecording = false);
      
      if (kIsWeb) {
        await _recorder!.stopRecorder();
        // For web, audio data is already collected via stream
        debugPrint('Web recording stopped. Audio data length: ${_recordedAudio?.length ?? 0}');
      } else {
        // Mobile recording
        final path = await _recorder!.stopRecorder();
        debugPrint('Mobile recording stopped. Path: $path');
        
        if (path != null && await File(path).exists()) {
          _recordedAudio = await File(path).readAsBytes();
          debugPrint('Audio file read. Size: ${_recordedAudio?.length ?? 0} bytes');
          
          // Clean up temporary file after reading
          try {
            await File(path).delete();
          } catch (e) {
            debugPrint('Failed to delete temp file: $e');
          }
        } else {
          throw Exception('Recording file not found or empty');
        }
      }

      // Validate audio data
      if (_recordedAudio == null || _recordedAudio!.isEmpty) {
        throw Exception('No audio data recorded');
      }

      // Ensure minimum audio length (e.g., at least 0.5 seconds)
      final minBytes = kIsWeb ? 8000 : 44100; // Approximate minimum for 0.5s
      if (_recordedAudio!.length < minBytes) {
        throw Exception('Recording too short. Please record for at least 1 second.');
      }

      setState(() => _isLoading = true);
      await _uploadAndGetFeedback();
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Stop recording error: $e');
      _showErrorDialog('Recording failed: ${e.toString()}');
    }
  }

  Future<void> _uploadAndGetFeedback() async {
    if (_recordedAudio == null || _recordedAudio!.isEmpty) {
      setState(() => _isLoading = false);
      _showErrorDialog('No audio data to upload');
      return;
    }
    
    try {
      debugPrint('Uploading audio data. Size: ${_recordedAudio!.length} bytes');
      
      // Add WAV header if needed (for raw PCM data from web)
      Uint8List audioToUpload = _recordedAudio!;
      if (kIsWeb && !_hasWavHeader(_recordedAudio!)) {
        audioToUpload = _addWavHeader(_recordedAudio!);
        debugPrint('Added WAV header. New size: ${audioToUpload.length} bytes');
      }
      
      final response = await _apiService.uploadAudio(audioToUpload);
      
      setState(() {
        _feedbackHistory.insert(0, response);
        _isLoading = false;
        _recordedAudio = null;
      });
      
      debugPrint('Feedback received successfully');
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Upload error: $e');
      _showErrorDialog('Feedback request failed: ${e.toString()}');
    }
  }

  // Check if audio data already has WAV header
  bool _hasWavHeader(Uint8List data) {
    if (data.length < 12) return false;
    
    // Check for "RIFF" at start and "WAVE" at position 8
    return data[0] == 0x52 && data[1] == 0x49 && data[2] == 0x46 && data[3] == 0x46 && // "RIFF"
           data[8] == 0x57 && data[9] == 0x41 && data[10] == 0x56 && data[11] == 0x45;   // "WAVE"
  }

  // Add WAV header to raw PCM data
  Uint8List _addWavHeader(Uint8List pcmData) {
    final sampleRate = 44100;
    final numChannels = 1;
    final bitsPerSample = 16;
    final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    final blockAlign = numChannels * bitsPerSample ~/ 8;
    final dataSize = pcmData.length;
    final fileSize = 36 + dataSize;

    final header = ByteData(44);
    
    // RIFF header
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, fileSize, Endian.little);
    header.setUint8(8, 0x57);  // W
    header.setUint8(9, 0x41);  // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E
    
    // fmt chunk
    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6D); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // space
    header.setUint32(16, 16, Endian.little); // fmt chunk size
    header.setUint16(20, 1, Endian.little);  // audio format (PCM)
    header.setUint16(22, numChannels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    
    // data chunk
    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, dataSize, Endian.little);
    
    // Combine header with PCM data
    final result = Uint8List(44 + dataSize);
    result.setAll(0, header.buffer.asUint8List());
    result.setAll(44, pcmData);
    
    return result;
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
          if (!message.contains('permission'))
            TextButton(
              child: Text('Retry'),
              onPressed: () {
                Navigator.pop(context);
                _initRecorderWithRetry();
              },
            ),
        ],
      ),
    );
  }

  void _clearHistory() {
    setState(() => _feedbackHistory.clear());
  }

  @override
  void dispose() {
    _recordingStreamController.close();
    _recorder?.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Setting up audio system...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Speech Feedback'),
        actions: [
          if (_feedbackHistory.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear_all),
              onPressed: _clearHistory,
              tooltip: 'Clear History',
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(32),
            child: Column(
              children: [
                Text(
                  _isRecording
                      ? 'Recording... Tap to stop'
                      : _isLoading
                          ? 'Processing your speech...'
                          : 'Tap to start recording',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                RecordingButton(
                  onStartRecording: _startRecording,
                  onStopRecording: _stopRecording,
                  isRecording: _isRecording,
                  isLoading: _isLoading,
                ),
                SizedBox(height: 16),
                if (_isLoading)
                  CircularProgressIndicator(),
                if (kIsWeb && !_isRecording && !_isLoading)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Note: Make sure to allow microphone access in your browser',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _feedbackHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No feedback yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Record your speech to get feedback!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _feedbackHistory.length,
                    itemBuilder: (context, index) {
                      return FeedbackCard(
                        feedback: _feedbackHistory[index],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}