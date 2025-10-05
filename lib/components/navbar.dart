import 'package:flutter/material.dart';
import '../models/planet_data.dart';

class NavBar extends StatelessWidget {
  final Function(Planet) onPlanetSelected;
  final VoidCallback onCenterView;

  const NavBar({
    super.key,
    required this.onPlanetSelected,
    required this.onCenterView,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hamburger menu for planet selection
          PopupMenuButton<Planet>(
            icon: const Icon(Icons.menu, color: Colors.white, size: 28),
            color: Colors.black87,
            onSelected: (planet) => onPlanetSelected(planet),
            itemBuilder: (context) {
              return planets
                  .where((p) => p.name != "Sun")
                  .map(
                    (planet) => PopupMenuItem<Planet>(
                      value: planet,
                      child: Text(
                        planet.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList();
            },
          ),

          const SizedBox(height: 12),

          // Circular center button
          Material(
            color: Colors.orangeAccent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onCenterView,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.center_focus_strong, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
