import 'package:flutter/material.dart';
import 'screens/solar_system_view.dart';

void main() {
  runApp(const ProjectHeliosApp());
}

class ProjectHeliosApp extends StatelessWidget {
  const ProjectHeliosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Project Helios',
      theme: ThemeData.dark(useMaterial3: true),
      home: const SolarSystemView(),
    );
  }
}
