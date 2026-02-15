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
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, PORT);
      _socket?.broadcastEnabled = true;
      _isListening = true;
      print("[WifiLanService] Listening on port $PORT");

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

  void stopListening() {
    _socket?.close();
    _isListening = false;
    _socket = null;
  }

  void broadcastMessage(Map<String, dynamic> data) {
    if (_socket == null) {
      print("[WifiLanService] Socket not ready. Rebinding...");
      startListening().then((_) => _send(data));
    } else {
      _send(data);
    }
  }

  void _send(Map<String, dynamic> data) {
    try {
      final jsonStr = jsonEncode(data);
      final bytes = utf8.encode(jsonStr);
      _socket?.send(bytes, InternetAddress('255.255.255.255', type: InternetAddressType.IPv4), PORT);
      print("[WifiLanService] Broadcast sent: $jsonStr");
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
