import 'dart:async'; // Added for Timer
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../features/sensor/sensor_service.dart';
import 'package:vibration/vibration.dart';
import '../mesh/p2p_mesh_service.dart'; // Moved to top
import 'package:geolocator/geolocator.dart'; // Moved to top

import 'package:shared_preferences/shared_preferences.dart';

class DemoEmergencyService extends ChangeNotifier {
  static final DemoEmergencyService instance = DemoEmergencyService._();
  
  final SensorService _sensorService = SensorService();
  
  // PRD: User Identity (Persisted)
  String _userName = "Dextrix Rider"; 
  String get userName => _userName;

  set userName(String value) {
    _userName = value;
    _saveIdentity();
    notifyListeners();
  }

  Future<void> _saveIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_identity', _userName);
    // Sync with Mesh
    P2pMeshService.instance.userName = _userName;
    if (P2pMeshService.instance.isMeshActive) {
       await P2pMeshService.instance.stopMesh();
       await Future.delayed(const Duration(milliseconds: 500));
       await P2pMeshService.instance.startMesh();
    }
  }

  Future<void> _loadIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedName = prefs.getString('user_identity');
    
    // Migration: If old default exists, reset it
    if (savedName == "Rider Kuldeep") savedName = null;
    
    _userName = savedName ?? "Dextrix Rider";
    P2pMeshService.instance.userName = _userName;
    notifyListeners();
  } 

  // Feature: Last Known Location (Lone Wolf Recovery)
  // Saved every 5 mins to local storage in case battery dies in dead zone
  Timer? _lastLocationTimer;
  Map<String, double>? lastKnownLocation;

  // PRD: Incoming Alert Handling
  Map<String, dynamic>? currentIncomingAlert;

  // P2P Service (True Mesh)
  final P2pMeshService _p2pService = P2pMeshService.instance;
  final String _myDeviceId = "DEV-${DateTime.now().millisecondsSinceEpoch}";
  
  // Debug Logs for UI
  List<String> packetLog = [];

  void logPacket(String msg) {
    final time = DateTime.now().toIso8601String().split('T')[1].substring(0,8);
    packetLog.insert(0, "[$time] $msg");
    if (packetLog.length > 50) packetLog.removeLast();
    notifyListeners();
  }

  // Debug Callback for UI Toasts
  void Function(String msg)? onDebugMessage;

  DemoEmergencyService._() {
    _loadIdentity();
    _initSensor();
    
    // Initialize P2P
    _p2pService.init();
    _p2pService.onDebugLog = (msg) => logPacket(msg);

    // Listen for P2P packets
    _p2pService.onDataReceived = (data) {
      final String? type = data['type'];
      final String? sender = data['sender_id'];
      
      logPacket("RX: ${data.toString()}"); // Log RAW packet

      if (sender == _myDeviceId) return; // Ignore own echoes

      if (type == 'SOS') {
        final msg = "⚠️ UDP SOS from ${data['victim_name']}";
        print(msg);
        onDebugMessage?.call(msg);
        
        // Calculate Distance
        double myLat = lastKnownLocation?['lat'] ?? 0.0;
        double myLng = lastKnownLocation?['lng'] ?? 0.0;
        double vicLat = (data['lat'] as num?)?.toDouble() ?? 0.0;
        double vicLng = (data['lng'] as num?)?.toDouble() ?? 0.0;
        
        String distStr = "Unknown Distance";
        if (myLat != 0.0 && vicLat != 0.0) {
            double distMeters = Geolocator.distanceBetween(myLat, myLng, vicLat, vicLng);
            distStr = "${distMeters.toStringAsFixed(0)}m away";
        }
        
        triggerIncomingAlert(data['victim_name'] ?? 'Unknown', distStr, lat: vicLat, lng: vicLng);
      } else if (type == 'HELLO') {
        final String name = data['sender_name'] ?? 'Unknown Rider';
        if (!nearbyRiders.contains(name)) {
          final msg = "👋 Discovered: $name";
          print(msg); 
          onDebugMessage?.call(msg);
          nearbyRiders.add(name);
          scanning = false; // Found someone
          notifyListeners();
        }
      }
    };
  }

  // Speed Warning State
  bool speedWarningActive = false;
  DateTime? _lastWarningTime;

  void _initSensor() {
    print("DemoEmergencyService: Initializing Sensors...");
    _sensorService.startMonitoring();
    _sensorService.crashDetectionStream.listen((force) {
      print("DemoEmergencyService: REAL SENSOR CRASH DETECTED ($force G)");
      simulateCrash(); // Trigger Pre-Alert (Countdown)
    });

    // Speed Monitor (Prediction)
    // 60 km/h = ~16.6 m/s
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10)
    ).listen((position) {
      final speedKmph = position.speed * 3.6;
      if (speedKmph > 60) {
        if (!speedWarningActive && (_lastWarningTime == null || DateTime.now().difference(_lastWarningTime!).inSeconds > 10)) {
           print("⚠️ OVERSPEED DETECTED: ${speedKmph.toStringAsFixed(1)} km/h");
           speedWarningActive = true;
           _lastWarningTime = DateTime.now();
           onDebugMessage?.call("⚠️ SLOW DOWN! Speed: ${speedKmph.toStringAsFixed(0)} km/h");
           notifyListeners();
           
           // Auto-reset warning after 5s
           Future.delayed(const Duration(seconds: 5), () {
             speedWarningActive = false;
             notifyListeners();
           });
        }
      }
    });
  }

  bool meshActive = false;
  bool emergencyActive = false; // True = WE are crashing
  bool isBroadcasting = false; // True = Countdown finished, sending SOS
  bool scanning = false;
  List<String> nearbyRiders = [];

  void startMesh() {
    print("DemoEmergencyService: Mesh Started. Scanning via P2P...");
    meshActive = true;
    scanning = true;
    nearbyRiders.clear(); 
    
    // Start P2P
    _p2pService.startMesh();
    
    notifyListeners();
  }

  void stopMesh() {
    meshActive = false;
    scanning = false;
    nearbyRiders.clear();
    _p2pService.stopMesh();
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
    
    // Safety: Ensure app stays awake during emergency
    WakelockPlus.enable();
    
    // Haptic Feedback for Crash
    Vibration.vibrate(pattern: [500, 200, 500, 200]); 
    
    notifyListeners();
  }

  // 2. Countdown Finished -> Broadcast SOS
  void broadcastSOS() {
    print("DemoEmergencyService: Broadcasting SOS Packet to P2P Mesh...");
    isBroadcasting = true;
    
    // Ensure we have a location (even if approximate)
    double lat = lastKnownLocation?['lat'] ?? 0.0;
    double lng = lastKnownLocation?['lng'] ?? 0.0;

    // DEMO SAFEGUARD: If indoors (0,0), use a fixed "Nearby" location
    // so the other phone can calculate a distance (~150m)
    if (lat == 0.0 && lng == 0.0) {
       print("⚠️ GPS is 0.0 (Indoors). Using SIMULATED Location for Demo.");
       lat = 28.4595; // Demo point matching Trigger Incoming Alert
       lng = 77.0266;
    }

    // Send Real P2P Packet
    final packet = {
      'type': 'SOS',
      'sender_id': _myDeviceId,
      'victim_name': userName,
      'timestamp': DateTime.now().toIso8601String(),
      'lat': lat,
      'lng': lng
    };
    
    _p2pService.broadcastMessage(packet);
    logPacket("TX: SOS SENT -> ${packet['victim_name']}");
    
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

  void triggerIncomingAlert(String victimName, String distance, {double? lat, double? lng}) {
    print("DemoEmergencyService: RECEIVED SOS from $victimName!");
    
    // HEAVY ALARM (Even if silent mode, vibration usually works)
    // Pattern: Wait 0ms, Vibrate 1000ms, Wait 500ms, Vibrate 1000ms...
    Vibration.vibrate(pattern: [0, 1000, 500, 1000, 500, 1000, 500, 1000]);

    currentIncomingAlert = {
      'victim': victimName,
      'distance': distance,
      'timestamp': DateTime.now().toIso8601String(),
      'lat': lat ?? 28.4595,
      'lng': lng ?? 77.0266
    };
    notifyListeners();
  }

  void clearIncomingAlert() {
    currentIncomingAlert = null;
    notifyListeners();
  }
}
