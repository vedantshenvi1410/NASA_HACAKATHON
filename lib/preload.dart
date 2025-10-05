import 'dart:async';
import '../models/planet_data.dart';
import '../Rdata/gemini_service.dart';

class PreloadService {
  final ChatGPTService _geminiService = ChatGPTService();

  /// Stores preloaded AI summaries for each planet
  final Map<String, String> _planetSummaries = {};

  /// Whether preloading is complete
  bool _isPreloaded = false;

  /// Public getter for cached summary
  String? getSummary(String planetName) => _planetSummaries[planetName];

  /// Start preloading all planets
  Future<void> preloadAll(List<Planet> planets, int sunLevel) async {
    if (_isPreloaded) return;

    final List<Future> preloadFutures = [];

    for (var planet in planets.where((p) => p.name != 'Sun')) {
      preloadFutures.add(_preloadPlanet(planet, sunLevel));
    }

    await Future.wait(preloadFutures);
    _isPreloaded = true;
  }

  Future<void> _preloadPlanet(Planet planet, int sunLevel) async {
    try {
      final summary =
          await _geminiService.generateSunEffectPrompt(planet, sunLevel);
      _planetSummaries[planet.name] = summary;
    } catch (e) {
      print(e);
      _planetSummaries[planet.name] =
          "No AI data available. ${planet.name} conditions are unknown.";
    }
  }

  /// Optional: clear cached data to reload for a new sunLevel
  void clearCache() {
    _planetSummaries.clear();
    _isPreloaded = false;
  }
}
