import 'dart:math';
import 'package:flutter/material.dart';
import '../models/planet_data.dart';

class SolarFlareWidget extends StatefulWidget {
  final double zoom;
  final List<Planet> planets;

  const SolarFlareWidget({
    super.key,
    required this.zoom,
    required this.planets,
  });

  @override
  State<SolarFlareWidget> createState() => _SolarFlareWidgetState();
}

class _SolarFlareWidgetState extends State<SolarFlareWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final centerX = MediaQuery.of(context).size.width / 2;
    final centerY = MediaQuery.of(context).size.height / 2;

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final radius = _controller.value * 600 * widget.zoom;
        final opacity = (1 - _controller.value).clamp(0.0, 1.0);

        return Stack(
          children: [
            // Expanding solar flare ring
            Positioned(
              left: centerX - radius,
              top: centerY - radius,
              child: Container(
                width: radius * 2,
                height: radius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.orangeAccent.withOpacity(0.7 * opacity),
                    width: 4 * widget.zoom,
                  ),
                ),
              ),
            ),

            // Planet flare effects
            ...widget.planets.map((planet) {
              // Distance from sun in screen pixels (scaled)
              final planetDistance = planet.positionFromSun * 60.0 * widget.zoom;

              // Only affect planets within flare radius
              if (radius >= planetDistance) {
                return Positioned(
                  left: centerX + cos(planetDistance) * planetDistance - planet.radius * widget.zoom,
                  top: centerY + sin(planetDistance) * planetDistance - planet.radius * widget.zoom,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: planet.radius * 2 * widget.zoom +
                        (planet.hasMagneticField ? 10 * widget.zoom : 0),
                    height: planet.radius * 2 * widget.zoom +
                        (planet.hasMagneticField ? 10 * widget.zoom : 0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: planet.hasMagneticField
                          ? Colors.cyanAccent.withOpacity(0.3 * opacity)
                          : Colors.red.withOpacity(0.3 * opacity),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }).toList(),
          ],
        );
      },
    );
  }
}
