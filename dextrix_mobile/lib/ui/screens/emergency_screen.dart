import 'package:flutter/material.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.redAccent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('CRASH DETECTED!', style: TextStyle(fontSize: 30, color: Colors.white)),
            const SizedBox(height: 20),
            const Text('Sending SOS in:', style: TextStyle(color: Colors.white)),
            const Text('5', style: TextStyle(fontSize: 80, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // TODO: Cancel SOS
              },
              child: const Text('I AM OKAY (CANCEL)'),
            ),
          ],
        ),
      ),
    );
  }
}
