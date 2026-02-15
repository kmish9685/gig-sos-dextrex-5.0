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

  // Method to manually start discovery for demo
  Future<void> startMesh() async {
    print("[DemoController] Starting Mesh manually...");
    await _meshService.startDiscovery();
  }
  
  Future<void> stopMesh() async {
    await _meshService.stopDiscovery();
  }

  void simulateIncomingSOS() {
    if (_meshService.provider is SimulatedMeshProvider) {
      (_meshService.provider as SimulatedMeshProvider).injectIncomingMessage({
        'alert_id': 'demo-alert-${DateTime.now().millisecondsSinceEpoch}',
        'device_id': 'Rider-Simulated',
        'timestamp': DateTime.now().toIso8601String(),
        'alert_type': 'manual',
        'latitude': 28.4595,
        'longitude': 77.0266,
      });
      print("[DemoController] Injected fake SOS message for demo.");
    } else {
       // Fallback or log if provider isn't simulated
       print("[DemoController] Provider is not Simulated, cannot inject.");
    }
  }
}
