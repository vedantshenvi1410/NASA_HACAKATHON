import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

import '../models/planet_data.dart';
import '../widgets/planet_widget.dart';
import '../widgets/solar_flare_widget.dart';
import '../widgets/starfield_widget.dart';
import '../widgets/comet_widget.dart';
import '../components/navbar.dart';
import '../preload.dart';
import '../backend/level_brain.dart';
import '../components/level_overlay.dart';
import '../widgets/earth_magnetic_visual.dart';

/// PROVIDER
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

/// MAIN VIEW
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

/// STATEFUL BODY
class _SolarSystemViewBody extends StatefulWidget {
  const _SolarSystemViewBody();

  @override
  State<_SolarSystemViewBody> createState() => _SolarSystemViewBodyState();
}

class _SolarSystemViewBodyState extends State<_SolarSystemViewBody>
    with SingleTickerProviderStateMixin {
  double zoom = 1.0;
  double dragRotation = 0.0;
  bool isShaking = false;

  late AudioPlayer audioPlayer;
  late AnimationController _controller;
  late PreloadService _preloadService;
  int sunLevel = 1;

  late Map<int, double> orbitOffsets;
  late Map<int, double> orbitSpeeds;

  Timer? _flareTimer;

  @override
  void initState() {
    super.initState();

    _preloadService = PreloadService();

    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 60))
          ..repeat();
    audioPlayer = AudioPlayer();

    final random = Random();
    orbitOffsets = {for (var p in planets) p.positionFromSun: random.nextDouble() * 2 * pi};
    orbitSpeeds = {for (var p in planets) p.positionFromSun: 0.6 / (p.positionFromSun + 0.8)};

    _preloadService.preloadAll(planets, sunLevel);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final levelBrain = Provider.of<LevelBrain>(context, listen: false);
      final solarProvider = Provider.of<SolarSystemProvider>(context, listen: false);

      _flareTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (levelBrain.currentLevel >= 3) {
          _triggerAutoSolarFlare(solarProvider);
        }
      });
    });
  }

  @override
  void dispose() {
    _flareTimer?.cancel();
    _controller.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  double rotationAngle(Planet planet) {
    final speed = orbitSpeeds[planet.positionFromSun] ?? 0.2;
    final offset = orbitOffsets[planet.positionFromSun] ?? 0.0;
    final time = _controller.lastElapsedDuration?.inMilliseconds ?? 0;
    return (time * 0.0005 * speed) + dragRotation + offset;
  }

  Offset planetOffset(Planet p, Offset center, double angle, double baseOrbit) {
    final orbitR = (baseOrbit + 60.0 * p.positionFromSun) * zoom;
    double shakeX = 0, shakeY = 0;
    if (isShaking) {
      final rand = Random();
      shakeX = (rand.nextDouble() - 0.5) * 8;
      shakeY = (rand.nextDouble() - 0.5) * 8;
    }
    final x = center.dx + orbitR * cos(angle);
    final y = center.dy + orbitR * sin(angle) * 0.6;
    return Offset(x - p.radius, y - p.radius) + Offset(shakeX, shakeY);
  }

  Future<void> triggerSolarFlare(SolarSystemProvider provider) async {
    provider.triggerFlare();
    _playFlareEffects();
    setState(() => isShaking = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => isShaking = false);
    });
  }

  void _triggerAutoSolarFlare(SolarSystemProvider provider) {
    provider.triggerFlare();
    _playFlareEffects();
    setState(() => isShaking = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => isShaking = false);
    });
  }

  Future<void> _playFlareEffects() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 100, amplitude: 50);
      }
      unawaited(audioPlayer.play(AssetSource('sounds/flare.mp3')));
    } catch (_) {}
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

  @override
  Widget build(BuildContext context) {
    final solarProvider = Provider.of<SolarSystemProvider>(context);
    final levelBrain = Provider.of<LevelBrain>(context);
    final size = MediaQuery.of(context).size;
    final center = Offset(size.width / 2, size.height / 2);
    final baseOrbit = min(size.width, size.height) * 0.12;

    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onScaleUpdate: (details) {
          setState(() {
            zoom = (zoom * details.scale).clamp(0.5, 2.0);
            dragRotation += details.focalPointDelta.dx * 0.01;
          });
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            final Map<Planet, Offset> planetPositions = {};
            for (var p in planets) {
              if (p.positionFromSun == 0) continue;
              final angle = rotationAngle(p);
              planetPositions[p] = planetOffset(p, center, angle, baseOrbit);
            }

            return Stack(
              children: [
                StarfieldWidget(rotation: dragRotation, zoom: zoom),

                // Orbits
                Positioned.fill(
                  child: CustomPaint(
                    painter: OrbitPainter(
                      center: center,
                      baseOrbit: baseOrbit * zoom,
                      maxIndex: planets.map((p) => p.positionFromSun).fold<int>(0, max),
                      t: (_controller.lastElapsedDuration?.inMilliseconds ?? 0) / 60000.0,
                    ),
                  ),
                ),

                // Sun
                Center(
                  child: Container(
                    width: 80 + sunLevel * 10,
                    height: 80 + sunLevel * 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [_sunColor(), _sunColor().withOpacity(0.8)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _sunColor().withOpacity(0.18),
                          blurRadius: 30,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),

                // Planets
                for (var p in planets)
                  if (p.positionFromSun != 0)
                    Positioned(
                      left: planetPositions[p]!.dx,
                      top: planetPositions[p]!.dy,
                      child: PlanetWidget(
                        planet: p,
                        rotation: rotationAngle(p),
                        zoom: zoom,
                        onTap: () => solarProvider.selectPlanet(p),
                      ),
                    ),

                CometWidget(zoom: zoom),

                if (solarProvider.flareActive)
                  SolarFlareWidget(
                    zoom: zoom,
                    planets: planets,
                    sunRadius: 80 + sunLevel * 10,
                  ),

                if (levelBrain.currentLevel >= 2)
                  const EarthMagneticVisual(),

                // LEFT SIDE horizontal NavBar
                Positioned(
                  top: 20,
                  left: 20,
                  child: NavBar(
                    onPlanetSelected: (planet) => solarProvider.selectPlanet(planet),
                    onCenterView: () {},
                  ),
                ),

                // Right-bottom controls
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FloatingActionButton(
                        backgroundColor: Colors.orangeAccent,
                        onPressed: () => triggerSolarFlare(solarProvider),
                        child: const Icon(Icons.wb_sunny),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _increaseSunLevel,
                        style: ElevatedButton.styleFrom(backgroundColor: _sunColor()),
                        child: Text('Sun Stage $sunLevel'),
                      ),
                    ],
                  ),
                ),

                // Level Overlay
                Positioned(
                  left: 20,
                  bottom: 20,
                  child: LevelOverlay(level: levelBrain.currentLevel),
                ),

                // PLANET INFO PANEL
                if (solarProvider.selectedPlanet != null)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      height: 200,
                      width: MediaQuery.of(context).size.width * 0.9,
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                solarProvider.selectedPlanet!.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () => solarProvider.selectPlanet(null),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Text(
                                solarProvider.selectedPlanet!.description ??
                                    "No description available",
                                style: const TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// ORBIT PAINTER
class OrbitPainter extends CustomPainter {
  final Offset center;
  final double baseOrbit;
  final int maxIndex;
  final double t;

  OrbitPainter({
    required this.center,
    required this.baseOrbit,
    required this.maxIndex,
    required this.t,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 1; i <= maxIndex; i++) {
      final r = baseOrbit + 60.0 * i;
      final rect = Rect.fromCenter(center: center, width: r * 2, height: r * 2 * 0.6);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: 2 * pi,
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05)
          ],
          stops: [(t + 0.0) % 1, (t + 0.1) % 1, (t + 2.0) % 1],
          transform: GradientRotation(2 * pi * t),
        ).createShader(rect);
      canvas.drawOval(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
