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
import '../preload.dart';

class SolarSystemProvider extends ChangeNotifier {
  Planet? selectedPlanet;
  bool flareActive = false;

  void selectPlanet(Planet? p) {
    selectedPlanet = p;
    notifyListeners();
  }

  void triggerFlare() {
    flareActive = true;
    notifyListeners();

    // flare lasts 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
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
  double zoom = 1.0;
  double dragRotation = 0.0;
  Offset cameraOffset = Offset.zero;
  Offset _previousFocalPoint = Offset.zero;
  double _startZoom = 1.0;

  late final AnimationController _orbitController;
  late final AnimationController _moveController;
  Animation<Offset>? _cameraAnim;
  Animation<double>? _zoomAnim;

  late final SolarSystemProvider _solarProvider;
  late final PreloadService _preloadService;

  Timer? _sunEventTimer;
  int sunLevel = 1;

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

    _solarProvider = SolarSystemProvider();
    _preloadService = PreloadService();
    _preloadService.preloadAll(planets, sunLevel);

    _orbitController =
        AnimationController(vsync: this, duration: const Duration(seconds: 240))
          ..repeat();

    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..addListener(() {
        if (_cameraAnim != null) cameraOffset = _cameraAnim!.value;
        if (_zoomAnim != null) zoom = _zoomAnim!.value;
        setState(() {});
      });

    // trigger flare every 30 seconds
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

  double _planetAngle(Planet planet) {
    final baseSpeed = _orbitalSpeeds[planet.name] ?? 1.0;
    final initialOffset = _planetAngleOffsets[planet.name] ?? 0.0;
    return (_orbitController.value * 2 * pi * baseSpeed) +
        dragRotation +
        initialOffset;
  }

  double _orbitRadiusFor(Planet p, double forZoom) {
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
    return (p.distanceFromSun * distanceScale * 0.001 + extraSpacing) * forZoom;
  }

  void _animateCenterOnPlanet(Planet planet, {double targetZoom = 1.2}) {
    _moveController.stop();
    final targetOrbitRadius = _orbitRadiusFor(planet, targetZoom);
    final angle = _planetAngle(planet);
    final planetVector =
        Offset(cos(angle) * targetOrbitRadius, sin(angle) * targetOrbitRadius);
    final targetCameraOffset = -planetVector;

    _cameraAnim = Tween<Offset>(begin: cameraOffset, end: targetCameraOffset)
        .animate(
            CurvedAnimation(parent: _moveController, curve: Curves.easeOutCubic));
    _zoomAnim = Tween<double>(begin: zoom, end: targetZoom).animate(
        CurvedAnimation(parent: _moveController, curve: Curves.easeOutCubic));

    _moveController.forward(from: 0.0);
    _solarProvider.selectPlanet(planet);
  }

  void _animateCenterOnSun({double targetZoom = 1.0}) {
    _moveController.stop();
    _cameraAnim = Tween<Offset>(begin: cameraOffset, end: Offset.zero).animate(
        CurvedAnimation(parent: _moveController, curve: Curves.easeOutCubic));
    _zoomAnim = Tween<double>(begin: zoom, end: targetZoom).animate(
        CurvedAnimation(parent: _moveController, curve: Curves.easeOutCubic));

    _moveController.forward(from: 0.0);
    _solarProvider.selectPlanet(null);
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _previousFocalPoint = details.focalPoint;
    _startZoom = zoom;
    _moveController.stop();
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final newZoom = (_startZoom * details.scale).clamp(0.4, 2.5);
    final rotDelta = details.focalPointDelta.dx * 0.002;

    setState(() {
      zoom = newZoom;
      dragRotation += rotDelta;
      cameraOffset += (details.focalPoint - _previousFocalPoint);
      _previousFocalPoint = details.focalPoint;
    });
  }

  void _increaseSunLevel() {
    setState(() {
      sunLevel = (sunLevel < 5) ? sunLevel + 1 : 1;
    });
    _preloadService.clearCache();
    _preloadService.preloadAll(planets, sunLevel);
  }

  Color _sunColor() {
    switch (sunLevel) {
      case 1:
        return Colors.yellowAccent;
      case 2:
        return Colors.orangeAccent;
      case 3:
        return Colors.redAccent;
      case 4:
        return Colors.purpleAccent;
      case 5:
        return Colors.lightBlueAccent;
      default:
        return Colors.yellowAccent;
    }
  }

  double _sunRadius() {
    switch (sunLevel) {
      case 1:
        return 40;
      case 2:
        return 50;
      case 3:
        return 60;
      case 4:
        return 70;
      case 5:
        return 80;
      default:
        return 40;
    }
  }

  Widget _buildSolarSystemContent(
      BuildContext context, SolarSystemProvider provider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final sunCenter = Offset(
      screenWidth / 2 + cameraOffset.dx,
      screenHeight / 2 + cameraOffset.dy,
    );

    return Stack(
      children: [
        StarfieldWidget(rotation: dragRotation, zoom: zoom),
        CustomPaint(
          size: Size(screenWidth, screenHeight),
          painter: _OrbitPainter(
            planets: planets,
            zoom: zoom,
            cameraOffset: cameraOffset,
            orbitRadiusFor: _orbitRadiusFor,
          ),
        ),
        // Sun
        Positioned(
          left: sunCenter.dx - _sunRadius() * zoom,
          top: sunCenter.dy - _sunRadius() * zoom,
          child: Container(
            width: _sunRadius() * 2 * zoom,
            height: _sunRadius() * 2 * zoom,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [_sunColor(), _sunColor().withOpacity(0.85)],
              ),
            ),
          ),
        ),
        // Planets
        ...planets.where((p) => p.name != "Sun").map((p) {
          final orbitRadius = _orbitRadiusFor(p, zoom);
          final angle = _planetAngle(p);
          final centerX = sunCenter.dx + cos(angle) * orbitRadius;
          final centerY = sunCenter.dy + sin(angle) * orbitRadius;

          return Positioned(
            left: centerX - p.radius * zoom,
            top: centerY - p.radius * zoom,
            child: PlanetWidget(
              planet: p,
              rotation: angle,
              zoom: zoom,
              onTap: () => _animateCenterOnPlanet(p, targetZoom: 1.2),
            ),
          );
        }),
        CometWidget(zoom: zoom),
        // Solar Flare
        if (provider.flareActive)
          SolarFlareWidget(
            zoom: zoom,
            planets: planets,
            cameraOffset: cameraOffset,
            sunRadius: _sunRadius(),
          ),
        // Planet details
        if (provider.selectedPlanet != null)
          PlanetDetailsPanel(
            planet: provider.selectedPlanet!,
            summary: _preloadService
                    .getSummary(provider.selectedPlanet!.name) ??
                "Loading summary...",
            onClose: () => provider.selectPlanet(null),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SolarSystemProvider>.value(
      value: _solarProvider,
      child: Consumer<SolarSystemProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onScaleStart: _handleScaleStart,
                    onScaleUpdate: _handleScaleUpdate,
                    child: AnimatedBuilder(
                      animation: _orbitController,
                      builder: (_, __) =>
                          _buildSolarSystemContent(context, provider),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: NavBar(
                      onPlanetSelected: (Planet p) =>
                          _animateCenterOnPlanet(p, targetZoom: 1.2),
                      onCenterView: () => _animateCenterOnSun(targetZoom: 1.0),
                    ),
                  ),
                  Positioned(
                    right: 20,
                    bottom: 20,
                    child: ElevatedButton(
                      onPressed: _increaseSunLevel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _sunColor(),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Sun Stage $sunLevel'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

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
    final center = Offset(size.width / 2 + cameraOffset.dx,
        size.height / 2 + cameraOffset.dy);
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
      oldDelegate.planets != planets ||
      oldDelegate.zoom != zoom ||
      oldDelegate.cameraOffset != cameraOffset;
}
