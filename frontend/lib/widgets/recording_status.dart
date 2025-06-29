import 'package:flutter/material.dart';

class RecordingStatus extends StatelessWidget {
  final bool isRecording;
  final bool isLoading;
  final int queueSize;
  final int activeRequests;

  const RecordingStatus({
    super.key,
    required this.isRecording,
    required this.isLoading,
    required this.queueSize,
    required this.activeRequests,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Displays the current recording or processing status
        Text(
          isRecording
              ? 'Recording... Tap to stop'
              : isLoading
              ? 'Processing your speech...'
              : 'Tap to start recording',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        // Displays queue and active request information when recording
        if (isRecording)
          Text(
            'Queue: $queueSize | Active: $activeRequests',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
      ],
    );
  }
}
