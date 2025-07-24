import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  static Future<String?> generateContent(String prompt) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'X-goog-api-key': _apiKey,
      },
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      return text?.toString();
    } else {
      return 'Hata: ${response.statusCode} - ${response.body}';
    }
  }
} 