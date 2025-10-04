// lib/screens/solar_system_view.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/planet_data.dart';
import '../widgets/planet_widget.dart';
import '../widgets/planet_details_panel.dart';
import '../widgets/solar_flare_widget.dart';
import '../widgets/starfield_widget.dart';
import '../widgets/comet_widget.dart';
import '../components/navbar.dart';

/// Local provider used by this screen (keeps state simple & local)
class SolarSystemProvider extends ChangeNotifier {
  Planet? selectedPlanet;
  bool flareActive = false;

  void selectPlanet(Planet? p) {
    selectedPlanet = p;
    notifyListeners();
  }

  /// Trigger an automated "sun event" (solar flare). The caller (this file)
  /// is responsible for timing; this method simply toggles state and resets.
  void triggerFlare({Duration duration = const Duration(seconds: 3)}) {
    if (flareActive) return;
    flareActive = true;
    notifyListeners();
    Future.delayed(duration, () {
      flareActive = false;
      notifyListeners();
    });
  }
}

class SolarSystemView extends StatefulWidget {
  const SolarSystemView({super.key});

  @override
  State<SolarSystemView> createState() => _SolarSystemViewState();
}

class _SolarSystemViewState extends State<SolarSystemView>
    with TickerProviderStateMixin {
  // view transform / interaction state
  double zoom = 1.0;
  double dragRotation = 0.0;
  Offset cameraOffset = Offset.zero;

  // helpers for pinch/drag
  Offset _previousFocalPoint = Offset.zero;
  double _startZoom = 1.0;

  // animation controllers
  late final AnimationController _orbitController; // controls orbits
  late final AnimationController _moveController; // camera/zoom animations

  // animations (created on demand)
  Animation<Offset>? _cameraAnim;
  Animation<double>? _zoomAnim;

  // provider owned by this State (so timer can call it safely)
  late final SolarSystemProvider _solarProvider;

  // automated sun-event timer
  Timer? _sunEventTimer;

  // starting angle offsets so planets don't all line up
  final Map<String, double> _planetAngleOffsets = {
    'Mercury': 0.0,
    'Venus': pi / 5,
    'Earth': 2 * pi / 5,
    'Mars': 3 * pi / 5,
    'Jupiter': pi,
    'Saturn': pi / 3,
    'Uranus': 4 * pi / 3,
    'Neptune': 5 * pi / 4,
  };

  // realistic relative orbital speed multipliers (Earth = 1)
  final Map<String, double> _orbitalSpeeds = {
    'Mercury': 4.15,
    'Venus': 1.62,
    'Earth': 1.0,
    'Mars': 0.53,
    'Jupiter': 0.084,
    'Saturn': 0.034,
    'Uranus': 0.0119,
    'Neptune': 0.006,
  };

  @override
  void initState() {
    super.initState();

    // create provider instance (so timer can call triggerFlare safely)
    _solarProvider = SolarSystemProvider();

    // orbit animations (long duration, repeating)
    _orbitController =
        AnimationController(vsync: this, duration: const Duration(seconds: 240))
          ..repeat();

    // move/zoom controller for camera animations (center-on-planet)
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..addListener(() {
        // update state while animation plays
        if (_cameraAnim != null) cameraOffset = _cameraAnim!.value;
        if (_zoomAnim != null) zoom = _zoomAnim!.value;
        setState(() {});
      });

    // Sun events every 30 seconds -> trigger flare via provider
    _sunEventTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _solarProvider.triggerFlare();
    });
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _moveController.dispose();
    _sunEventTimer?.cancel();
    super.dispose();
  }

  // Calculate a planet's current angle on its orbit (in radians).
  // This uses the orbit controller value and the orbital speed multiplier.
  double _planetAngle(Planet planet) {
    final baseSpeed = _orbitalSpeeds[planet.name] ?? 1.0;
    final initialOffset = _planetAngleOffsets[planet.name] ?? 0.0;
    return (_orbitController.value * 2 * pi * baseSpeed) +
        dragRotation +
        initialOffset;
  }

  // Compute the visual orbit radius (screen pixels) for a planet.
  // We use a combination of the planet's real numeric distance and manual spacing
  // values so orbits look pleasant on a mobile screen.
  double _orbitRadiusFor(Planet p, double forZoom) {
    // tweak these values to adjust visual spacing
    const double distanceScale = 4.0; // multiplies planet.distanceFromSun
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
    // combine numeric distance and extra spacing, then scale and apply zoom
    return (p.distanceFromSun * distanceScale * 0.001 + extraSpacing) * forZoom;
  }

  // Animate the camera to center on the given planet (with optional targetZoom).
  // The algorithm calculates where the planet will be on screen (based on current
  // orbit angle) and then animates the cameraOffset so that planet lands at screen center.
  void _animateCenterOnPlanet(Planet planet, {double targetZoom = 1.2}) {
    // stop any ongoing move animation
    _moveController.stop();

    // compute target orbit radius using targetZoom (so we animate to the intended zoom)
    final targetOrbitRadius = _orbitRadiusFor(planet, targetZoom);
    final angle = _planetAngle(planet);

    // planet's world vector relative to sun (screen-space vector)
    final planetVector = Offset(cos(angle) * targetOrbitRadius, sin(angle) * targetOrbitRadius);

    // to bring planet to screen center, cameraOffset should be negative of planetVector
    final targetCameraOffset = -planetVector;

    // create tweens from current cameraOffset/zoom to targets
    _cameraAnim = Tween<Offset>(begin: cameraOffset, end: targetCameraOffset)
        .animate(CurvedAnimation(parent: _moveController, curve: Curves.easeOutCubic));
    _zoomAnim = Tween<double>(begin: zoom, end: targetZoom)
        .animate(CurvedAnimation(parent: _moveController, curve: Curves.easeOutCubic));

    _moveController.forward(from: 0.0);

    // also open the details panel for this planet
    _solarProvider.selectPlanet(planet);
  }

  // Quickly animate camera back to Sun (center) and optionally close selected planet
  void _animateCenterOnSun({double targetZoom = 1.0}) {
    _moveController.stop();

    _cameraAnim = Tween<Offset>(begin: cameraOffset, end: Offset.zero)
        .animate(CurvedAnimation(parent: _moveController, curve: Curves.easeOutCubic));
    _zoomAnim = Tween<double>(begin: zoom, end: targetZoom)
        .animate(CurvedAnimation(parent: _moveController, curve: Curves.easeOutCubic));

    _moveController.forward(from: 0.0);

    // deselect planet
    _solarProvider.selectPlanet(null);
  }

  // Gesture handlers: using onScaleStart/onScaleUpdate to support pinch + pan
  void _handleScaleStart(ScaleStartDetails details) {
    _previousFocalPoint = details.focalPoint;
    _startZoom = zoom;
    // stop any camera animation in progress
    _moveController.stop();
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    // details.scale is relative to when gesture began; apply to saved _startZoom
    final newZoom = (_startZoom * details.scale).clamp(0.4, 2.5);
    // rotation by horizontal finger delta for feel
    final rotDelta = details.focalPointDelta.dx * 0.002;

    setState(() {
      zoom = newZoom;
      dragRotation += rotDelta;
      // pan (camera offset) by the movement of focal point
      cameraOffset += (details.focalPoint - _previousFocalPoint);
      _previousFocalPoint = details.focalPoint;
    });
  }

  // Helper to build the solar system content (keeps build() tidy)
  Widget _buildSolarSystemContent(BuildContext context, SolarSystemProvider provider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        // starfield background
        StarfieldWidget(rotation: dragRotation, zoom: zoom),

        // orbits (behind planets)
        CustomPaint(
          size: Size(screenWidth, screenHeight),
          painter: _OrbitPainter(
            planets: planets,
            zoom: zoom,
            cameraOffset: cameraOffset,
            orbitRadiusFor: _orbitRadiusFor,
          ),
        ),

        // Sun (positioned at center + cameraOffset)
        Positioned(
          left: (screenWidth / 2 - 40 * zoom) + cameraOffset.dx,
          top: (screenHeight / 2 - 40 * zoom) + cameraOffset.dy,
          child: AnimatedBuilder(
            animation: _orbitController,
            builder: (_, __) {
              final sunRadius = 40 + sin(_orbitController.value * 2 * pi) * 5;
              return Container(
                width: sunRadius * 2 * zoom,
                height: sunRadius * 2 * zoom,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.yellowAccent,
                      Colors.orangeAccent.withOpacity(0.85),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // planets (on top of orbits)
        ...planets.where((p) => p.name != "Sun").map((p) {
          final orbitRadius = _orbitRadiusFor(p, zoom);
          final angle = _planetAngle(p);

          final centerX = (screenWidth / 2 + cameraOffset.dx) + cos(angle) * orbitRadius;
          final centerY = (screenHeight / 2 + cameraOffset.dy) + sin(angle) * orbitRadius;

          return Positioned(
            left: centerX - p.radius * zoom,
            top: centerY - p.radius * zoom,
            child: PlanetWidget(
              planet: p,
              rotation: angle,
              zoom: zoom,
              onTap: () {
                // animate camera to this planet when tapped
                _animateCenterOnPlanet(p, targetZoom: 1.2);
              },
            ),
          );
        }),

        // comet + solar flare effects
        CometWidget(zoom: zoom),
        if (_solarProvider.flareActive) SolarFlareWidget(zoom: zoom, planets: planets),

        // planet details panel (if selected)
        if (_solarProvider.selectedPlanet != null)
          PlanetDetailsPanel(
            planet: _solarProvider.selectedPlanet!,
            onClose: () => _solarProvider.selectPlanet(null),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SolarSystemProvider>.value(
      value: _solarProvider,
      child: Consumer<SolarSystemProvider>(builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                // main interactive area (handles gestures)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: _handleScaleStart,
                  onScaleUpdate: _handleScaleUpdate,
                  child: AnimatedBuilder(
                    animation: _orbitController,
                    builder: (_, __) => _buildSolarSystemContent(context, provider),
                  ),
                ),

                // top navbar (reusable widget)
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: NavBar(
                    onPlanetSelected: (Planet p) {
                      // when user selects from dropdown, smoothly move to planet
                      _animateCenterOnPlanet(p, targetZoom: 1.2);
                    },
                    onCenterView: () {
                      _animateCenterOnSun(targetZoom: 1.0);
                    },
                  ),
                ),

                // optional small status or hint at bottom-left
                Positioned(
                  left: 12,
                  bottom: 18,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Pinch to zoom • Drag to pan • Tap planet to focus',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

/// Orbit Painter (keeps painter logic local and consistent with orbitRadiusFor)
class _OrbitPainter extends CustomPainter {
  final List<Planet> planets;
  final double zoom;
  final Offset cameraOffset;
  final double Function(Planet, double) orbitRadiusFor;

  _OrbitPainter({
    required this.planets,
    required this.zoom,
    required this.cameraOffset,
    required this.orbitRadiusFor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2 + cameraOffset.dx, size.height / 2 + cameraOffset.dy);

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withOpacity(0.12);

    for (final p in planets.where((p) => p.name != "Sun")) {
      final r = orbitRadiusFor(p, zoom);
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) =>
      oldDelegate.planets != planets || oldDelegate.zoom != zoom || oldDelegate.cameraOffset != cameraOffset;
}
