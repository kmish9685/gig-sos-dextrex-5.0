import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/constants.dart';
import '../sensor/sensor_module.dart';
import '../mesh/mesh_module.dart';
import 'emergency_module.dart';

// Mapping requested states to internal enum or extending enum
// Internal: idle, preAlert, sosActive, sosReceived, relaying
// Requested: IDLE, CRASH_DETECTED, SOS_BROADCASTING, ALERT_RECEIVED, RESCUE_ACTIVE

class EmergencyService implements EmergencyModule {
  final SensorModule _sensorModule;
  final MeshModule _meshModule;
  final _stateController = StreamController<AppSafetyState>.broadcast();
  final Uuid _uuid = const Uuid();
  
  AppSafetyState _currentState = AppSafetyState.idle;
  Timer? _countdownTimer;
  int _countdownSeconds = 5;
  
  Map<String, dynamic>? _activeAlert;
  String? _myDeviceId;

  EmergencyService({
    required SensorModule sensorModule,
    required MeshModule meshModule,
  })  : _sensorModule = sensorModule,
        _meshModule = meshModule {
    _init();
  }

  Future<void> _init() async {
    await _loadDeviceId();
    
    // Listen to crash detection
    _sensorModule.crashDetectionStream.listen((gForce) {
      if (_currentState == AppSafetyState.idle) {
        print("[EmergencyService] Crash Detected ($gForce G). Triggering State.");
        triggerEmergency();
      }
    });

    // Listen to incoming mesh messages
    _meshModule.messageStream.listen((message) {
      _handleIncomingMessage(message);
    });
    
    _emitState(_currentState);
  }
  
  Future<void> _loadDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    _myDeviceId = prefs.getString('device_id');
    if (_myDeviceId == null) {
      _myDeviceId = _uuid.v4().substring(0, 8); // Short ID for demo
      await prefs.setString('device_id', _myDeviceId!);
    }
    print("[EmergencyService] My Device ID: $_myDeviceId");
  }

  @override
  Stream<AppSafetyState> get stateStream => _stateController.stream;

  @override
  void triggerEmergency() {
    if (_currentState != AppSafetyState.idle) return;
    _updateState(AppSafetyState.preAlert); // CRASH_DETECTED equivalent
    _startCountdown();
  }

  @override
  void cancelEmergency() {
    print("[EmergencyService] Cancelled.");
    _countdownTimer?.cancel();
    _updateState(AppSafetyState.idle);
    _activeAlert = null;
  }

  @override
  void acknowledgeAlert(String alertId) {
     // TODO: Move to rescue state
     print("[EmergencyService] Alert Acknowledged.");
  }

  @override
  void relayAlert(String alertId) {
    if (_activeAlert != null) {
       _meshModule.broadcastMessage(_activeAlert!);
       _updateState(AppSafetyState.relaying);
    }
  }

  void _startCountdown() {
    _countdownSeconds = 5;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdownSeconds--;
      print("[EmergencyService] $_countdownSeconds...");
      
      if (_countdownSeconds <= 0) {
        timer.cancel();
        _activateSOS();
      }
    });
  }

  Future<void> _activateSOS() async {
    _updateState(AppSafetyState.sosActive); // SOS_BROADCASTING

    final alertPayload = {
      "alert_id": _uuid.v4(),
      "timestamp": DateTime.now().toIso8601String(),
      "device_id": _myDeviceId ?? "unknown",
      "latitude": 28.4595, // TODO: Real GPS
      "longitude": 77.0266,
      "type": "CRASH_AUTO",
      "status": "ACTIVE"
    };

    _activeAlert = alertPayload;
    print("[EmergencyService] Broadcasting SOS: $alertPayload");
    
    await _meshModule.broadcastMessage(alertPayload);
    _persistAlert(alertPayload);
  }

  void _handleIncomingMessage(Map<String, dynamic> message) {
    // Basic filter: Don't react to own messages (if looped back)
    if (message['device_id'] == _myDeviceId) return;
    
    if (_currentState == AppSafetyState.idle || _currentState == AppSafetyState.relaying) {
      print("[EmergencyService] !!! ALERT RECEIVED !!! From: ${message['device_id']}");
      _activeAlert = message;
      _updateState(AppSafetyState.sosReceived); // ALERT_RECEIVED
      _persistAlert(message);
    }
  }
  
  Future<void> _persistAlert(Map<String, dynamic> alert) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('alert_history') ?? [];
    history.add(jsonEncode(alert));
    await prefs.setStringList('alert_history', history);
  }

  void _updateState(AppSafetyState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _emitState(newState);
    }
  }
  
  void _emitState(AppSafetyState state) {
    _stateController.add(state);
    print("[EmergencyService] State Changed: $state");
  }
}
