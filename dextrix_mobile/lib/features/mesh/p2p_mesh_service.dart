
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:nearby_connections/nearby_connections.dart';

class P2pMeshService {
  static final P2pMeshService instance = P2pMeshService._();
  P2pMeshService._();

  final Nearby _nearby = Nearby();
  
  // State
  bool isMeshActive = false;
  List<String> connectedEndpoints = []; // List of Endpoint IDs
  String userName = "Dextrix Rider";

  // Callbacks
  void Function(Map<String, dynamic> data)? onDataReceived;
  void Function(String msg)? onDebugLog;

  void init() {
    // Check permissions on init
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // Note: In v4.3.0, we rely on OS dialogs or external permission handler.
    // Assuming permissions are granted for this Hackathon Demo.
  }

  // 1. Start Mesh (Advertising + Discovery)
  Future<void> startMesh() async {
    if (isMeshActive) return;
    
    // Permissions are assumed or handled by UI before this call
    // If explicit check is needed, use permission_handler package
    
    isMeshActive = true;
    onDebugLog?.call("🌐 Starting Nearby Mesh (Strategy: P2P_CLUSTER)...");

    try {
      // A. Start Advertising (Be visible)
      await _nearby.startAdvertising(
        userName,
        Strategy.P2P_CLUSTER,
        onConnectionInitiated: (id, info) {
          onDebugLog?.call("🤝 Connection Initiated by ${info.endpointName} ($id)");
          _acceptConnection(id);
        },
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) {
            onDebugLog?.call("✅ Connected to $id");
            if (!connectedEndpoints.contains(id)) connectedEndpoints.add(id);
          } else {
            onDebugLog?.call("❌ Connection Failed: $status");
          }
        },
        onDisconnected: (id) {
          onDebugLog?.call("🔌 Disconnected: $id");
          connectedEndpoints.remove(id);
        },
      );
      onDebugLog?.call("📢 Advertising Started");
    } catch (e) {
      onDebugLog?.call("❌ Advertise Error: $e");
    }

    try {
      // B. Start Discovery (Find others)
      await _nearby.startDiscovery(
        userName,
        Strategy.P2P_CLUSTER,
        onEndpointFound: (id, name, serviceId) {
          onDebugLog?.call("👀 Found Peer: $name ($id). Requesting Connection...");
          _requestConnection(id, name);
        },
        onEndpointLost: (id) {
          onDebugLog?.call("💨 Lost Peer: $id");
        },
      );
      onDebugLog?.call("🔍 Discovery Started");
    } catch (e) {
      onDebugLog?.call("❌ Discovery Error: $e");
    }
  }

  // 2. Accept Connection
  Future<void> _acceptConnection(String id) async {
    try {
      await _nearby.acceptConnection(
        id,
        onPayLoadRecieved: (id, payload) {
          if (payload.type == PayloadType.BYTES) {
            final str = String.fromCharCodes(payload.bytes!);
            onDebugLog?.call("RX from $id: $str");
            try {
              final json = jsonDecode(str);
              onDataReceived?.call(json);
              
              // Mesh Relay Logic: If valid SOS, re-broadcast to others? 
              // For Demo: Just receive.
            } catch (e) {
              print("Parse Error: $e");
            }
          }
        },
      );
    } catch (e) {
      onDebugLog?.call("❌ Accept Error: $e");
    }
  }

  // 3. Request Connection
  Future<void> _requestConnection(String id, String name) async {
    try {
      await _nearby.requestConnection(
        userName,
        id,
        onConnectionInitiated: (id, info) {
          onDebugLog?.call("🤝 Outgoing Connection Initiated to ${info.endpointName}");
          _acceptConnection(id);
        },
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) {
             onDebugLog?.call("✅ Connected to $id");
             if (!connectedEndpoints.contains(id)) connectedEndpoints.add(id);
          } else {
             onDebugLog?.call("❌ Connection Failed: $status");
          }
        },
        onDisconnected: (id) {
          onDebugLog?.call("🔌 Disconnected: $id");
          connectedEndpoints.remove(id);
        },
      );
    } catch (e) {
      onDebugLog?.call("❌ Request Error: $e");
    }
  }

  // 4. Broadcast
  void broadcastMessage(Map<String, dynamic> data) async {
    if (connectedEndpoints.isEmpty) {
      onDebugLog?.call("⚠️ No Connected Peers.");
      return;
    }

    final jsonStr = jsonEncode(data);
    final bytes = Uint8List.fromList(utf8.encode(jsonStr));

    for (var id in connectedEndpoints) {
      try {
        await _nearby.sendBytesPayload(id, bytes);
      } catch (e) {
        print("Send Error to $id: $e");
      }
    }
    onDebugLog?.call("TX P2P (x${connectedEndpoints.length}): $jsonStr");
  }

  Future<void> stopMesh() async {
    isMeshActive = false;
    await _nearby.stopAdvertising();
    await _nearby.stopDiscovery();
    connectedEndpoints.clear();
    onDebugLog?.call("🛑 Mesh Stopped");
  }
}
