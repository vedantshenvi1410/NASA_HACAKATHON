import 'package:flutter/material.dart';
import '../models/planet_data.dart';

class PlanetWidget extends StatelessWidget {
  final Planet planet;
  final double rotation;
  final double zoom;
  final VoidCallback onTap;

  const PlanetWidget({
    super.key,
    required this.planet,
    required this.rotation,
    required this.zoom,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: planet.radius * 2 * zoom,
        height: planet.radius * 2 * zoom,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: planet.color,
          boxShadow: [
            BoxShadow(
              color: planet.color.withOpacity(0.6),
              blurRadius: 8 * zoom,
              spreadRadius: 2 * zoom,
            )
          ],
        ),
        child: Center(
          child: Text(
            planet.name[0],
            style: TextStyle(
                color: Colors.white,
                fontSize: 12 * zoom,
                fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
