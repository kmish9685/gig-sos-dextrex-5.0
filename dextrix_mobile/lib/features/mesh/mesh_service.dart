import 'dart:async';
import 'mesh_module.dart';
import 'mesh_provider.dart';
import 'simulated_mesh_provider.dart';

class MeshService implements MeshModule {
  final MeshProvider _provider;

  MeshService({MeshProvider? provider}) 
      : _provider = provider ?? SimulatedMeshProvider();

  @override
  Stream<List<String>> get peersStream => _provider.peersStream;

  @override
  Stream<Map<String, dynamic>> get messageStream => _provider.messageStream;

  @override
  Future<void> startDiscovery() async {
    await _provider.startDiscovery();
  }

  @override
  Future<void> stopDiscovery() async {
    await _provider.stopDiscovery();
  }

  @override
  Future<void> broadcastMessage(Map<String, dynamic> payload) async {
    await _provider.broadcast(payload);
  }

  @override
  Future<void> connectToPeer(String peerId) async {
    // Connection logic often handled automatically in mesh,
    // but specific direct connection can be implemented here.
    print("[MeshService] Connecting to $peerId...");
  }
  
  MeshProvider get provider => _provider;
}
