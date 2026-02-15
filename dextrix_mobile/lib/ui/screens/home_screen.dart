import 'package:flutter/material.dart';
import '../../features/demo/demo_emergency_service.dart';
import 'demo_screen.dart'; // Direct navigation
import 'incoming_alert_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  void initState() {
    super.initState();
    // Listen for incoming alerts
    DemoEmergencyService.instance.addListener(_checkIncomingAlert);
  }

  @override
  void dispose() {
    DemoEmergencyService.instance.removeListener(_checkIncomingAlert);
    super.dispose();
  }

  void _checkIncomingAlert() {
    // If we have an alert and we are currently on this screen (mostly), show it
    if (DemoEmergencyService.instance.currentIncomingAlert != null) {
      // Avoid double push: usually handled by checking route, but for this simple Nav 1.0 logic:
      // We assume if this fires, we check. 
      // But adding a listener like this will fire on EVERY notify. 
      // Better to check inside build or use a stream listener.
      // For Single view, let's just do it in the build method's listener logic or here carefully.
      
      // Simpler approach for this Hackathon:
      // Check if we are already showing it? No easy way without nav key.
      // Let's just Push it and clear it inside the screen? No.
      // Let's rely on the service to notify us only when it SETS it?
      
      // HACK: Just check if we haven't already navigated. 
      // Actually, standard practice for simple apps:
      // Use a post-frame callback in build if generic.
      
      // Let's use the AnimatedBuilder in build() to conditionally show it? 
      // No, pushing a screen is better for "Popup".
      
      // Working Logic:
      // We will perform the check in the listener, but we need to know if we already pushed.
      // Let's just push IMMEDIATE.
      
      // To prevent loop:
      // verify modal route?
      // actually, let's just do it in build() with a SchedulerBinding check
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dextrix 5.0'),
        actions: [
          // Hidden/Subtle Settings for Judge Control
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white24), 
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DemoScreen()),
            ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: DemoEmergencyService.instance,
        builder: (context, _) {
          final service = DemoEmergencyService.instance;
          
          // AUTO-NAVIGATION LOGIC
          if (service.currentIncomingAlert != null) {
            // Unschedule it so we don't loop? No the screen will handle clear.
            // We need to navigate ONCE.
            // Dispatch a post frame callback
            WidgetsBinding.instance.addPostFrameCallback((_) {
               Navigator.push(
                 context, 
                 MaterialPageRoute(builder: (_) => const IncomingAlertScreen())
               );
            });
          }

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

              // Emergency Overlay (Red Flash)
              if (service.emergencyActive)
                Positioned.fill(
                  child: Container(
                    color: Colors.red.withOpacity(0.95),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.warning, size: 100, color: Colors.white),
                          const SizedBox(height: 20),
                          const Text(
                            "CRASH DETECTED!",
                            style: TextStyle(
                              color: Colors.white, 
                              fontSize: 32, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Initializing Timer...",
                            style: TextStyle(color: Colors.white70, fontSize: 18),
                          ),
                          const SizedBox(height: 40),
                          ElevatedButton(
                            onPressed: DemoEmergencyService.instance.cancelEmergency,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            ),
                            child: const Text("I AM SAFE (CANCEL)", style: TextStyle(fontSize: 18)),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

