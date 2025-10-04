import 'package:flutter/material.dart';

class Planet {
  final String name;
  final int positionFromSun;
  final double radius;
  final double distanceFromSun; // in millions of km
  final String yearLength;
  final String description;
  final String flareEffectDescription;
  final bool hasMagneticField;
  final Color color;

  Planet({
    required this.name,
    required this.positionFromSun,
    required this.radius,
    required this.distanceFromSun,
    required this.yearLength,
    required this.description,
    required this.flareEffectDescription,
    required this.hasMagneticField,
    required this.color,
  });
}

final List<Planet> planets = [
  Planet(
    name: "Sun",
    positionFromSun: 0,
    radius: 38,
    distanceFromSun: 0,
    yearLength: "—",
    description: "The center of our Solar System, a G-type main-sequence star.",
    flareEffectDescription: "Produces intense bursts of solar radiation.",
    hasMagneticField: true,
    color: Colors.orangeAccent,
  ),
  Planet(
    name: "Mercury",
    positionFromSun: 1,
    radius: 8.0,
    distanceFromSun: 57.9,
    yearLength: "88 Earth days",
    description: "Closest planet to the Sun and smallest in the Solar System.",
    flareEffectDescription: "Heavily affected by solar radiation.",
    hasMagneticField: true,
    color: Colors.grey,
  ),
  Planet(
    name: "Venus",
    positionFromSun: 2,
    radius: 12.0, // smaller than Earth
    distanceFromSun: 108.2,
    yearLength: "225 Earth days",
    description: "Venus is bright and hot with a thick, toxic atmosphere.",
    flareEffectDescription: "Solar flares heat its clouds intensely.",
    hasMagneticField: false,
    color: Colors.yellowAccent,
  ),
  Planet(
    name: "Earth",
    positionFromSun: 3,
    radius: 14.0, // slightly bigger than Venus
    distanceFromSun: 149.6,
    yearLength: "365 Earth days",
    description: "Our home planet, full of water and life.",
    flareEffectDescription: "Auroras appear during solar storms.",
    hasMagneticField: true,
    color: Colors.blueAccent,
  ),
  Planet(
    name: "Mars",
    positionFromSun: 4,
    radius: 10.0,
    distanceFromSun: 227.9,
    yearLength: "687 Earth days",
    description: "The red planet with a thin atmosphere.",
    flareEffectDescription: "Solar wind strips away its thin atmosphere.",
    hasMagneticField: false,
    color: Colors.redAccent,
  ),
  Planet(
    name: "Jupiter",
    positionFromSun: 5,
    radius: 25.0,
    distanceFromSun: 778.5,
    yearLength: "12 Earth years",
    description: "The gas giant with a Great Red Spot storm.",
    flareEffectDescription: "Absorbs solar energy in its massive atmosphere.",
    hasMagneticField: true,
    color: Colors.orange,
  ),
  Planet(
    name: "Saturn",
    positionFromSun: 6,
    radius: 22.0,
    distanceFromSun: 1434.0,
    yearLength: "29 Earth years",
    description: "Famous for its beautiful ring system.",
    flareEffectDescription: "Rings shimmer in sunlight.",
    hasMagneticField: true,
    color: Colors.amberAccent,
  ),
  Planet(
    name: "Uranus",
    positionFromSun: 7,
    radius: 18.0,
    distanceFromSun: 2871.0,
    yearLength: "84 Earth years",
    description: "Icy blue-green planet with a tilted axis.",
    flareEffectDescription: "Solar storms interact with its methane atmosphere.",
    hasMagneticField: true,
    color: Colors.cyanAccent,
  ),
  Planet(
    name: "Neptune",
    positionFromSun: 8,
    radius: 17.0,
    distanceFromSun: 4495.0,
    yearLength: "165 Earth years",
    description: "The farthest planet, cold and windy.",
    flareEffectDescription: "Barely touched by the Sun’s rays.",
    hasMagneticField: true,
    color: Colors.blue,
  ),
];
