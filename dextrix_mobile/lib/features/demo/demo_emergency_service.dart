import 'package:connectivity_plus/connectivity_plus.dart'; // Added for Auto-Reconnect
import 'dart:async'; // Added for Timer
import 'dart:convert';
import 'package:flutter/widgets.dart'; // Added for Lifecycle Observer
import 'package:flutter/foundation.dart';
import '../../features/sensor/sensor_service.dart';
import 'package:vibration/vibration.dart';
import '../mesh/p2p_mesh_service.dart'; // Moved to top
import 'package:geolocator/geolocator.dart'; // Moved to top

import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart'; // Added for Pocket Mode
import 'package:flutter_tts/flutter_tts.dart'; // Vocal Beacon

class DemoEmergencyService extends ChangeNotifier with WidgetsBindingObserver {

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
    WidgetsBinding.instance.addObserver(this); // Listen to Lifecycle
    _loadIdentity();
    _initSensor();
    _initConnectivity(); // Added for Auto-Reconnect
    
    // Initialize P2P
    _p2pService.init();
    _p2pService.onDebugLog = (msg) => logPacket(msg);

    // Listen for P2P packets
    _p2pService.onDataReceived = (data) async {
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
        
        // Try to get fresh location if missing
        if (myLat == 0.0) {
           try {
             final pos = await Geolocator.getCurrentPosition();
             myLat = pos.latitude;
             myLng = pos.longitude;
             // Update cache
             lastKnownLocation = {'lat': myLat, 'lng': myLng};
           } catch (e) {
             print("Loc Error: $e");
           }
        }

        double vicLat = (data['lat'] as num?)?.toDouble() ?? 0.0;
        double vicLng = (data['lng'] as num?)?.toDouble() ?? 0.0;
        
        String distStr = "Unknown Distance";
        if (myLat != 0.0 && vicLat != 0.0) {
            double distMeters = Geolocator.distanceBetween(myLat, myLng, vicLat, vicLng);
            
            // SANITY CHECK: P2P Range is max ~200m. 
            // If GPS says 2km, GPS is wrong (Indoors).
            if (distMeters > 500) {
              distStr = "Nearby (< 100m)"; // Trust the Mesh, not the GPS drift
            } else {
              distStr = "${distMeters.toStringAsFixed(0)}m away";
            }
        } else {
            // No GPS, but we have P2P packet -> We are close.
            distStr = "Nearby (Visual Range)";
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
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("DemoEmergencyService: Lifecycle State -> $state");
    if (state == AppLifecycleState.resumed) {
       // APP CAME TO FOREGROUND
       // Fix for "Demo Effect": If we were supposed to be meshing, 
       // restart it to grab the radio from OS background throttling.
       if (meshActive) {
          print("🔄 App Resumed. Refreshing Mesh Connection...");
          onDebugMessage?.call("⚡ App Resumed. Refreshing Radio...");
          
          // Quick toggle to wake up Nearby API
          stopMesh();
          Future.delayed(const Duration(milliseconds: 500), () {
             startMesh();
          });
       }
    }
  }

  // Speed Warning State
  bool speedWarningActive = false;
  DateTime? _lastWarningTime;

  // Auto-Restart Mesh on Network Change (Fix for Disconnect Issue)
  void _initConnectivity() {
    print("DemoEmergencyService: Listening for Network Changes...");
    Connectivity().onConnectivityChanged.listen((result) {
      print("Connectivity Changed: $result");

      // SCENARIO E: Relay Upload (If Internet Returns)
      if (result != ConnectivityResult.none) {
         simulateNetworkRestoration();
      }
      
      // AUTO-RESTART MESH (Fix for "Toggle Required")
      // Whether Wi-Fi turns ON or OFF, the Radio state changes.
      // We must restart the Mesh to re-acquire the radio cleanly.
      if (meshActive) {
         print("🔄 Network Changed. Restarting Mesh in 2s...");
         onDebugMessage?.call("🌐 Network Change. Rebinding Mesh...");
         
         // Delay to let OS settle radio
         Future.delayed(const Duration(seconds: 2), () {
            stopMesh();
            Future.delayed(const Duration(milliseconds: 1000), () {
               // Only restart if we were supposed to be active
               // (Check a flag 'shouldBeActive' or just restart)
               startMesh(); 
            });
         });
      }
    }); 
  }

  void _initSensor() {
    print("DemoEmergencyService: Initializing Sensors...");
    _sensorService.startMonitoring();
    _sensorService.crashDetectionStream.listen((force) {
      print("DemoEmergencyService: REAL SENSOR CRASH DETECTED ($force G)");
      simulateCrash(); // Trigger Pre-Alert (Countdown)
    });

    // Speed Monitor (Prediction & Auto-Cancel)
    // 60 km/h = ~16.6 m/s
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5)
    ).listen((position) {
      final speedKmph = position.speed * 3.6;
      
      // SCENARIO C: The Prediction
      if (speedKmph > 60) {
        if (!speedWarningActive && (_lastWarningTime == null || DateTime.now().difference(_lastWarningTime!).inSeconds > 10)) {
           print("⚠️ OVERSPEED DETECTED: ${speedKmph.toStringAsFixed(1)} km/h");
           speedWarningActive = true;
           _lastWarningTime = DateTime.now();
           onDebugMessage?.call("⚠️ SLOW DOWN! Speed: ${speedKmph.toStringAsFixed(0)} km/h");
           notifyListeners();
           
           Future.delayed(const Duration(seconds: 5), () {
             speedWarningActive = false;
             notifyListeners();
           });
        }
      }

      // SCENARIO D: The False Alarm (Auto-Cancel)
      // Logic: If Crash detected (Emergency Active) BUT user is moving fast (> 15km/h)
      // It means they didn't crash, they are riding.
      if (emergencyActive && speedKmph > 15) {
         _movingCount++;
         if (_movingCount >= 3) {
            print("🚗 Movement Detected ($speedKmph km/h). False Alarm! Auto-Cancelling.");
            cancelEmergency();
            onDebugMessage?.call("✅ False Alarm Resolved (You are moving)");
            _movingCount = 0;
         }
      } else {
         _movingCount = 0;
      }
    });
  }
  
  int _movingCount = 0; // For Auto-Cancel logic

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
    
    // KEEP ALIVE: Enable Wakelock to prevent CPU sleeping in background
    WakelockPlus.enable(); 
    
    // Start P2P
    _p2pService.startMesh();
    
    notifyListeners();
  }

  void stopMesh() {
    meshActive = false;
    scanning = false;
    nearbyRiders.clear();
    WakelockPlus.disable(); // Release lock
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

  Timer? _sosTimer;
  Timer? _ttsTimer; // Added for Vocal Loop
  final FlutterTts _tts = FlutterTts();

  // 2. Countdown Finished -> Broadcast SOS
  void broadcastSOS() {
    print("DemoEmergencyService: Broadcasting SOS Packet to P2P Mesh (Looping)...");
    isBroadcasting = true;

    // 1. NETWORK FIRST (Critical Path)
    // Ensure we have a location
    double lat = lastKnownLocation?['lat'] ?? 0.0;
    double lng = lastKnownLocation?['lng'] ?? 0.0;

    if (lat == 0.0 && lng == 0.0) {
       print("⚠️ GPS is 0.0 (Indoors). Using SIMULATED Location for Demo.");
       lat = 28.4595; 
       lng = 77.0266;
    }

    // Start P2P Loop IMMEDIATELY
    _sosTimer?.cancel();
    _sosTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!isBroadcasting) {
           timer.cancel();
           return;
        }
        
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
    });
    
    // 2. AUDIO SECOND (Feedback)
    _startAudioBeacon();
  }

  Future<void> _startAudioBeacon() async {
    try {
      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.5); 
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      
      _ttsTimer?.cancel();
      _tts.speak("Emergency! emergency! Accident Detected! Please Help!");
      
      _ttsTimer = Timer.periodic(const Duration(seconds: 5), (_) {
         if (isBroadcasting) {
            _tts.speak("Emergency! emergency! Please Help!");
         }
      });
    } catch (e) {
      print("TTS Error: $e");
    }
  }
  
  void cancelEmergency() {
    print("DemoEmergencyService: Emergency Cancelled/Resolved.");
    emergencyActive = false;
    isBroadcasting = false;
    _sosTimer?.cancel(); // Stop the loop
    _ttsTimer?.cancel(); // Stop Vocal Loop
    
    // Stop Haptics & Audio
    Vibration.cancel();
    _tts.stop(); 
    
    WakelockPlus.disable();
    
    notifyListeners();
  }

  // --- INCOMING ALERT FLOW (RESPONDER) ---

  // SCENARIO E: The Relay (Store & Forward)
  List<Map<String, dynamic>> relayQueue = [];
  bool isAlarmMuted = false;
  String? lastMutedVictim;
  DateTime? lastMuteTime;

  void triggerIncomingAlert(String victimName, String distance, {double? lat, double? lng}) {
    print("DemoEmergencyService: RECEIVED SOS from $victimName!");
    
    // Logic: Reset Mute if this is a NEW victim
    if (lastMutedVictim != victimName) {
       isAlarmMuted = false; 
    }
    
    // Logic: If Muted for > 15 seconds (Demo Mode), Wake Up (Re-Alert Safety Check)
    if (isAlarmMuted && lastMuteTime != null && DateTime.now().difference(lastMuteTime!).inSeconds >= 15) {
       print("⚠️ Safety Mute Expired (15s passed). Re-Alerting!");
       isAlarmMuted = false;
    }
    
    // HEAVY ALARM LOOP (Infinite until stopped)
    // Only start if not already muted
    if (!isAlarmMuted) {
       Vibration.vibrate(pattern: [500, 2000, 500, 2000], repeat: 0);
    }
    
    // Store for Relay (Scenario E)
    final packet = {
      'victim': victimName,
      'distance': distance,
      'timestamp': DateTime.now().toIso8601String(),
      'lat': lat ?? 28.4595,
      'lng': lng ?? 77.0266,
      'status': 'PENDING_UPLOAD' // Waiting for Internet
    };
    
    currentIncomingAlert = packet;
    relayQueue.add(packet); 
    
    onDebugMessage?.call("📡 SOS Stored in Relay Queue (Waiting for Internet)");
    notifyListeners();
  }
  
  void stopAlarm() {
    isAlarmMuted = true; // Prevents future vibrations for THIS session
    lastMutedVictim = currentIncomingAlert?['victim']; // Remember who we muted
    lastMuteTime = DateTime.now(); // Start the 3-minute timer
    Vibration.cancel();
    print("DemoEmergencyService: Alarm Stopped/Muted.");
  }
  
  // Call this to simulate finding internet (Scenario E completion)
  void simulateNetworkRestoration() {
    if (relayQueue.isEmpty) return;
    
    onDebugMessage?.call("🌐 Network Restored! Uploading ${relayQueue.length} SOS packets...");
    
    // Simulate API Call Time
    Future.delayed(const Duration(seconds: 2), () {
      // Print the ACTUAL data being uploaded (for Demo Proof)
      for (var packet in relayQueue) {
         // TODO: Replace with real API endpoint in Production
         print("☁️ [DEMO SIMULATION] Preparing POST Request...");
         print("🔗 Endpoint: /api/v1/sos_relay (Mocked)");
         print("📦 Payload: ${jsonEncode(packet)}");
      }
      
      relayQueue.clear();
      onDebugMessage?.call("✅ All SOS Data Uploaded to HQ (Mocked Debug)!");
      notifyListeners();
    });
  }

  void clearIncomingAlert() {
    currentIncomingAlert = null;
    notifyListeners();
  }
}
