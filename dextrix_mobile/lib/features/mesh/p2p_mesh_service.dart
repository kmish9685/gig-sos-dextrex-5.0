
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';

class P2pMeshService {
  static final P2pMeshService instance = P2pMeshService._();
  P2pMeshService._();

  late NearbyService _nearbyService;
  StreamSubscription? _stateSubscription;
  StreamSubscription? _browserSubscription;
  StreamSubscription? _advertiserSubscription;
  StreamSubscription? _dataSubscription;

  List<Device> connectedDevices = [];
  bool isMeshActive = false;

  // Callbacks
  void Function(Map<String, dynamic> data)? onDataReceived;
  void Function(String msg)? onDebugLog;

  void init() {
    _nearbyService = NearbyService(); // Instantiate immediately
    
    // Initialize Nearby Service
    _nearbyService.init(
      serviceType: 'mp-connection',
      strategy: Strategy.P2P_CLUSTER, // M-to-N Mesh Strategy
      callback: (isRunning) {
        if (isRunning) {
          onDebugLog?.call("✅ P2P Service Started (Strategy: Cluster)");
          // We don't auto-start here, waiting for UI command
        } else {
          onDebugLog?.call("❌ P2P Service Failed to Start!");
        }
      }
    );
  }

  void startMesh() {
    if (isMeshActive) return;
    isMeshActive = true;
    onDebugLog?.call("🌐 P2P Mesh: Starting Discovery & Advertising...");
    
    // 1. State Monitor (Detect Peers)
    _stateSubscription = _nearbyService.stateChangedSubscription(callback: (devicesList) {
      connectedDevices.clear();
      onDebugLog?.call("👀 P2P State Changed: ${devicesList.length} devices found");

      for (var device in devicesList) {
        if (device.state == SessionState.connected) {
          connectedDevices.add(device);
          onDebugLog?.call("✅ Connected to: ${device.deviceName} (${device.deviceId})");
        } else if (device.state == SessionState.notConnected) {
          onDebugLog?.call("🔌 Disconnected: ${device.deviceName}");
          // Auto-Invite Disconnected Peers
          _nearbyService.invitePeer(deviceID: device.deviceId, deviceName: device.deviceName);
        }
      }
    });

    // 2. Data Listener
    _dataSubscription = _nearbyService.dataReceivedSubscription(callback: (data) {
       try {
         final str = String.fromCharCodes(data['message']); // Uint8List? 
         onDebugLog?.call("RX P2P from ${data['deviceId']}: $str");
         final json = jsonDecode(str);
         onDataReceived?.call(json);
       } catch (e) {
         print("P2P Parse Error: $e");
       }
    });

    // 3. Start Browsing (Looking for peers)
    _browserSubscription = _nearbyService.startBrowsingForPeers().listen((event) {
        // Just listening keeps browsing active
    });

    // 4. Start Advertising (Being visible)
    _advertiserSubscription = _nearbyService.startAdvertisingPeer().listen((event) {
        // Just listening keeps advertising active
    });
  }

  void broadcastMessage(Map<String, dynamic> data) {
    if (connectedDevices.isEmpty) {
      onDebugLog?.call("⚠️ No Peers Connected. Broadcasting via UDP (Fallback)? No, P2P Mode active.");
      return;
    }

    final jsonStr = jsonEncode(data);
    for (var device in connectedDevices) {
      if (device.state == SessionState.connected) {
         _nearbyService.sendMessage(device.deviceId, jsonStr);
      }
    }
    onDebugLog?.call("TX P2P (x${connectedDevices.length}): $jsonStr");
  }

  void stopMesh() {
    isMeshActive = false;
    _stateSubscription?.cancel();
    _browserSubscription?.cancel();
    _advertiserSubscription?.cancel();
    _dataSubscription?.cancel();
    _nearbyService.stopAdvertisingPeer();
    _nearbyService.stopBrowsingForPeers();
  }
}
