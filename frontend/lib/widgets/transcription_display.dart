import 'package:flutter/material.dart';

class TranscriptionDisplay extends StatelessWidget {
  final bool isRecording;
  final String currentTranscription;
  final String finalTranscription;
  final int chunkCount;
  final bool isProcessing;

  const TranscriptionDisplay({
    super.key,
    required this.isRecording,
    required this.currentTranscription,
    required this.finalTranscription,
    required this.chunkCount,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon indicating recording or text mode
              Icon(
                isRecording ? Icons.mic : Icons.text_fields,
                color: isRecording ? Colors.red : Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              // Displays the transcription status
              Text(
                isRecording
                    ? 'Live Transcription (Chunk #$chunkCount)'
                    : 'Final Transcription',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isRecording ? Colors.red : Colors.blue,
                ),
              ),
              // Shows a loading indicator if processing
              if (isProcessing)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Displays the current or final transcription text
          Text(
            isRecording
                ? (currentTranscription.isEmpty
                      ? 'Listening...'
                      : currentTranscription)
                : finalTranscription,
            style: TextStyle(
              fontSize: 16,
              fontStyle: currentTranscription.isEmpty && isRecording
                  ? FontStyle.italic
                  : FontStyle.normal,
              color: currentTranscription.isEmpty && isRecording
                  ? Colors.grey[600]
                  : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
