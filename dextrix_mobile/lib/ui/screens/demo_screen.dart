import 'package:flutter/material.dart';
import '../../features/demo/demo_emergency_service.dart';

class DemoScreen extends StatelessWidget {
  const DemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Validation Dashboard')),
      body: AnimatedBuilder(
        animation: DemoEmergencyService.instance,
        builder: (context, _) {
          final service = DemoEmergencyService.instance;

          return ListView(
            children: [
              // 1. Controls Section
              ExpansionTile(
                title: const Text("Controls", style: TextStyle(fontWeight: FontWeight.bold)),
                initiallyExpanded: true,
                children: [
                   ListTile(
                    leading: Icon(Icons.wifi_tethering, color: service.meshActive ? Colors.green : Colors.grey),
                    title: const Text('1. Toggle Mesh'),
                    subtitle: Text(service.meshActive ? 'Active (Scanning)' : 'Inactive'),
                    trailing: Switch(
                      value: service.meshActive, 
                      onChanged: (val) {
                        if (val) service.startMesh();
                        else service.stopMesh();
                      }
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.vibration, color: Colors.orange),
                    title: const Text('2. Trigger Crash'),
                    subtitle: const Text('Simulates 5G Impact'),
                    onTap: () {
                       service.simulateCrash();
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Crash Triggered! Check Home overlay.')),
                       );
                    },
                  ),
                ],
              ),
              
              const Divider(thickness: 2),
              
              // 2. Peers Section
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Connected Peers (Simulated)", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              if (service.nearbyRiders.isEmpty)
                 const Padding(
                   padding: EdgeInsets.all(16.0),
                   child: Text("No peers connected.\n(Start Mesh to simulate discovery)", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                 )
              else
                ...service.nearbyRiders.map((peer) => Card(
                  color: Colors.green.withOpacity(0.1),
                  child: ListTile(
                    leading: const Icon(Icons.phone_android),
                    title: Text(peer),
                    trailing: const Icon(Icons.check_circle, color: Colors.green),
                  ),
                )).toList(),
              
              const Divider(thickness: 2),

              // 3. State Debug
               Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("State Internals:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("Mesh Active: ${service.meshActive}"),
                    Text("Emergency Active: ${service.emergencyActive}"),
                    Text("Riders Count: ${service.nearbyRiders.length}"),
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
