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
              // 1. Identity Config
              const Text("MY IDENTITY", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(service.userName),
                  subtitle: const Text("Tap to edit name"),
                  trailing: const Icon(Icons.edit),
                  onTap: () {
                    _showNameEditDialog(context, service);
                  },
                ),
              ),
              const Divider(thickness: 2),

              // 2. Network Events
              const Text("INJECT NETWORK EVENTS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),
              
              const Text("Discovery Injection:", style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 10,
                children: [
                   ActionChip(
                    avatar: const Icon(Icons.wifi_tethering),
                    label: const Text("+ Amit"),
                    onPressed: () => service.injectDiscoveredRider("Rider Amit"),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.wifi_tethering),
                    label: const Text("+ Rahul"),
                    onPressed: () => service.injectDiscoveredRider("Rider Rahul"),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              const Text("Emergency Injection (Incoming):", style: TextStyle(fontWeight: FontWeight.bold)),
              ListTile(
                    tileColor: Colors.red.withOpacity(0.1),
                    leading: const Icon(Icons.warning, color: Colors.red),
                    title: const Text('Simulate SOS from "Rider Amit"'),
                    subtitle: const Text('Triggers Incoming Alert Screen'),
                    onTap: () {
                       service.triggerIncomingAlert("Rider Amit", "150m");
                       Navigator.pop(context); // Close panel to see alert
                    },
              ),

              const Divider(thickness: 2),

              // 3. Force Local State
              const Text("FORCE LOCAL HARDWARE:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
               ListTile(
                    leading: const Icon(Icons.vibration, color: Colors.orange),
                    title: const Text('Force Hardware Crash'),
                    subtitle: const Text('Simulates 5G Accel Spike (My Crash)'),
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
                    Text("My Status: ${service.emergencyActive ? 'CRASHED' : 'SAFE'}"),
                    Text("Broadcasting: ${service.isBroadcasting}"),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showNameEditDialog(BuildContext context, DemoEmergencyService service) {
    final controller = TextEditingController(text: service.userName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit My Name"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () {
              service.userName = controller.text;
              // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
              service.notifyListeners(); 
              Navigator.pop(ctx);
            }, 
            child: const Text("SAVE")
          )
        ],
      )
    );
  }
}

