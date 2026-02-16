import 'package:flutter/material.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/settings_screen.dart';

void main() {
  runApp(const DextrixApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class DextrixApp extends StatelessWidget {
  const DextrixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Dextrix 5.0',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF1E1E1E), // Dark theme
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepOrange,
          secondary: Colors.amber,
        ),
      ),
      home: const HomeScreen(),
      routes: {
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
