import 'dart:typed_data';

class AudioChunk {
  // Raw audio data for the chunk
  final Uint8List audioData;
  // Sequence number of the chunk
  final int chunkNumber;
  // Indicates if this is the final chunk
  final bool isFinal;

  const AudioChunk({
    required this.audioData,
    required this.chunkNumber,
    required this.isFinal,
  });

  @override
  String toString() =>
      'AudioChunk(#$chunkNumber, ${audioData.length} bytes, final: $isFinal)';
}
