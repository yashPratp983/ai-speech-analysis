import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/feedback_response.dart';

class ApiService {
  static const String baseUrl = 'https://ai-speech-analysis.onrender.com';
  
  Future<FeedbackResponse> uploadAudio(Uint8List audioData) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/v1/speech-therapy/feedback'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'audio',
          audioData,
          filename: 'recording.wav',
          contentType: MediaType('audio', 'wav'),
        ),
      );

      var response = await request.send();
      var responseData = await response.stream.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        return FeedbackResponse.fromJson(json.decode(responseData));
      } else {
        throw Exception('Server error: ${response.statusCode} - $responseData');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}