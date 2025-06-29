class FeedbackResponse {
  // Indicates if the feedback was successful
  final bool success;
  // Transcription text associated with the feedback
  final String transcription;
  // Feedback message
  final String feedback;
  // Additional message or information
  final String message;

  FeedbackResponse({
    required this.success,
    required this.transcription,
    required this.feedback,
    required this.message,
  });

  // Factory method to create a FeedbackResponse from JSON
  factory FeedbackResponse.fromJson(Map<String, dynamic> json) {
    return FeedbackResponse(
      success: json['success'] ?? false,
      transcription: json['transcription'] ?? '',
      feedback: json['feedback'] ?? '',
      message: json['message'] ?? '',
    );
  }
}