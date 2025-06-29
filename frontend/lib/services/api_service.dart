import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/feedback_response.dart';

class ApiService {
  static const String baseUrl =
      'https://ai-speech-analysis.onrender.com'; // Update with your actual backend URL

  // Sends audio data for real-time transcription
  Future<String> transcribeAudio(Uint8List audioData, String context) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/v1/speech-therapy/transcribe'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'audio',
          audioData,
          filename: 'chunk.wav',
          contentType: MediaType('audio', 'wav'),
        ),
      );

      // Add context as a field in the request
      request.fields['context'] = context;

      var response = await request.send();
      var responseData = await response.stream.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseData);
        return jsonResponse['transcription'] ?? '';
      } else {
        throw Exception(
          'Transcription error: ${response.statusCode} - $responseData',
        );
      }
    } catch (e) {
      // Return empty string for failed transcriptions to avoid disrupting the flow
      print('Transcription error: $e');
      return '';
    }
  }

  // Retrieves feedback based on the provided transcription
  Future<FeedbackResponse> getFeedbackForText(
    String transcription,
    context,
  ) async {
    try {
      var response = await http.post(
        Uri.parse('$baseUrl/api/v1/speech-therapy/feedback'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'transcription': transcription}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        // Create a FeedbackResponse with the transcription and feedback
        return FeedbackResponse.fromJson({
          'transcription': transcription,
          'feedback': jsonResponse['feedback'],
          'success': true,
          'message':
              jsonResponse['message'] ?? 'Feedback generated successfully',
        });
      } else {
        throw Exception(
          'Feedback error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
