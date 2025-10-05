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
import '../backend/level_brain.dart';
import '../components/level_overlay.dart';

/// Provider controlling planet selection & flare state
class SolarSystemProvider extends ChangeNotifier {
  Planet? selectedPlanet;
  bool flareActive = false;

  void selectPlanet(Planet? planet) {
    selectedPlanet = planet;
    notifyListeners();
  }

  void triggerFlare() {
    flareActive = true;
    notifyListeners();
    Future.delayed(const Duration(seconds: 3), () {
      flareActive = false;
      notifyListeners();
    });
  }
}

/// Main view wrapper, properly provides LevelBrain & SolarSystemProvider
class SolarSystemView extends StatelessWidget {
  const SolarSystemView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LevelBrain()),
        ChangeNotifierProvider(create: (_) => SolarSystemProvider()),
      ],
      child: const _SolarSystemViewBody(),
    );
  }
}

/// Actual SolarSystemView body, stateful
class _SolarSystemViewBody extends StatefulWidget {
  const _SolarSystemViewBody();

  @override
  State<_SolarSystemViewBody> createState() => _SolarSystemViewBodyState();
}

class _SolarSystemViewBodyState extends State<_SolarSystemViewBody>
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

  late PreloadService _preloadService;
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
    _preloadService = PreloadService();
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

    // Preload planet data for level 1
    _preloadService.preloadAll(planets, sunLevel);

    // Automatic flare timer will be triggered in post-frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final solarProvider =
          Provider.of<SolarSystemProvider>(context, listen: false);
      final levelBrain = Provider.of<LevelBrain>(context, listen: false);

      Timer.periodic(const Duration(seconds: 30), (_) {
        if (levelBrain.currentLevel >= 3) {
          solarProvider.triggerFlare();
        }
      });
    });
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _moveController.dispose();
    super.dispose();
  }

  double _planetAngle(Planet planet) {
    final baseSpeed = _orbitalSpeeds[planet.name] ?? 1.0;
    final offset = _planetAngleOffsets[planet.name] ?? 0.0;
    return (_orbitController.value * 2 * pi * baseSpeed) + dragRotation + offset;
  }

  double _orbitRadiusFor(Planet planet, double zoom) {
    const double scale = 4.0;
    double baseOffset;
    switch (planet.positionFromSun) {
      case 1:
        baseOffset = 140;
        break;
      case 2:
        baseOffset = 240;
        break;
      case 3:
        baseOffset = 340;
        break;
      case 4:
        baseOffset = 500;
        break;
      case 5:
        baseOffset = 850;
        break;
      case 6:
        baseOffset = 1350;
        break;
      case 7:
        baseOffset = 1850;
        break;
      case 8:
        baseOffset = 2500;
        break;
      default:
        baseOffset = planet.positionFromSun * 100.0;
    }
    return (planet.distanceFromSun * scale * 0.001 + baseOffset) * zoom;
  }

  void _animateCenterOnPlanet(Planet planet, {double targetZoom = 1.2}) {
    _moveController.stop();
    final radius = _orbitRadiusFor(planet, targetZoom);
    final angle = _planetAngle(planet);
    final pos = Offset(cos(angle) * radius, sin(angle) * radius);

    _cameraAnim =
        Tween<Offset>(begin: cameraOffset, end: -pos).animate(CurvedAnimation(
      parent: _moveController,
      curve: Curves.easeOutCubic,
    ));
    _zoomAnim =
        Tween<double>(begin: zoom, end: targetZoom).animate(CurvedAnimation(
      parent: _moveController,
      curve: Curves.easeOutCubic,
    ));

    _moveController.forward(from: 0.0);

    Provider.of<SolarSystemProvider>(context, listen: false)
        .selectPlanet(planet);
  }

  void _animateCenterOnSun({double targetZoom = 1.0}) {
    _moveController.stop();
    _cameraAnim =
        Tween<Offset>(begin: cameraOffset, end: Offset.zero).animate(
            CurvedAnimation(parent: _moveController, curve: Curves.easeOutCubic));
    _zoomAnim =
        Tween<double>(begin: zoom, end: targetZoom).animate(CurvedAnimation(
      parent: _moveController,
      curve: Curves.easeOutCubic,
    ));
    _moveController.forward(from: 0.0);

    Provider.of<SolarSystemProvider>(context, listen: false).selectPlanet(null);
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

    Provider.of<LevelBrain>(context, listen: false).increaseLevel();
  }

  Color _sunColor() {
    switch (sunLevel) {
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

  double _sunRadius() => 30 + sunLevel * 10;

  @override
  Widget build(BuildContext context) {
    final solarProvider = Provider.of<SolarSystemProvider>(context);
    final levelBrain = Provider.of<LevelBrain>(context);

    final size = MediaQuery.of(context).size;
    final sunCenter = Offset(size.width / 2 + cameraOffset.dx,
        size.height / 2 + cameraOffset.dy);

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
                builder: (_, __) {
                  return Stack(
                    children: [
                      StarfieldWidget(rotation: dragRotation, zoom: zoom),
                      CustomPaint(
                        size: size,
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
                      ...planets.where((p) => p.name != "Sun").map((planet) {
                        final orbit = _orbitRadiusFor(planet, zoom);
                        final angle = _planetAngle(planet);
                        final pos = Offset(
                          sunCenter.dx + cos(angle) * orbit,
                          sunCenter.dy + sin(angle) * orbit,
                        );
                        return Positioned(
                          left: pos.dx - planet.radius * zoom,
                          top: pos.dy - planet.radius * zoom,
                          child: PlanetWidget(
                            planet: planet,
                            rotation: angle,
                            zoom: zoom,
                            onTap: () =>
                                _animateCenterOnPlanet(planet, targetZoom: 1.2),
                          ),
                        );
                      }),
                      CometWidget(zoom: zoom),
                      if (solarProvider.flareActive)
                        SolarFlareWidget(
                          zoom: zoom,
                          planets: planets,
                          cameraOffset: cameraOffset,
                          sunRadius: _sunRadius(),
                        ),
                      if (solarProvider.selectedPlanet != null)
                        PlanetDetailsPanel(
                          planet: solarProvider.selectedPlanet!,
                          summary: _preloadService
                                  .getSummary(solarProvider.selectedPlanet!.name) ??
                              "Loading summary...",
                          onClose: () => solarProvider.selectPlanet(null),
                        ),
                    ],
                  );
                },
              ),
            ),
            // NavBar
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: NavBar(
                onPlanetSelected: (p) => _animateCenterOnPlanet(p, targetZoom: 1.2),
                onCenterView: () => _animateCenterOnSun(targetZoom: 1.0),
              ),
            ),
            // Sun stage + manual flare button
            Positioned(
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _increaseSunLevel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _sunColor(),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Sun Stage $sunLevel'),
                  ),
                  const SizedBox(height: 8),
                  if (levelBrain.currentLevel <= 2)
                    ElevatedButton(
                      onPressed: () => solarProvider.triggerFlare(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Trigger Flare'),
                    ),
                ],
              ),
            ),
            // Level overlay
            Positioned(
              left: 20,
              bottom: 20,
              child: LevelOverlay(level: levelBrain.currentLevel),
            ),
          ],
        ),
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

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withOpacity(0.12);

    for (final planet in planets.where((p) => p.name != "Sun")) {
      final r = orbitRadiusFor(planet, zoom);
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter oldDelegate) =>
      oldDelegate.planets != planets ||
      oldDelegate.zoom != zoom ||
      oldDelegate.cameraOffset != cameraOffset;
}
