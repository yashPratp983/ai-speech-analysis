import 'dart:async';
import 'audio_chunk.dart';

class TranscriptionRequest {
  // Audio chunk to be transcribed
  final AudioChunk chunk;
  // Completer to handle the transcription result
  final Completer<String> completer;
  // Timestamp of when the request was created
  final DateTime timestamp;

  TranscriptionRequest({
    required this.chunk,
    required this.completer,
    required this.timestamp,
  });

  // Checks if the transcription request has expired
  bool get isExpired => DateTime.now().difference(timestamp).inSeconds > 10;
}
