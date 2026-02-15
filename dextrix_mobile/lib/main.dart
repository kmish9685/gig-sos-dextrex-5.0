import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/sensor/sensor_module.dart';
import 'features/sensor/sensor_service.dart';
import 'features/mesh/mesh_module.dart';
import 'features/mesh/mesh_service.dart';
import 'features/emergency/emergency_module.dart';
import 'features/emergency/emergency_service.dart';
import 'features/map/map_module.dart';
import 'features/map/map_service.dart';
import 'features/demo/demo_module.dart';
import 'features/demo/demo_controller.dart';

import 'ui/screens/home_screen.dart';

void main() {
  runApp(const DextrixApp());
}

class DextrixApp extends StatelessWidget {
  const DextrixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. Core Hardware/Network Services
        Provider<SensorModule>(
          create: (_) => SensorService(),
          dispose: (_, service) => service.stopMonitoring(),
        ),
        Provider<MeshModule>(
          create: (_) => MeshService(), // Uses MockMeshProvider by default
          dispose: (_, service) => service.stopDiscovery(),
        ),
        Provider<MapModule>(
          create: (_) => MapService(),
          dispose: (_, service) => service.stopTracking(),
        ),

        // 2. Logic/State Services (Depend on Core)
        ProxyProvider2<SensorModule, MeshModule, EmergencyModule>(
          update: (_, sensor, mesh, __) => EmergencyService(
            sensorModule: sensor,
            meshModule: mesh,
          ),
        ),

        // 3. Demo Controller (Depends on Logic)
        ProxyProvider2<EmergencyModule, MeshModule, DemoModule>(
          update: (_, emergency, mesh, __) => DemoController(
            emergencyModule: emergency,
            meshService: mesh as MeshService,
          ),
        ),
      ],
      child: MaterialApp(
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
      ),
    );
  }
}
