import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/planet_data.dart';

class GeminiService {
  // Load API key from .env
  final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  final String baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=';

  /// Generates a short summary about planetary living conditions
  Future<String> generateSunEffectPrompt(Planet planet, int sunLevel) async {
    if (apiKey.isEmpty) {
      throw Exception("Gemini API key not set in .env");
    }

    final prompt = _generatePrompt(planet, sunLevel);

    final uri = Uri.parse('$baseUrl$apiKey');
    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ]
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded['candidates'][0]['content']['parts'][0]['text'] ?? 
             "No summary returned by Gemini API.";
    } else {
      throw Exception("Gemini API Error: ${response.body}");
    }
  }

  /// Internal method to generate prompt
  String _generatePrompt(Planet planet, int sunLevel) {
    return """
Provide a short 2-3 sentence summary about the living conditions on ${planet.name}, 
considering the Sun's stage $sunLevel, temperature, and radiation effects. 
Focus only on habitability or planetary environment. Do not write a long story.
""";
  }
}
