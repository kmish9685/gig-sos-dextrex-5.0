import 'dart:async';
import 'dart:math';

/// Abstract provider for mesh networking technologies (BLE, WiFi Direct, Mock).
abstract class MeshProvider {
  Stream<List<String>> get peersStream;
  Stream<Map<String, dynamic>> get messageStream;
  
  Future<void> startDiscovery();
  Future<void> stopDiscovery();
  Future<void> broadcast(Map<String, dynamic> payload);
}

/// Mock implementation for testing/demo purposes.
/// Simulates peers appearing and receiving messages.
class MockMeshProvider implements MeshProvider {
  final _peersController = StreamController<List<String>>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Timer? _simulationTimer;
  final Random _random = Random();
  final List<String> _dummyPeers = ['Rider-A', 'Rider-B', 'Rider-C'];

  @override
  Stream<List<String>> get peersStream => _peersController.stream;

  @override
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  @override
  Future<void> startDiscovery() async {
    print("[MockMesh] Starting discovery...");
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      // Simulate peers appearing/disappearing
      if (_random.nextBool()) {
        final count = _random.nextInt(_dummyPeers.length + 1);
        final visiblePeers = _dummyPeers.take(count).toList();
        _peersController.add(visiblePeers);
        print("[MockMesh] Visible peers: $visiblePeers");
      }
    });
  }

  @override
  Future<void> stopDiscovery() async {
    print("[MockMesh] Stopping discovery...");
    _simulationTimer?.cancel();
  }

  @override
  Future<void> broadcast(Map<String, dynamic> payload) async {
    print("[MockMesh] Broadcasting: $payload");
    // Simulate echo or response?
    // In a real relay, we might get an ACK.
    await Future.delayed(const Duration(milliseconds: 500));
  }
  
  // Method to simulate receiving an alert from a peer
  void simulateIncomingMessage(Map<String, dynamic> message) {
    _messageController.add(message);
    print("[MockMesh] Simulated Incoming Message: $message");
  }
}
