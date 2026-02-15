import 'dart:async';
import 'dart:math';
import 'package:uuid/uuid.dart';
import 'mesh_provider.dart';

/// reliable Simulated Mesh Layer for Hackathon Demo
///
/// Simulates:
/// 1. Discovery of nearby peers (with random delays)
/// 2. Transmission of messages (with 1-2s latency)
/// 3. "Offline" behavior (works without internet/bluetooth)
class SimulatedMeshProvider implements MeshProvider {
  final _peersController = StreamController<List<String>>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  
  // Simulation State
  Timer? _discoveryLoop;
  final Random _random = Random();
  final List<String> _fakePeers = [
    "Rider-Amit (Available)", 
    "Rider-Sara (Busy)", 
    "Rider-Rahul (Nearby)"
  ];
  final List<String> _visiblePeers = [];
  
  bool _isDiscovering = false;

  @override
  Stream<List<String>> get peersStream => _peersController.stream;

  @override
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  @override
  Future<void> startDiscovery() async {
    if (_isDiscovering) return;
    _isDiscovering = true;
    print("[SimulatedMesh] Starting Mock Discovery...");
    
    // Simulate finding peers over time to look real
    _discoveryLoop = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_isDiscovering) {
        timer.cancel();
        return;
      }
      
      // Randomly add/remove a peer to make it feel "alive"
      if (_random.nextBool()) {
        if (_visiblePeers.length < _fakePeers.length) {
          final newPeer = _fakePeers[_visiblePeers.length];
          _visiblePeers.add(newPeer);
          print("[SimulatedMesh] Found peer: $newPeer");
        }
      } else if (_visiblePeers.isNotEmpty && _random.nextDouble() > 0.8) {
         // 20% chance to lose a peer
         final removed = _visiblePeers.removeAt(0);
         print("[SimulatedMesh] Lost peer: $removed");
      }
      
      _peersController.add(List.from(_visiblePeers));
    });
  }

  @override
  Future<void> stopDiscovery() async {
    _isDiscovering = false;
    _discoveryLoop?.cancel();
    _visiblePeers.clear();
    _peersController.add([]);
    print("[SimulatedMesh] Discovery Stopped.");
  }

  @override
  Future<void> broadcast(Map<String, dynamic> payload) async {
    if (_visiblePeers.isEmpty) {
      print("[SimulatedMesh] Broadcast failed: No peers found.");
      // In a real demo, we might want to force a peer to appear so the demo succeeds
      _visiblePeers.add(_fakePeers[0]);
      _peersController.add(_visiblePeers);
      await Future.delayed(const Duration(seconds: 1));
    }

    print("[SimulatedMesh] Broadcasting SOS packet...");
    
    // Simulate Network Latency (1.5 seconds)
    await Future.delayed(const Duration(milliseconds: 1500));
    
    print("[SimulatedMesh] Packet transmitted to ${_visiblePeers.length} peers.");
    
    // SIMULATION TRICK:
    // In a real demo with 2 phones, this "Broadcast" only logs locally.
    // To make Phone B react, we can't magically send data without Bluetooth.
    // 
    // OPTIONS FOR HACKATHON DEMO:
    // 1. Single Device Demo: The app simulates receiving its OWN message back as an echo check.
    // 2. Wizard of Oz: User taps "Simulate Receive" on Phone B manually.
    // 
    // We will implement an "Echo" for single-device sanity check, 
    // BUT explicit `simulateIncomingMessage` is better controlled via the DemoController.
  }
  
  // Exposed for DemoController to force a message arrival
  void injectIncomingMessage(Map<String, dynamic> message) {
    print("[SimulatedMesh] Injecting INCOMING message from 'fake' network.");
    _messageController.add(message);
  }
}
