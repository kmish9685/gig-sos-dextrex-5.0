import 'dart:async';
import 'package:flutter/material.dart';
import '../../features/demo/demo_emergency_service.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  int _countdown = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _timer?.cancel();
          // Trigger Broadcast
          DemoEmergencyService.instance.broadcastSOS();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: DemoEmergencyService.instance,
      builder: (context, _) {
        final service = DemoEmergencyService.instance;
        
        // State 1: Broadcasting (Countdown Finished)
        if (service.isBroadcasting) {
          return Scaffold(
            backgroundColor: Colors.red[900], // Darker red for active state
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_tethering, size: 100, color: Colors.white),
                  const SizedBox(height: 20),
                  const Text(
                    "BROADCASTING SOS...",
                    style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Sending location to nearby riders",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 60),
                  ElevatedButton(
                    onPressed: () {
                       service.cancelEmergency();
                       Navigator.pop(context); 
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                    child: const Text('I AM SAFE (RESOLVE)'),
                  ),
                ],
              ),
            ),
          );
        }

        // State 2: Countdown (Pre-Alert)
        return Scaffold(
          backgroundColor: Colors.redAccent,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('CRASH DETECTED!', style: TextStyle(fontSize: 30, color: Colors.white)),
                const SizedBox(height: 20),
                const Text('Sending SOS in:', style: TextStyle(color: Colors.white)),
                
                // Big Countdown Number
                Text(
                  '$_countdown',
                  style: const TextStyle(fontSize: 100, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  ),
                  onPressed: () {
                     service.cancelEmergency();
                     Navigator.pop(context); // Go back home
                  },
                  child: const Text('I AM OKAY (CANCEL)', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        );
     }
    );
  }
}

