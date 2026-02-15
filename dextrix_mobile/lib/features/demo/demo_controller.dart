import 'package:flutter/foundation.dart';
import 'demo_module.dart';
import '../emergency/emergency_module.dart';
import '../mesh/mesh_service.dart';
import '../mesh/mesh_provider.dart';

class DemoController implements DemoModule {
  final EmergencyModule _emergencyModule;
  final MeshService _meshService; // To access provider
  
  bool _isGodMode = false;

  DemoController({
    required EmergencyModule emergencyModule,
    required MeshService meshService,
  })  : _emergencyModule = emergencyModule,
        _meshService = meshService;

  @override
  bool get isGodModeEnabled => _isGodMode;

  void toggleGodMode(bool enabled) {
    _isGodMode = enabled;
    print("[DemoController] God Mode: $enabled");
  }

  @override
  void forceState(String stateName) {
    if (!_isGodMode) return;
    
    // Simple state forcing logic
    if (stateName == 'SOS') {
      _emergencyModule.triggerEmergency();
    } else if (stateName == 'IDLE') {
      _emergencyModule.cancelEmergency();
    }
  }

  @override
  void toggleNetworkSimulation(bool isOnline) {
    // TODO: Connect to ConnectivityService if implemented
    print("[DemoController] Network Sim: ${isOnline ? 'Online' : 'Offline'}");
  }

  @override
  void injectFakePeer(String deviceId) {
    // Cast to Mock provider if possible
    if (_meshService.provider is MockMeshProvider) {
       // (_meshService.provider as MockMeshProvider).injectPeer(deviceId);
       print("[DemoController] Injecting fake peer (requires MockMesh update)");
    }
  }

  void simulateIncomingSOS() {
    if (_meshService.provider is MockMeshProvider) {
      (_meshService.provider as MockMeshProvider).simulateIncomingMessage({
        'alert_id': 'demo-alert-123',
        'device_id': 'demo-rider-B',
        'timestamp': DateTime.now().toIso8601String(),
        'alert_type': 'manual',
        'latitude': 28.4595,
        'longitude': 77.0266,
      });
    }
  }
}
