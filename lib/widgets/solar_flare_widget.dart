// ignore: unused_import
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/planet_data.dart';

class SolarFlareWidget extends StatefulWidget {
  final double zoom;
  final List<Planet> planets;
  const SolarFlareWidget({super.key, required this.zoom, required this.planets});

  @override
  State<SolarFlareWidget> createState() => _SolarFlareWidgetState();
}

class _SolarFlareWidgetState extends State<SolarFlareWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double centerX = MediaQuery.of(context).size.width / 2;
    double centerY = MediaQuery.of(context).size.height / 2;

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        double radius = _controller.value * 600 * widget.zoom;
        double opacity = 1 - _controller.value;
        return Stack(
          children: [
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
                      width: 4),
                ),
              ),
            ),
            ...widget.planets.map((p) {
              double distance = p.positionFromSun * 60.0 * widget.zoom;
              if (radius >= distance) {
                return Positioned(
                  left: centerX + distance - p.radius,
                  top: centerY - p.radius,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: p.radius * 2 + (p.hasMagneticField ? 10 : 0),
                    height: p.radius * 2 + (p.hasMagneticField ? 10 : 0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.hasMagneticField
                          ? Colors.cyanAccent.withOpacity(0.3)
                          : Colors.red.withOpacity(0.3),
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
