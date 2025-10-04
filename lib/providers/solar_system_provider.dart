import 'package:flutter/material.dart';
import '../models/planet_data.dart';

class SolarSystemProvider extends ChangeNotifier {
  Planet? selectedPlanet;
  bool flareActive = false;

  void selectPlanet(Planet? planet) {
    selectedPlanet = planet;
    notifyListeners();
  }

  void triggerFlare() {
    flareActive = true;
    notifyListeners();
    Future.delayed(const Duration(seconds: 6), () {
      flareActive = false;
      notifyListeners();
    });
  }
}
