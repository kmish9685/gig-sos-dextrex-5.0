import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'mesh_provider.dart';

class NearbyMeshProvider implements MeshProvider {
  final Strategy _strategy = Strategy.P2P_CLUSTER;
  String _userName = "Rider-${Random().nextInt(1000)}";
  
  final _peersController = StreamController<List<String>>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  
  // Track connected endpoints
  final Map<String, String> _connectedEndpoints = {}; // endpointId -> endpointName

  @override
  Stream<List<String>> get peersStream => _peersController.stream;

  @override
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  @override
  Future<void> startDiscovery() async {
    print("[NearbyMesh] Requesting Permissions...");
    if (!await _checkPermissions()) {
      print("[NearbyMesh] Permissions denied!");
      return;
    }

    _userName = await _getDeviceName();
    print("[NearbyMesh] Starting Mesh as $_userName");

    try {
      // 1. Start Advertising (Be discoverable)
      await Nearby().startAdvertising(
        _userName,
        _strategy,
        onConnectionInitiated: (id, info) {
          print("[NearbyMesh] Connection Initiated by ${info.endpointName} ($id)");
          _acceptConnection(id);
        },
        onConnectionResult: (id, status) {
          print("[NearbyMesh] Connection Result for $id: $status");
          if (status == Status.CONNECTED) {
             // Add to list, but we don't have name here easily unless we stored it from initiated
             // For now, allow discovery to handle listing
          }
        },
        onDisconnected: (id) {
          print("[NearbyMesh] Disconnected: $id");
          _connectedEndpoints.remove(id);
          _peersController.add(_connectedEndpoints.values.toList());
        },
      );

      // 2. Start Discovery (Find others)
      await Nearby().startDiscovery(
        _userName,
        _strategy,
        onEndpointFound: (id, name, serviceId) {
          print("[NearbyMesh] Found Endpoint: $name ($id)");
          // Auto-connect for Mesh
          Nearby().requestConnection(
            _userName,
            id,
            onConnectionInitiated: (id, info) => _acceptConnection(id),
            onConnectionResult: (id, status) {
              if (status == Status.CONNECTED) {
                _connectedEndpoints[id] = name;
                _peersController.add(_connectedEndpoints.values.toList());
              }
            },
            onDisconnected: (id) {
               _connectedEndpoints.remove(id);
               _peersController.add(_connectedEndpoints.values.toList());
            },
          );
        },
        onEndpointLost: (id) {
          print("[NearbyMesh] Lost Endpoint: $id");
        },
      );
      
    } catch (e) {
      print("[NearbyMesh] Error starting mesh: $e");
    }
  }

  Future<void> _acceptConnection(String id) async {
    await Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endId, payload) {
        if (payload.type == PayloadType.BYTES) {
          final bytes = payload.bytes!;
          final str = utf8.decode(bytes);
          print("[NearbyMesh] Received from $endId: $str");
          try {
            final data = jsonDecode(str);
            _messageController.add(data);
          } catch (e) {
            print("[NearbyMesh] Failed to parse JSON: $e");
          }
        }
      },
    );
  }

  @override
  Future<void> stopDiscovery() async {
    await Nearby().stopAdvertising();
    await Nearby().stopDiscovery();
    await Nearby().stopAllEndpoints();
    _connectedEndpoints.clear();
    print("[NearbyMesh] Mesh Stopped.");
  }

  @override
  Future<void> broadcast(Map<String, dynamic> payload) async {
    final msg = jsonEncode(payload);
    final bytes = utf8.encode(msg);
    
    // Send to ALL connected endpoints
    if (_connectedEndpoints.isEmpty) {
        print("[NearbyMesh] No peers connected to broadcast to!");
        return;
    }
    
    // Nearby Connections sends to list
    // Warning: PayloadID is auto-generated usually
    try {
        await Nearby().sendBytesPayload(
            _connectedEndpoints.keys.toList(), 
            Uint8List.fromList(bytes)
        );
        print("[NearbyMesh] Broadcast sent to ${_connectedEndpoints.length} peers.");
    } catch (e) {
        print("[NearbyMesh] Broadcast failed: $e");
    }
  }

  Future<bool> _checkPermissions() async {
    // Android 12+ requires specific permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.nearbyWifiDevices,
    ].request();
    
    return statuses.values.every((status) => status.isGranted);
  }
  
  Future<String> _getDeviceName() async {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      // Simple random name for anonymous safety or use model
      // return "Rider-${(await deviceInfo.androidInfo).model}";
      return "Rider-${Random().nextInt(999)}";
  }
}
