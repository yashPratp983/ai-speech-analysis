import 'dart:typed_data';
import '../models/audio_config.dart';

class AudioUtils {
  // Converts audio samples to bytes
  static Uint8List convertSamplesToBytes(List<int> samples) {
    final bytes = ByteData(samples.length * 2);
    for (int i = 0; i < samples.length; i++) {
      bytes.setInt16(i * 2, samples[i], Endian.little);
    }
    return bytes.buffer.asUint8List();
  }

  // Adds a WAV header to PCM data
  static Uint8List addWavHeader(Uint8List pcmData, AudioConfig config) {
    final dataSize = pcmData.length;
    final fileSize = 36 + dataSize;

    final header = ByteData(44);

    // RIFF header
    _setString(header, 0, 'RIFF');
    header.setUint32(4, fileSize, Endian.little);
    _setString(header, 8, 'WAVE');

    // fmt chunk
    _setString(header, 12, 'fmt ');
    header.setUint32(16, 16, Endian.little); // fmt chunk size
    header.setUint16(20, 1, Endian.little); // audio format (PCM)
    header.setUint16(22, config.channels, Endian.little);
    header.setUint32(24, config.sampleRate, Endian.little);
    header.setUint32(28, config.byteRate, Endian.little);
    header.setUint16(32, config.blockAlign, Endian.little);
    header.setUint16(34, 16, Endian.little); // bits per sample

    // data chunk
    _setString(header, 36, 'data');
    header.setUint32(40, dataSize, Endian.little);

    // Combine header with PCM data
    final result = Uint8List(44 + dataSize);
    result.setAll(0, header.buffer.asUint8List());
    result.setAll(44, pcmData);

    return result;
  }

  // Sets a string value in ByteData
  static void _setString(ByteData data, int offset, String value) {
    for (int i = 0; i < value.length; i++) {
      data.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  // Merges two transcriptions
  static String mergeTranscriptions(String current, String newText) {
    if (current.isEmpty) return newText;
    if (newText.isEmpty) return current;

    final words = current.split(' ');
    final newWords = newText.split(' ');

    if (words.length >= 3 && newWords.length >= 3) {
      final lastWords = words.takeLast(3).join(' ').toLowerCase();
      final firstWords = newWords.take(3).join(' ').toLowerCase();

      if (firstWords.contains(lastWords) || lastWords.contains(firstWords)) {
        return '$current $newText';
      }
    }

    return '$current $newText';
  }
}

// Extension for List
extension ListExtension<T> on List<T> {
  // Takes the last [count] elements of the list
  Iterable<T> takeLast(int count) {
    return skip(length - count);
  }
}
