/// Core Mesh Communication Module Interface
/// Responsible for device discovery and offline data transmission.
abstract class MeshModule {
  /// Stream of discovered peers nearby.
  Stream<List<String>> get peersStream;

  /// Stream of incoming messages (SOS alerts).
  Stream<Map<String, dynamic>> get messageStream;

  /// Starts advertising valid presence and scanning for others.
  Future<void> startDiscovery();

  /// Stops all mesh activity.
  Future<void> stopDiscovery();

  /// Broadcasts an SOS alert to all connected/reachable peers.
  /// [payload] is the JSON data of the alert.
  Future<void> broadcastMessage(Map<String, dynamic> payload);

  /// Connects to a specific peer (if needed for direct transfer).
  Future<void> connectToPeer(String peerId);
}


