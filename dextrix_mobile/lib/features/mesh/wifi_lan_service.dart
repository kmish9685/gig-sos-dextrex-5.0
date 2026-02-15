import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';

class WifiLanService {
  static final WifiLanService instance = WifiLanService._();
  WifiLanService._();

  RawDatagramSocket? _socket;
  static const int PORT = 4555; // Custom port for Dextrix
  bool _isListening = false;

  void Function(Map<String, dynamic> data)? onDataReceived;

  Future<void> startListening() async {
    if (_isListening) return;

    try {
      // Bind to Any (0.0.0.0) allows receiving broadcasts
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, PORT, reuseAddress: true);
      _socket?.broadcastEnabled = true;
      _isListening = true;
      print("[WifiLanService] Listening on 0.0.0.0:$PORT");

      _socket?.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket?.receive();
          if (datagram != null) {
            _handleIncomingPacket(datagram);
          }
        }
      });
    } catch (e) {
      print("[WifiLanService] Error binding socket: $e");
    }
  }

  Timer? _broadcastTimer;

  // ... (existing code)

  void startBroadcastingPresence(Map<String, dynamic> packet) {
    _broadcastTimer?.cancel();
    _broadcastTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      // Add dynamic timestamp to avoid deduplication if needed
      final p = Map<String, dynamic>.from(packet);
      // p['ts'] = DateTime.now().millisecondsSinceEpoch; 
      broadcastMessage(p);
    });
    print("[WifiLanService] Started Presence Broadcast (Every 3s)");
  }

  void stopListening() {
    _broadcastTimer?.cancel();
    _socket?.close();
    _isListening = false;
    _socket = null;
  }

  void broadcastMessage(Map<String, dynamic> data) async {
    if (_socket == null) {
      print("[WifiLanService] Socket not ready. Rebinding...");
      await startListening();
    }
    
    _send(data);
  }

  Future<String> _getBroadcastAddress() async {
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (final interface in interfaces) {
        // Look for typical LAN/Hotspot interfaces (wlan0, ap0, etc.)
        // or just take the first non-loopback
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
             final ip = addr.address; // e.g., 192.168.43.10
             final subnet = ip.substring(0, ip.lastIndexOf('.'));
             return '$subnet.255'; // Return 192.168.43.255
          }
        }
      }
    } catch (e) {
      print("[WifiLanService] IP Search Error: $e");
    }
    return '255.255.255.255'; // Fallback
  }

  void _send(Map<String, dynamic> data) async {
    try {
      final jsonStr = jsonEncode(data);
      final bytes = utf8.encode(jsonStr);
      
      final broadcastIP = await _getBroadcastAddress();
      print("[WifiLanService] Sending to $broadcastIP");

      _socket?.send(bytes, InternetAddress(broadcastIP), PORT);
      print("[WifiLanService] Bytes sent: $jsonStr");
    } catch (e) {
      print("[WifiLanService] Send error: $e");
    }
  }

  void _handleIncomingPacket(Datagram datagram) {
    try {
      final message = utf8.decode(datagram.data);
      final data = jsonDecode(message);
      
      // Filter out own messages if needed (by ID)
      // For Demo, we just pass everything up
      print("[WifiLanService] Received: $message from ${datagram.address.address}");
      
      onDataReceived?.call(data);
    } catch (e) {
      print("[WifiLanService] Parse error: $e");
    }
  }
}
