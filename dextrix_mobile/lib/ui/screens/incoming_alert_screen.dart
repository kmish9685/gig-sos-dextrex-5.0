import 'package:flutter/material.dart';
import '../../features/demo/demo_emergency_service.dart';

class IncomingAlertScreen extends StatelessWidget {
  const IncomingAlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alert = DemoEmergencyService.instance.currentIncomingAlert;
    if (alert == null) {
      // Safety check: if clear, go back
      Future.microtask(() => Navigator.pop(context));
      return const SizedBox();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Flashing Red Background Animation could go here
          Container(color: Colors.red.withOpacity(0.2)),
          
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.red),
                const SizedBox(height: 20),
                const Text(
                  "SOS RECEIVED",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2
                  ),
                ),
                const SizedBox(height: 40),
                
                // Victim Card
                Card(
                  color: Colors.grey[900],
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(
                          alert['victim'] ?? "Unknown Rider",
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              "${alert['distance']} away",
                              style: const TextStyle(fontSize: 18, color: Colors.blueAccent),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text("Accident detected via Mesh", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Actions
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                    onPressed: () {
                      // Mock Navigation
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Google Maps Navigation Started..."))
                      );
                    }, 
                    icon: const Icon(Icons.navigation, color: Colors.white),
                    label: const Text("NAVIGATE TO VICTIM", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    DemoEmergencyService.instance.clearIncomingAlert();
                    Navigator.pop(context);
                  },
                  child: const Text("Dismiss Alert", style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
