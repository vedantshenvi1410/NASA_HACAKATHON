import 'package:flutter/material.dart';
import 'dart:math';

class StarfieldWidget extends StatelessWidget {
  final double rotation;
  final double zoom;
  const StarfieldWidget({super.key, required this.rotation, required this.zoom});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: StarfieldPainter(rotation: rotation, zoom: zoom),
    );
  }
}

class StarfieldPainter extends CustomPainter {
  final double rotation;
  final double zoom;
  StarfieldPainter({required this.rotation, required this.zoom});

  final Random random = Random();
  final int starCount = 200;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = Colors.white.withOpacity(0.7);

    for (int i = 0; i < starCount; i++) {
      double x = random.nextDouble() * size.width + rotation * (i % 3) * 0.2;
      double y = random.nextDouble() * size.height + rotation * (i % 3) * 0.2;
      double radius = random.nextDouble() * 1.5 * zoom;
      canvas.drawCircle(Offset(x % size.width, y % size.height), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant StarfieldPainter oldDelegate) => true;
}
