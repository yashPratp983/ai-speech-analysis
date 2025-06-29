import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/transcription_request.dart';
import '../models/audio_chunk.dart';
import '../services/api_service.dart';

class TranscriptionQueue {
  final ApiService apiService;
  final int maxConcurrentRequests;
  final Function(String, bool) onTranscriptionResult;

  final Queue<TranscriptionRequest> _queue = Queue<TranscriptionRequest>(); // Queue to hold transcription requests
  bool _isProcessing = false; // Indicates if the queue is being processed
  int _activeRequests = 0; // Number of active transcription requests
  Timer? _processingTimer; // Timer to periodically process the queue

  TranscriptionQueue({
    required this.apiService,
    required this.onTranscriptionResult,
    this.maxConcurrentRequests = 1,
  });

  // Starts the transcription queue processing
  void start() {
    _processingTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _processQueue(),
    );
  }

  // Stops the transcription queue processing
  void stop() {
    _processingTimer?.cancel();
    _processingTimer = null;
    _queue.clear();
  }

  // Adds a transcription request to the queue
  void addRequest(AudioChunk chunk, String currentTranscription) {
    final completer = Completer<String>();
    final request = TranscriptionRequest(
      chunk: chunk,
      completer: completer,
      timestamp: DateTime.now(),
    );

    _queue.add(request);

    completer.future
        .then((transcription) {
          if (transcription.isNotEmpty) {
            onTranscriptionResult(transcription, chunk.isFinal);
          }
        })
        .catchError((error) {
          debugPrint(
            'Transcription error for chunk #${chunk.chunkNumber}: $error',
          );
        });

    debugPrint('Queued transcription request. Queue size: ${_queue.length}');
  }

  // Processes the transcription queue
  void _processQueue() {
    if (_queue.isEmpty ||
        _isProcessing ||
        _activeRequests >= maxConcurrentRequests) {
      return;
    }

    _isProcessing = true;

    try {
      while (_queue.isNotEmpty && _activeRequests < maxConcurrentRequests) {
        final request = _queue.removeFirst();

        if (request.isExpired) {
          debugPrint('Skipping expired transcription request');
          request.completer.complete('');
          continue;
        }

        _activeRequests++;
        debugPrint(
          'Processing transcription request. Active: $_activeRequests, Queue: ${_queue.length}',
        );

        _processRequest(request).whenComplete(() => _activeRequests--);
      }
    } finally {
      _isProcessing = false;
    }
  }

  // Processes an individual transcription request
  Future<void> _processRequest(TranscriptionRequest request) async {
    try {
      debugPrint(
        'Sending ${request.chunk.isFinal ? 'final' : 'chunk #${request.chunk.chunkNumber}'} for transcription (${request.chunk.audioData.length} bytes)',
      );

      final result = await apiService.transcribeAudio(
        request.chunk.audioData,
        '', // Pass current transcription context if needed
      );

      request.completer.complete(result);
    } catch (e) {
      debugPrint(
        'Transcription error for chunk #${request.chunk.chunkNumber}: $e',
      );
      request.completer.completeError(e);
    }
  }

  // Getters for monitoring
  int get queueSize => _queue.length;
  int get activeRequests => _activeRequests;
  bool get isProcessing => _isProcessing;
}
