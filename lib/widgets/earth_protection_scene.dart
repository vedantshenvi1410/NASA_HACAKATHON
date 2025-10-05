import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

/// A pseudo-3D visualization of Earth's magnetic field deflecting solar flare particles.
class EarthProtectionScene extends StatefulWidget {
  final bool active;
  final VoidCallback? onComplete;

  const EarthProtectionScene({Key? key, required this.active, this.onComplete}) : super(key: key);

  @override
  State<EarthProtectionScene> createState() => _EarthProtectionSceneState();
}

class _EarthProtectionSceneState extends State<EarthProtectionScene>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && widget.onComplete != null) {
          widget.onComplete!();
        }
      });
  }

  @override
  void didUpdateWidget(covariant EarthProtectionScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Opacity(
          opacity: Curves.easeInOut.transform(t < 0.9 ? 1 : 1 - (t - 0.9) * 10),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(color: Colors.black.withOpacity(0.8)),
              // Earth sphere
              Transform.rotate(
                angle: t * 2 * pi,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
                      radius: 0.9,
                      center: Alignment(-0.3, -0.3),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.blueAccent, blurRadius: 30, spreadRadius: 5)
                    ],
                  ),
                ),
              ),
              // Magnetic field arcs
              CustomPaint(
                size: const Size(400, 400),
                painter: _MagneticFieldPainter(t),
              ),
              // Solar particles (small orange dots)
              CustomPaint(
                size: const Size(400, 400),
                painter: _ParticlePainter(t),
              ),
              const Positioned(
                bottom: 60,
                child: Text(
                  "Earth's Magnetic Field Protects Us",
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Draw curved arcs representing magnetic field lines
class _MagneticFieldPainter extends CustomPainter {
  final double t;
  _MagneticFieldPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int i = -3; i <= 3; i++) {
      final path = Path();
      for (double a = -pi / 2; a <= pi / 2; a += 0.05) {
        final r = 100 + i * 10 + 20 * cos(a + t * 2 * pi);
        final x = center.dx + r * sin(a);
        final y = center.dy + r * cos(a) * 0.6;
        if (a == -pi / 2) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MagneticFieldPainter old) => true;
}

/// Draw orange particles that bend away from the Earth
class _ParticlePainter extends CustomPainter {
  final double t;
  _ParticlePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rand = Random(42);
    final center = Offset(size.width / 2, size.height / 2);

    final paint = Paint()..color = Colors.orangeAccent.withOpacity(0.8);
    for (int i = 0; i < 20; i++) {
      final baseAngle = -pi / 3 + rand.nextDouble() * pi / 6;
      final progress = (t * 3 + i * 0.05) % 1.2;
      if (progress > 1) continue;
      final distance = 300 - 250 * progress;
      double bend = 1 - pow(progress, 2).toDouble();
      final dx = center.dx + distance * cos(baseAngle) + bend * 30 * sin(baseAngle * 2);
      final dy = center.dy + distance * sin(baseAngle);
      canvas.drawCircle(Offset(dx, dy), 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}
