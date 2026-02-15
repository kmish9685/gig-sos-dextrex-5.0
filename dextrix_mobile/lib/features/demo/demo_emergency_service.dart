import 'package:flutter/foundation.dart';
import '../../features/sensor/sensor_service.dart';
import 'dart:async';
import '../mesh/wifi_lan_service.dart';

class DemoEmergencyService extends ChangeNotifier {
  static final DemoEmergencyService instance = DemoEmergencyService._();
  
  final SensorService _sensorService = SensorService();
  
  // PRD: User Identity
  String userName = "Rider Kuldeep"; 

  // PRD: Incoming Alert Handling
  Map<String, dynamic>? currentIncomingAlert;

  // UDP Service
  final WifiLanService _lanService = WifiLanService.instance;
  final String _myDeviceId = "DEV-${DateTime.now().millisecondsSinceEpoch}";
  
  DemoEmergencyService._() {
    _initSensor();
    // Listen for UDP packets
    _lanService.onDataReceived = (data) {
      final String? type = data['type'];
      final String? sender = data['sender_id'];
      
      if (sender == _myDeviceId) return; // Ignore own echoes

      if (type == 'SOS') {
        print("DemoEmergencyService: REAL UDP SOS RECEIVED!");
        triggerIncomingAlert(data['victim_name'] ?? 'Unknown', 'Nearby (WiFi)');
      } else if (type == 'HELLO') {
        final String name = data['sender_name'] ?? 'Unknown Rider';
        if (!nearbyRiders.contains(name)) {
          print("DemoEmergencyService: Discovered Peer via UDP - $name");
          nearbyRiders.add(name);
          scanning = false; // Found someone
          notifyListeners();
        }
      }
    };
  }

  void _initSensor() {
    print("DemoEmergencyService: Initializing Sensors...");
    _sensorService.startMonitoring();
    _sensorService.crashDetectionStream.listen((force) {
      print("DemoEmergencyService: REAL SENSOR CRASH DETECTED ($force G)");
      simulateCrash(); // Trigger Pre-Alert (Countdown)
    });
  }

  bool meshActive = false;
  bool emergencyActive = false; // True = WE are crashing
  bool isBroadcasting = false; // True = Countdown finished, sending SOS
  bool scanning = false;
  List<String> nearbyRiders = [];

  void startMesh() {
    print("DemoEmergencyService: Mesh Started. Scanning via UDP...");
    meshActive = true;
    scanning = true;
    nearbyRiders.clear(); 
    
    // Start UDP Listener
    _lanService.startListening();
    
    notifyListeners();
  }

  void stopMesh() {
    meshActive = false;
    scanning = false;
    nearbyRiders.clear();
    _lanService.stopListening();
    notifyListeners();
  }

  void injectDiscoveredRider(String name) {
    if (!meshActive) return;
    if (!nearbyRiders.contains(name)) {
      nearbyRiders.add(name);
      scanning = false; 
      notifyListeners();
    }
  }

  // --- MY EMERGENCY FLOW ---

  // 1. Crash Detected -> Start Countdown
  void simulateCrash() {
    print("DemoEmergencyService: Crash Logic Triggered! Starting Countdown.");
    emergencyActive = true;
    isBroadcasting = false;
    notifyListeners();
  }

  // 2. Countdown Finished -> Broadcast SOS
  void broadcastSOS() {
    print("DemoEmergencyService: Broadcasting SOS Packet to UDP Mesh...");
    isBroadcasting = true;
    
    // Send Real UDP Packet
    _lanService.broadcastMessage({
      'type': 'SOS',
      'sender_id': _myDeviceId,
      'victim_name': userName,
      'timestamp': DateTime.now().toIso8601String()
    });
    
    notifyListeners();
  }

  // 3. Cancel/Resolve
  void cancelEmergency() {
    print("DemoEmergencyService: Emergency Cancelled/Resolved.");
    emergencyActive = false;
    isBroadcasting = false;
    // Optional: Send 'CANCEL' packet
    notifyListeners();
  }

  // --- INCOMING ALERT FLOW (RESPONDER) ---

  void triggerIncomingAlert(String victimName, String distance) {
    print("DemoEmergencyService: RECEIVED SOS from $victimName!");
    currentIncomingAlert = {
      'victim': victimName,
      'distance': distance,
      'timestamp': DateTime.now().toIso8601String(),
      'lat': 28.4595,
      'lng': 77.0266
    };
    notifyListeners();
  }

  void clearIncomingAlert() {
    currentIncomingAlert = null;
    notifyListeners();
  }
}
