import 'package:flutter/material.dart';

class LevelOverlay extends StatelessWidget {
  final int level;

  const LevelOverlay({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Level $level',
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }
}
