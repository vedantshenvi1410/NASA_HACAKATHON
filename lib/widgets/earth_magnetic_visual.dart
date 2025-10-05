import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/solar_system_view.dart';

/// Fixed, top-right 2D magnetosphere visualization
/// with curved flare lines deflecting off Earth
class EarthMagneticVisual extends StatefulWidget {
  const EarthMagneticVisual({super.key});

  @override
  State<EarthMagneticVisual> createState() => _EarthMagneticVisualState();
}

class _EarthMagneticVisualState extends State<EarthMagneticVisual>
    with TickerProviderStateMixin {
  late AnimationController _fieldController;
  late AnimationController _flareController;

  @override
  void initState() {
    super.initState();
    _fieldController =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..repeat(reverse: true);

    _flareController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _fieldController.dispose();
    _flareController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final solarProvider = Provider.of<SolarSystemProvider>(context);

    if (solarProvider.flareActive && !_flareController.isAnimating) {
      _flareController.forward(from: 0);
    }

    return Positioned(
      top: 30,
      right: 20,
      child: AnimatedBuilder(
        animation: Listenable.merge([_fieldController, _flareController]),
        builder: (context, _) {
          return CustomPaint(
            painter: _MagnetospherePainter(
              fieldProgress: _fieldController.value,
              flareProgress: _flareController.value,
              flareActive: solarProvider.flareActive,
            ),
            size: const Size(200, 200),
          );
        },
      ),
    );
  }
}

class _MagnetospherePainter extends CustomPainter {
  final double fieldProgress;
  final double flareProgress;
  final bool flareActive;

  _MagnetospherePainter({
    required this.fieldProgress,
    required this.flareProgress,
    required this.flareActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = 60.0 + sin(fieldProgress * pi) * 6;

    // --- Earth ---
    final earthPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.blueAccent.shade700, Colors.greenAccent.shade400],
        center: const Alignment(-0.2, -0.2),
        radius: 0.9,
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius));
    canvas.drawCircle(center, baseRadius, earthPaint);

    // --- Magnetic field lines (curved around Earth) ---
    int linesCount = 24;
    for (int i = 0; i < linesCount; i++) {
      double angle = 2 * pi / linesCount * i + fieldProgress * 2 * pi;
      double radius = baseRadius + 10 + sin(fieldProgress * 2 * pi + i) * 5;

      final linePaint = Paint()
        ..color = Colors.cyanAccent.withOpacity(0.7)
        ..strokeWidth = 1.5;

      final start = Offset(
          center.dx + cos(angle) * radius, center.dy + sin(angle) * radius);
      final end = Offset(
          center.dx + cos(angle) * (radius + 12),
          center.dy + sin(angle) * (radius + 12));
      canvas.drawLine(start, end, linePaint);
    }

    // --- Glow halo ---
    final glowPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 18);
    canvas.drawCircle(center, baseRadius + 20, glowPaint);

    // --- Solar flare interaction: curved lines deflecting off Earth ---
    if (flareActive || flareProgress > 0) {
      final flareCount = 8;
      for (int i = 0; i < flareCount; i++) {
        final t = (flareProgress + i / flareCount) % 1;
        final flarePaint = Paint()
          ..color = Colors.orangeAccent.withOpacity(1 - t)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;

        // Curved approach: flare comes from left-top and bends around Earth
        final start = Offset(
          center.dx - 140 + t * 120,
          center.dy - 40 + i * 8,
        );

        // Calculate deflected path along a simple curve
        final control = Offset(center.dx - 20, center.dy + sin(t * pi) * 60);
        final end = Offset(
          center.dx + 140 - t * 120,
          center.dy - 40 + i * 8,
        );

        final path = Path();
        path.moveTo(start.dx, start.dy);
        path.quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
        canvas.drawPath(path, flarePaint);
      }
    }

    // --- Label ---
    final textPainter = TextPainter(
      text: const TextSpan(
        text: "Magnetosphere",
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.blueAccent, blurRadius: 6)],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - 65, size.height - 20));
  }

  @override
  bool shouldRepaint(covariant _MagnetospherePainter oldDelegate) =>
      oldDelegate.fieldProgress != fieldProgress ||
      oldDelegate.flareProgress != flareProgress ||
      oldDelegate.flareActive != flareActive;
}
