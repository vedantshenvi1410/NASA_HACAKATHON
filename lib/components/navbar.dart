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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<Planet>(
              dropdownColor: Colors.black87,
              value: null,
              hint: const Text(
                "Select Planet",
                style: TextStyle(color: Colors.white),
              ),
              iconEnabledColor: Colors.white,
              items: planets
                  .where((p) => p.name != "Sun")
                  .map((planet) => DropdownMenuItem<Planet>(
                        value: planet,
                        child: Text(
                          planet.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ))
                  .toList(),
              onChanged: (planet) {
                if (planet != null) onPlanetSelected(planet);
              },
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onCenterView,
            child: const Text("Center"),
          )
        ],
      ),
    );
  }
}
