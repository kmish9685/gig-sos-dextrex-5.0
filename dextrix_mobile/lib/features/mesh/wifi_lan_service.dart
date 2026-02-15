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

  void stopListening() {
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

  void _send(Map<String, dynamic> data) {
    try {
      final jsonStr = jsonEncode(data);
      final bytes = utf8.encode(jsonStr);
      // Send to Global Broadcast Address
      int sent = _socket?.send(bytes, InternetAddress('255.255.255.255'), PORT) ?? 0;
      print("[WifiLanService] Bytes sent: $sent | Payload: $jsonStr");
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
