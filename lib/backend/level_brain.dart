import 'package:flutter/material.dart';

class LevelBrain extends ChangeNotifier {
  int _currentLevel = 1;

  int get currentLevel => _currentLevel;

  /// Increase level up to 5
  void increaseLevel() {
    _currentLevel = _currentLevel < 5 ? _currentLevel + 1 : 1;
    notifyListeners();
  }
}
