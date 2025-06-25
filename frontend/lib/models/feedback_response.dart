class FeedbackResponse {
  final bool success;
  final String transcription;
  final String feedback;
  final String message;

  FeedbackResponse({
    required this.success,
    required this.transcription,
    required this.feedback,
    required this.message,
  });

  factory FeedbackResponse.fromJson(Map<String, dynamic> json) {
    return FeedbackResponse(
      success: json['success'] ?? false,
      transcription: json['transcription'] ?? '',
      feedback: json['feedback'] ?? '',
      message: json['message'] ?? '',
    );
  }
}