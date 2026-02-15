import 'package:flutter/foundation.dart';
import '../../features/sensor/sensor_service.dart';
import 'dart:async';

class DemoEmergencyService extends ChangeNotifier {
  static final DemoEmergencyService instance = DemoEmergencyService._();
  
  final SensorService _sensorService = SensorService();
  
  // PRD: User Identity
  String userName = "Rider Kuldeep"; 

  // PRD: Incoming Alert Handling
  Map<String, dynamic>? currentIncomingAlert;
  
  DemoEmergencyService._() {
    _initSensor();
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
    print("DemoEmergencyService: Mesh Started. Scanning...");
    meshActive = true;
    scanning = true;
    nearbyRiders.clear(); 
    notifyListeners();
  }

  void stopMesh() {
    meshActive = false;
    scanning = false;
    nearbyRiders.clear();
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
    print("DemoEmergencyService: Broadcasting SOS Packet to Mesh...");
    isBroadcasting = true;
    // In real app, we would send data via MeshModule here
    notifyListeners();
  }

  // 3. Cancel/Resolve
  void cancelEmergency() {
    print("DemoEmergencyService: Emergency Cancelled/Resolved.");
    emergencyActive = false;
    isBroadcasting = false;
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

