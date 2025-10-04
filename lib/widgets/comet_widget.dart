import 'package:flutter/material.dart';

class CometWidget extends StatefulWidget {
  final double zoom;
  const CometWidget({super.key, required this.zoom});

  @override
  State<CometWidget> createState() => _CometWidgetState();
}

class _CometWidgetState extends State<CometWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late double startX, startY, endX, endY;

  @override
  void initState() {
    super.initState();
    // ignore: deprecated_member_use
    final size = WidgetsBinding.instance.window.physicalSize;
    startX = -50;
    startY = 50 + (200 * (0.5 + 0.5));
    endX = 400 + 50;
    endY = startY + 100;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          double x = startX + (endX - startX) * _controller.value;
          double y = startY + (endY - startY) * _controller.value;
          return Positioned(
            left: x * widget.zoom,
            top: y * widget.zoom,
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Colors.white),
            ),
          );
        });
  }
}
