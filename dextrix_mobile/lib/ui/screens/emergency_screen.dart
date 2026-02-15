import 'dart:async';
import 'package:flutter/material.dart';
import '../../features/demo/demo_emergency_service.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> with SingleTickerProviderStateMixin {
  int _countdown = 3;
  Timer? _timer;
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _startTimer();
    
    // Ripple Animation Setup
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
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
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([DemoEmergencyService.instance, _rippleController]),
      builder: (context, _) {
        final service = DemoEmergencyService.instance;
        
        // State 1: Broadcasting (Countdown Finished)
        if (service.isBroadcasting) {
          // VISUAL STROBE LOGIC
          final isStrobe = _rippleController.value > 0.5;
          final bgColor = isStrobe ? Colors.white : Colors.red[900]!;
          final fgColor = isStrobe ? Colors.red[900]! : Colors.white;

          return Scaffold(
            backgroundColor: bgColor, // Flash Effect
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // RIPPLE ANIMATION STACK (Fixed Size)
                  SizedBox(
                    width: 300,
                    height: 300,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ring 1
                        _buildRipple(1.0, fgColor),
                        // Ring 2 
                        _buildRipple(0.7, fgColor),
                        // Ring 3
                        _buildRipple(0.3, fgColor),
                        
                        // The Icon (Inverted Contrast)
                        Icon(Icons.wifi_tethering, size: 100, color: fgColor),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  Text(
                    "BROADCASTING SOS...",
                    style: TextStyle(fontSize: 24, color: fgColor, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "ALARM ACTIVE - SEEKING HELP", 
                    style: TextStyle(color: fgColor.withOpacity(0.8), fontSize: 16),
                  ),
                  const SizedBox(height: 60),
                  ElevatedButton(
                    onPressed: () {
                       service.cancelEmergency();
                       Navigator.pop(context); 
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: fgColor, 
                      foregroundColor: bgColor,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)
                    ),
                    child: const Text('I AM SAFE (RESOLVE)', style: TextStyle(fontWeight: FontWeight.bold)),
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
                const Text('CRASH DETECTED!', style: TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                const Text('Sending SOS in:', style: TextStyle(color: Colors.white, fontSize: 18)),
                
                // Big Countdown Number
                Text(
                  '$_countdown',
                  style: const TextStyle(fontSize: 120, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red
                  ),
                  onPressed: () {
                     service.cancelEmergency();
                     Navigator.pop(context); // Go back home
                  },
                  child: const Text('I AM OKAY (CANCEL)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
     }
    );
  }

  Widget _buildRipple(double startPhase, Color color) {
    double progress = (_rippleController.value + startPhase) % 1.0;
    return Opacity(
      opacity: 1.0 - progress, // Fade out as it grows
      child: Container(
        width: 100 + (progress * 200), // Grow from 100 to 300
        height: 100 + (progress * 200),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.5), width: 3),
        ),
      ),
    );
  }
}

