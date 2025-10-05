import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/planet_data.dart';

class ChatGPTService {
  final String apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  final String baseUrl = 'https://api.openai.com/v1/chat/completions';

  /// Generates short environmental summaries using the improved NASA-based prompt
  Future<String> generateSunEffectPrompt(Planet planet, int sunLevel) async {
    final prompt = _generatePrompt(planet, sunLevel);

    final body = jsonEncode({
      "model": "gpt-4o-mini",
      "messages": [
        {
          "role": "system",
          "content": "You are a scientific AI assistant specializing in solar physics and planetary environments."
        },
        {
          "role": "user",
          "content": prompt
        }
      ],
      "temperature": 0.7,
      "max_tokens": 150
    });

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded['choices'][0]['message']['content'].toString().trim();
    } else {
      throw Exception("ChatGPT API Error: ${response.body}");
    }
  }

  /// NASA-informed concise prompt for planetary impact
  String _generatePrompt(Planet planet, int sunLevel) {
    return """
In 2–3 sentences, describe how solar flares, coronal mass ejections (CMEs), and high-energy radiation from the Sun — currently in stage $sunLevel — affect conditions on ${planet.name}. 
Base your answer on NASA’s understanding of solar storms and flares (https://science.nasa.gov/sun/solar-storms-and-flares/). 
Consider ${planet.name}'s distance from the Sun, its magnetic field, and atmosphere. Focus on temperature, radiation levels, and habitability, using clear and brief scientific language.
""";
  }
}
