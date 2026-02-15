import 'package:flutter/material.dart';
import '../../features/demo/demo_emergency_service.dart';

class DemoScreen extends StatelessWidget {
  const DemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Judge Control Panel')),
      body: AnimatedBuilder(
        animation: DemoEmergencyService.instance,
        builder: (context, _) {
          final service = DemoEmergencyService.instance;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text("INJECT REAL-WORLD EVENTS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),
              
              const Text("Discovery Injection:", style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 10,
                children: [
                  ActionChip(
                    label: const Text("+ Rider Amit"),
                    onPressed: () => service.injectDiscoveredRider("Rider Amit"),
                  ),
                  ActionChip(
                    label: const Text("+ Rider Sarah"),
                    onPressed: () => service.injectDiscoveredRider("Rider Sarah"),
                  ),
                  ActionChip(
                    label: const Text("+ Rider Rahul"),
                    onPressed: () => service.injectDiscoveredRider("Rider Rahul"),
                  ),
                ],
              ),
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text("Use these to simulate a peer entering range.", style: TextStyle(fontSize: 12, color: Colors.grey))
              ),

              const Divider(thickness: 2),

              const Text("Force States:", style: TextStyle(fontWeight: FontWeight.bold)),
               ListTile(
                    leading: const Icon(Icons.vibration, color: Colors.orange),
                    title: const Text('Force Hardware Crash'),
                    subtitle: const Text('Simulates 5G Accel Spike'),
                    onTap: () {
                       service.simulateCrash();
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Crash Triggered!')),
                       );
                    },
                  ),
                  
              const Divider(thickness: 2),

              const Text("System State (Read-Only):", style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                color: Colors.black12,
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Mesh Active: ${service.meshActive}"),
                    Text("Scanning: ${service.scanning}"),
                    Text("Emergency: ${service.emergencyActive}"),
                    Text("Riders: ${service.nearbyRiders.length}"),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
