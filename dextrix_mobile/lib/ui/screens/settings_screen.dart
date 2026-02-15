
import 'package:flutter/material.dart';
import '../../features/demo/demo_emergency_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = DemoEmergencyService.instance;
    
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("User Identity"),
            subtitle: Text(service.userName),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text("App Version"),
            subtitle: const Text("Dextrix 5.0 (P2P Mesh - Alpha)"),
          ),
          ListTile(
            leading: const Icon(Icons.perm_device_information),
            title: const Text("Mesh Strategy"),
            subtitle: const Text("P2P_CLUSTER (Google Nearby)"),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text("Clear Logs"),
            onTap: () {
               service.packetLog.clear();
               // service.notifyListeners(); // Method not exposed, but logPacket calls it
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Logs Cleared")));
            },
          ),
        ],
      ),
    );
  }
}
