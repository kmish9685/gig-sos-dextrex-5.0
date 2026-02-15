import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dextrix 5.0')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Status: Online & Monitoring'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Manual SOS Trigger
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('MANUAL SOS'),
            ),
             const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Navigate to Map
              },
              child: const Text('View Nearby Riders'),
            ),
          ],
        ),
      ),
    );
  }
}
