import 'package:flutter/foundation.dart';
import '../../features/sensor/sensor_service.dart';
import 'package:vibration/vibration.dart';

// ... (existing imports)

// ... inside class ...

    // Speed Monitor (Prediction)
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10)
    ).listen((position) {
      // Update Last Known Location (in memory for now, would be SharedPrefs)
      lastKnownLocation = {'lat': position.latitude, 'lng': position.longitude};
      
      final speedKmph = position.speed * 3.6;
      if (speedKmph > 60) { // Limit
        if (!speedWarningActive && (_lastWarningTime == null || DateTime.now().difference(_lastWarningTime!).inSeconds > 10)) {
           print("⚠️ OVERSPEED DETECTED: ${speedKmph.toStringAsFixed(1)} km/h");
           speedWarningActive = true;
           _lastWarningTime = DateTime.now();
           
           // Validated: Feature Request - Vibrate on Overspeed
           Vibration.vibrate(duration: 1000); 
           
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
    
    // Feature: Last Known Location Sync (Every 5 mins)
    _lastLocationTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
        if (lastKnownLocation != null) {
            print("📍 Saved Last Known Location: ${lastKnownLocation.toString()} (Lone Wolf Protection)");
            // In real app: await SharedPreferences.getInstance().then((p) => p.setString('last_loc', jsonEncode(lastKnownLocation)));
        }
    });
  }
import '../mesh/wifi_lan_service.dart';
import 'package:geolocator/geolocator.dart';

class DemoEmergencyService extends ChangeNotifier {
  static final DemoEmergencyService instance = DemoEmergencyService._();
  
  final SensorService _sensorService = SensorService();
  
  // PRD: User Identity
  String userName = "Rider Kuldeep"; 

  // Feature: Last Known Location (Lone Wolf Recovery)
  // Saved every 5 mins to local storage in case battery dies in dead zone
  Timer? _lastLocationTimer;
  Map<String, double>? lastKnownLocation;

  // PRD: Incoming Alert Handling
  Map<String, dynamic>? currentIncomingAlert;

  // UDP Service
  final WifiLanService _lanService = WifiLanService.instance;
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
    _initSensor();
    // Listen for UDP packets
    _lanService.onDataReceived = (data) {
      final String? type = data['type'];
      final String? sender = data['sender_id'];
      
      logPacket("RX: ${data.toString()}"); // Log RAW packet

      if (sender == _myDeviceId) return; // Ignore own echoes

      if (type == 'SOS') {
        final msg = "⚠️ UDP SOS from ${data['victim_name']}";
        print(msg);
        onDebugMessage?.call(msg);
        triggerIncomingAlert(data['victim_name'] ?? 'Unknown', 'Nearby (WiFi)');
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
    
    // Haptic Feedback for Crash
    Vibration.vibrate(pattern: [500, 200, 500, 200]); 
    
    notifyListeners();
  }

  // 2. Countdown Finished -> Broadcast SOS
  void broadcastSOS() {
    print("DemoEmergencyService: Broadcasting SOS Packet to UDP Mesh...");
    isBroadcasting = true;
    
    // Send Real UDP Packet
    final packet = {
      'type': 'SOS',
      'sender_id': _myDeviceId,
      'victim_name': userName,
      'timestamp': DateTime.now().toIso8601String(),
      'lat': lastKnownLocation?['lat'] ?? 0.0,
      'lng': lastKnownLocation?['lng'] ?? 0.0
    };
    
    _lanService.broadcastMessage(packet);
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
