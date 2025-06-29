import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/audio_chunk.dart';
import '../models/audio_config.dart';
import '../utils/audio_utils.dart';

class AudioProcessor {
  final AudioConfig config;
  final Function(AudioChunk) onChunkReady;

  List<int> _audioBuffer = []; // Buffer to store incoming audio data
  bool _isProcessingChunk = false; // Indicates if a chunk is being processed
  int _chunkCount = 0; // Counter for processed chunks

  AudioProcessor({required this.config, required this.onChunkReady});

  // Handles incoming audio data and processes it into chunks
  void handleAudioData(List<int> audioData) {
    _audioBuffer.addAll(audioData);

    if (_audioBuffer.length >= config.samplesPerChunk && !_isProcessingChunk) {
      _processAudioChunk();
    }
  }

  // Processes a chunk of audio data
  void _processAudioChunk() {
    if (_isProcessingChunk || _audioBuffer.length < config.samplesPerChunk)
      return;

    _isProcessingChunk = true;
    _chunkCount++;

    try {
      final chunk = _audioBuffer.take(config.samplesPerChunk).toList();

      final samplesToRemove = config.samplesPerChunk - config.overlapSamples;
      if (samplesToRemove > 0 && _audioBuffer.length > samplesToRemove) {
        _audioBuffer = _audioBuffer.skip(samplesToRemove).toList();
      }

      debugPrint(
        'Processing chunk #$_chunkCount: ${chunk.length} samples, buffer remaining: ${_audioBuffer.length}',
      );

      final audioBytes = AudioUtils.convertSamplesToBytes(chunk);
      final wavData = AudioUtils.addWavHeader(audioBytes, config);

      onChunkReady(
        AudioChunk(
          audioData: wavData,
          chunkNumber: _chunkCount,
          isFinal: false,
        ),
      );
    } catch (e) {
      debugPrint('Error processing audio chunk: $e');
    } finally {
      _isProcessingChunk = false;
    }
  }

  // Processes the final chunk of audio data
  AudioChunk? processFinalChunk() {
    if (_audioBuffer.isEmpty) return null;

    if (_audioBuffer.length >= config.minimumSamples) {
      final audioBytes = AudioUtils.convertSamplesToBytes(_audioBuffer);
      final wavData = AudioUtils.addWavHeader(audioBytes, config);

      return AudioChunk(
        audioData: wavData,
        chunkNumber: ++_chunkCount,
        isFinal: true,
      );
    }

    return null;
  }

  // Resets the audio processor state
  void reset() {
    _audioBuffer.clear();
    _isProcessingChunk = false;
    _chunkCount = 0;
  }

  // Getters for monitoring
  int get bufferSize => _audioBuffer.length;
  int get chunkCount => _chunkCount;
  bool get isProcessing => _isProcessingChunk;
}
