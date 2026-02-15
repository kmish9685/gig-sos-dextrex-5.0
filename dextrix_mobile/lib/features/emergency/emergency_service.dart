import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../core/utils/constants.dart'; // We will create this
import '../sensor/sensor_module.dart';
import '../mesh/mesh_module.dart';
import 'emergency_module.dart';

class EmergencyService implements EmergencyModule {
  final SensorModule _sensorModule;
  final MeshModule _meshModule;
  final _stateController = StreamController<AppSafetyState>.broadcast();
  
  AppSafetyState _currentState = AppSafetyState.idle;
  Timer? _countdownTimer;
  int _countdownSeconds = 5;
  
  // Current active alert (either my own or received)
  Map<String, dynamic>? _activeAlert;

  EmergencyService({
    required SensorModule sensorModule,
    required MeshModule meshModule,
  })  : _sensorModule = sensorModule,
        _meshModule = meshModule {
    _init();
  }

  void _init() {
    // Listen to crash detection
    _sensorModule.crashDetectionStream.listen((gForce) {
      if (_currentState == AppSafetyState.idle) {
        print("[EmergencyService] Crash Detected ($gForce G). Triggering Countdown.");
        triggerEmergency();
      }
    });

    // Listen to incoming mesh messages
    _meshModule.messageStream.listen((message) {
      _handleIncomingMessage(message);
    });
    
    // Emit initial state
    _stateController.add(_currentState);
  }

  @override
  Stream<AppSafetyState> get stateStream => _stateController.stream;

  @override
  void triggerEmergency() {
    if (_currentState != AppSafetyState.idle) return;

    _updateState(AppSafetyState.preAlert);
    _startCountdown();
  }

  @override
  void cancelEmergency() {
    print("[EmergencyService] Emergency Cancelled by User.");
    _countdownTimer?.cancel();
    _updateState(AppSafetyState.idle);
    _activeAlert = null;
  }

  @override
  void acknowledgeAlert(String alertId) {
    // Logic to accept/navigate to rescue
    // For now, just log
    print("[EmergencyService] Acknowledged Alert: $alertId");
  }

  @override
  void relayAlert(String alertId) {
    // Logic to rebroadcast
    if (_activeAlert != null) {
       _meshModule.broadcastMessage(_activeAlert!);
       _updateState(AppSafetyState.relaying);
    }
  }

  void _startCountdown() {
    _countdownSeconds = 5;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdownSeconds--;
      print("[EmergencyService] Countdown: $_countdownSeconds");
      
      if (_countdownSeconds <= 0) {
        timer.cancel();
        _activateSOS();
      }
    });
  }

  Future<void> _activateSOS() async {
    print("[EmergencyService] SOS ACTIVATED!");
    _updateState(AppSafetyState.sosActive);

    // Create Alert Payload
    final alertPayload = {
      "alert_id": const Uuid().v4(),
      "timestamp": DateTime.now().toIso8601String(),
      "latitude": 0.0, // TODO: Get from MapModule
      "longitude": 0.0,
      "device_id": "my-device-id", // TODO: Persist ID
      "alert_type": "auto",
      "ttl": 3,
    };

    _activeAlert = alertPayload;
    
    // Broadcast
    await _meshModule.broadcastMessage(alertPayload);
    
    // Keep broadcasting periodically? (Handled by MeshService logic usually)
  }

  void _handleIncomingMessage(Map<String, dynamic> message) {
    if (_currentState == AppSafetyState.idle || _currentState == AppSafetyState.relaying) {
      print("[EmergencyService] Received SOS from ${message['device_id']}");
      _activeAlert = message;
      _updateState(AppSafetyState.sosReceived);
    }
  }

  void _updateState(AppSafetyState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }
}
