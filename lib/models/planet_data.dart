import 'package:flutter/material.dart';

class Planet {
  final String name;
  final double radius; // visual radius in pixels
  final double distanceFromSun; // in million km
  final int positionFromSun; // Mercury = 1, Venus = 2, ...
  final String description;
  final String flareEffectDescription;
  final bool hasMagneticField;
  final Color color;

  // 🌍 New fields for AI integration
  String? aiSummary; // preloaded Gemini short summary about living conditions
  bool isLoadingSummary; // to track when data is being fetched

  Planet({
    required this.name,
    required this.radius,
    required this.distanceFromSun,
    required this.positionFromSun,
    required this.description,
    required this.flareEffectDescription,
    required this.hasMagneticField,
    required this.color,
    this.aiSummary,
    this.isLoadingSummary = false,
  });
}

// 🌞 Planets list
final List<Planet> planets = [
  Planet(
    name: "Sun",
    radius: 40,
    distanceFromSun: 0,
    positionFromSun: 0,
    description: "The star at the center of the Solar System",
    flareEffectDescription: "Generates solar flares affecting planets",
    hasMagneticField: false,
    color: Colors.yellowAccent,
  ),
  Planet(
    name: "Mercury",
    radius: 4,
    distanceFromSun: 57.9,
    positionFromSun: 1,
    description: "Closest planet to the Sun",
    flareEffectDescription: "Minimal effect",
    hasMagneticField: false,
    color: Colors.grey,
  ),
  Planet(
    name: "Venus",
    radius: 6,
    distanceFromSun: 108.2,
    positionFromSun: 2,
    description: "Second planet from the Sun",
    flareEffectDescription: "Slight heating effect",
    hasMagneticField: false,
    color: Colors.orangeAccent,
  ),
  Planet(
    name: "Earth",
    radius: 6.5,
    distanceFromSun: 149.6,
    positionFromSun: 3,
    description: "Our home planet",
    flareEffectDescription: "Moderate effect on atmosphere",
    hasMagneticField: true,
    color: Colors.blue,
  ),
  Planet(
    name: "Mars",
    radius: 5,
    distanceFromSun: 227.9,
    positionFromSun: 4,
    description: "The Red Planet",
    flareEffectDescription: "Can affect magnetic field",
    hasMagneticField: true,
    color: Colors.red,
  ),
  Planet(
    name: "Jupiter",
    radius: 12,
    distanceFromSun: 778.5,
    positionFromSun: 5,
    description: "Largest planet in the Solar System",
    flareEffectDescription: "Minimal effect due to distance",
    hasMagneticField: true,
    color: Colors.brown,
  ),
  Planet(
    name: "Saturn",
    radius: 10,
    distanceFromSun: 1434,
    positionFromSun: 6,
    description: "Famous for its rings",
    flareEffectDescription: "Minimal effect due to distance",
    hasMagneticField: true,
    color: Colors.yellow,
  ),
  Planet(
    name: "Uranus",
    radius: 8,
    distanceFromSun: 2871,
    positionFromSun: 7,
    description: "Ice giant",
    flareEffectDescription: "Minimal effect due to distance",
    hasMagneticField: true,
    color: Colors.lightBlueAccent,
  ),
  Planet(
    name: "Neptune",
    radius: 8,
    distanceFromSun: 4495,
    positionFromSun: 8,
    description: "Farthest planet from the Sun",
    flareEffectDescription: "Minimal effect due to distance",
    hasMagneticField: true,
    color: Colors.blueAccent,
  ),
];
