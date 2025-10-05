import 'dart:math';
import 'package:flutter/material.dart';
import '../models/planet_data.dart';

class SolarFlareWidget extends StatefulWidget {
  final double zoom;
  final List<Planet> planets;
  final double sunRadius;

  const SolarFlareWidget({
    super.key,
    required this.zoom,
    required this.planets,
    required this.sunRadius,
  });

  @override
  State<SolarFlareWidget> createState() => _SolarFlareWidgetState();
}

class _SolarFlareWidgetState extends State<SolarFlareWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Map<String, bool> _planetHit = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(); // continuous pulse

    // Initialize hit state for each planet
    for (var p in widget.planets) {
      _planetHit[p.name] = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _orbitRadiusFor(Planet p) {
    // Scaling same as SolarSystemView
    const double distanceScale = 4.0;
    double extraSpacing;
    switch (p.positionFromSun) {
      case 1:
        extraSpacing = 140;
        break;
      case 2:
        extraSpacing = 240;
        break;
      case 3:
        extraSpacing = 340;
        break;
      case 4:
        extraSpacing = 500;
        break;
      case 5:
        extraSpacing = 850;
        break;
      case 6:
        extraSpacing = 1350;
        break;
      case 7:
        extraSpacing = 1850;
        break;
      case 8:
        extraSpacing = 2500;
        break;
      default:
        extraSpacing = p.positionFromSun * 100.0;
    }
    return (p.distanceFromSun * distanceScale * 0.001 + extraSpacing) * widget.zoom;
  }

  double _maxOrbitDistance() {
    double maxDistance = 0;
    for (var p in widget.planets) {
      if (p.name == "Sun") continue;
      final distance = _orbitRadiusFor(p);
      if (distance > maxDistance) maxDistance = distance;
    }
    return maxDistance + 150; // extra space
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Fixed sun center (no camera offset)
    final sunCenter = Offset(screenWidth / 2, screenHeight / 2);
    final maxDistance = _maxOrbitDistance();

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final flareRadius = _controller.value * maxDistance;
        final opacity = (1 - _controller.value).clamp(0.0, 1.0);

        List<Widget> planetEffects = [];

        for (var planet in widget.planets) {
          if (planet.name == "Sun") continue;

          final orbitRadius = _orbitRadiusFor(planet);

          // Determine if planet is hit by flare
          final distanceDiff = (flareRadius - orbitRadius).abs();
          _planetHit[planet.name] = distanceDiff < 12.0;

          final shakeMagnitude =
              _planetHit[planet.name]! ? 6.0 * (1 / planet.positionFromSun) : 0.0;
          final angle = planet.positionFromSun * pi / 4; // fixed orbit angle
          final dx = cos(angle) * shakeMagnitude;
          final dy = sin(angle) * shakeMagnitude;

          final planetX = sunCenter.dx + cos(angle) * orbitRadius + dx;
          final planetY = sunCenter.dy + sin(angle) * orbitRadius + dy;

          planetEffects.add(
            Positioned(
              left: planetX - planet.radius * widget.zoom,
              top: planetY - planet.radius * widget.zoom,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: planet.radius * 2 * widget.zoom,
                height: planet.radius * 2 * widget.zoom,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orangeAccent.withOpacity(0.4 * opacity),
                ),
              ),
            ),
          );
        }

        return Stack(
          children: [
            // Expanding flare ring from sun
            Positioned(
              left: sunCenter.dx - flareRadius,
              top: sunCenter.dy - flareRadius,
              child: Container(
                width: flareRadius * 2,
                height: flareRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.orangeAccent.withOpacity(0.7 * opacity),
                    width: 4 * widget.zoom,
                  ),
                ),
              ),
            ),
            ...planetEffects
          ],
        );
      },
    );
  }
}
