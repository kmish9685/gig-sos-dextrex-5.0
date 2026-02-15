import 'package:flutter/material.dart';
import '../../features/demo/demo_emergency_service.dart';

class SignalMonitorScreen extends StatelessWidget {
  const SignalMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📡 Signal Matrix"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.greenAccent,
      ),
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: DemoEmergencyService.instance,
        builder: (context, child) {
          final logs = DemoEmergencyService.instance.packetLog;
          
          if (logs.isEmpty) {
            return const Center(child: Text("Scanning for Signals...", style: TextStyle(color: Colors.white30)));
          }

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final isTx = log.contains("TX:");
              final isRx = log.contains("RX:");
              final isError = log.contains("Error");

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isTx ? Colors.blue.withOpacity(0.1) : (isError ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1)),
                  border: Border(left: BorderSide(
                    width: 3, 
                    color: isTx ? Colors.blue : (isError ? Colors.red : Colors.greenAccent)
                  ))
                ),
                child: Text(
                  log,
                  style: const TextStyle(fontFamily: 'Courier', fontSize: 12, color: Colors.white),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
