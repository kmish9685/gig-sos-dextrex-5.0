import 'package:flutter/material.dart';
import '../../features/demo/demo_emergency_service.dart';
import 'signal_monitor_screen.dart';
import 'demo_screen.dart'; // Direct navigation
import 'incoming_alert_screen.dart';
import 'emergency_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isEmergencyShown = false;

  @override
  void initState() {
    super.initState();
    
    // AUTO-START MESH (Safety First)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DemoEmergencyService.instance.startMesh();
    });

    DemoEmergencyService.instance.addListener(_onServiceUpdate);
    
    // Visual Debugging Hook
    DemoEmergencyService.instance.onDebugMessage = (msg) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg), 
            duration: const Duration(milliseconds: 1500),
            backgroundColor: msg.startsWith("⚠️") ? Colors.red : Colors.green,
          )
        );
      }
    };
  }

  @override
  void dispose() {
    DemoEmergencyService.instance.removeListener(_onServiceUpdate);
    DemoEmergencyService.instance.onDebugMessage = null;
    super.dispose();
  }

  void _onServiceUpdate() {
    final service = DemoEmergencyService.instance;
    
    // 1. My Emergency Logic (Crash)
    if (service.emergencyActive && !_isEmergencyShown) {
      _isEmergencyShown = true;
      Navigator.push(
        context, 
        MaterialPageRoute(builder: (_) => EmergencyScreen())
      ).then((_) {
        // When we come back, reset logic
        _isEmergencyShown = false;
        // Also ensure service is reset if they just pressed "Back" without resolving
        if (service.emergencyActive) {
           service.cancelEmergency(); 
        }
      });
    }

    // 2. Incoming Alert Logic (Others)
    if (service.currentIncomingAlert != null) {
      // Basic check to avoid multi-push would be good, but for MVP:
      // We rely on the screen itself to dismiss and clear data
       if (ModalRoute.of(context)?.isCurrent ?? false) {
          Navigator.push(
             context, 
             MaterialPageRoute(builder: (_) => const IncomingAlertScreen())
          );
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DEXTRIX 5.0'),
        actions: [
          IconButton(
            icon: const Icon(Icons.radar), 
            tooltip: "Signal Matrix",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignalMonitorScreen()))
          ),
          IconButton(
            icon: const Icon(Icons.settings), 
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: DemoEmergencyService.instance,
        builder: (context, _) {
          final service = DemoEmergencyService.instance;
          
          return Stack(
            children: [
              // Main Content
              Column(
                children: [
                  const SizedBox(height: 20),
                  // Identity Card
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 20),
                     child: Align(
                       alignment: Alignment.centerLeft,
                       child: Text("Welcome, ${service.userName}", style: const TextStyle(fontSize: 16, color: Colors.white70)),
                     ),
                   ),

                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Status Indicator
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: service.meshActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: service.meshActive ? Colors.green : Colors.grey,
                              width: 2
                            )
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                service.meshActive ? Icons.wifi_tethering : Icons.wifi_off,
                                color: service.meshActive ? Colors.green : Colors.grey
                              ),
                              const SizedBox(width: 10),
                              Text(
                                service.meshActive ? "MESH: SEARCHING" : "MESH: OFFLINE",
                                style: TextStyle(
                                  fontSize: 18, 
                                  fontWeight: FontWeight.bold,
                                  color: service.meshActive ? Colors.green : Colors.grey
                                )
                              ),
                            ],
                          ),
                        ),

                        // Nearby Riders Logic
                        if (service.meshActive) ...[
                          const Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                  padding: EdgeInsets.only(left: 40, bottom: 10),
                                  child: Text("Nearby Riders:", style: TextStyle(fontWeight: FontWeight.bold))
                              )
                          ),
                          
                          if (service.nearbyRiders.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Column(
                                  children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 10),
                                      Text("Scanning for nearby riders...", style: TextStyle(color: Colors.grey))
                                  ]
                              ),
                            )
                          else
                            Expanded(child: ListView(
                              shrinkWrap: true,
                              children: service.nearbyRiders.map((rider) => Card(
                              margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 4),
                              child: ListTile(
                                leading: const Icon(Icons.person_pin_circle, color: Colors.blue),
                                title: Text(rider),
                                trailing: const Text("~100m"),
                              ),
                            )).toList())),
                            
                          const SizedBox(height: 20),
                          TextButton(
                               onPressed: DemoEmergencyService.instance.stopMesh, 
                               child: const Text("Turn Off Mesh", style: TextStyle(color: Colors.grey))
                          ),
                          const SizedBox(height: 20),
                        ] else ...[
                           ElevatedButton.icon(
                            icon: const Icon(Icons.radar),
                            label: const Text("ACTIVATE MESH NETWORK"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            ),
                            onPressed: DemoEmergencyService.instance.startMesh,
                          ),
                          const SizedBox(height: 20),
                        ],
                        
                        const Spacer(),

                        // Manual SOS Button
                        Padding(
                          padding: const EdgeInsets.only(bottom: 40.0),
                          child: ElevatedButton.icon(
                            onPressed: DemoEmergencyService.instance.simulateCrash,
                            icon: const Icon(Icons.warning_amber_rounded),
                            label: const Text("TRIGGER SOS"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                              textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // REMOVED OVERLAY BLOCK HERE
            ],
          );
        },
      ),
    );
  }
}

