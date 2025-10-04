import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/solar_system_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // Load API key

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
