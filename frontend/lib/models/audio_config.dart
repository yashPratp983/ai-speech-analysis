class AudioConfig {
  // Sample rate of the audio
  final int sampleRate;
  // Number of audio channels
  final int channels;
  // Bytes per audio sample
  final int bytesPerSample;
  // Duration of each audio chunk in milliseconds
  final int chunkDurationMs;
  // Overlap duration between audio chunks in milliseconds
  final int overlapMs;
  // Minimum recording duration in milliseconds
  final int minimumRecordingMs;
  // Maximum number of concurrent transcription requests
  final int maxConcurrentRequests;

  const AudioConfig({
    this.sampleRate = 44100,
    this.channels = 1,
    this.bytesPerSample = 2,
    this.chunkDurationMs = 3000,
    this.overlapMs = 1000,
    this.minimumRecordingMs = 1000,
    this.maxConcurrentRequests = 1,
  });

  // Calculates the number of samples per audio chunk
  int get samplesPerChunk => (sampleRate * chunkDurationMs / 1000).round();
  // Calculates the number of overlap samples
  int get overlapSamples => (sampleRate * overlapMs / 1000).round();
  // Calculates the minimum number of samples required for recording
  int get minimumSamples => (sampleRate * minimumRecordingMs / 1000).round();
  // Calculates the byte rate of the audio
  int get byteRate => sampleRate * channels * bytesPerSample;
  // Calculates the block alignment of the audio
  int get blockAlign => channels * bytesPerSample;
}
