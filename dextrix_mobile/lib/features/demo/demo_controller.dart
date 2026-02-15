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
    // Only works if using Mock or we force injection
    // For Nearby, we can't easily inject without a second device,
    // so we rely on the MockProvider logic OR allow loopback if we implemented it.
    // For now, let's just trigger the EmergencyState directly to Simulate "Received"
    // This is a "God Mode" cheat.
    
    _emergencyModule.acknowledgeAlert("demo-remote-alert"); // Trigger UI reaction
    print("[DemoController] Simulated Incoming Alert Triggered (UI Only)");
  }
}
