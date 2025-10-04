// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/planet_data.dart';
import '../screens/solar_system_view.dart';

class NavBar extends StatefulWidget {
  final Function(Planet) onPlanetSelected;
  final VoidCallback onCenterView;

  const NavBar({
    super.key,
    required this.onPlanetSelected,
    required this.onCenterView,
  });

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  Planet? selectedPlanet;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 🌍 Dropdown list of planets
          DropdownButton<Planet>(
            dropdownColor: Colors.black87,
            value: selectedPlanet,
            hint: const Text(
              "Select Planet",
              style: TextStyle(color: Colors.white),
            ),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            items: planets
                .where((p) => p.name != "Sun")
                .map((planet) => DropdownMenuItem(
                      value: planet,
                      child: Text(
                        planet.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ))
                .toList(),
            onChanged: (Planet? planet) {
              if (planet != null) {
                setState(() => selectedPlanet = planet);
                widget.onPlanetSelected(planet);
              }
            },
          ),

          // ☀️ Back to Sun button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.my_location, color: Colors.black),
            label: const Text(
              "Center Sun",
              style: TextStyle(color: Colors.black),
            ),
            onPressed: widget.onCenterView,
          ),
        ],
      ),
    );
  }
}
