import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/demo/demo_controller.dart';
import '../../features/sensor/sensor_module.dart';
import '../../features/mesh/mesh_module.dart';

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  final List<String> _logs = [];

  void _addLog(String log) {
    if (mounted) {
      setState(() {
        _logs.insert(0, "${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second} - $log");
        if (_logs.length > 50) _logs.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access controllers
    final demoCtrl = Provider.of<DemoController>(context, listen: false);
    final sensorModule = Provider.of<SensorModule>(context, listen: false);
    final meshModule = Provider.of<MeshModule>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Validation Dashboard')),
      body: Column(
        children: [
          // 1. Controls Section
          ExpansionTile(
            title: const Text("Controls", style: TextStyle(fontWeight: FontWeight.bold)),
            initiallyExpanded: true,
            children: [
               ListTile(
                leading: const Icon(Icons.wifi_tethering),
                title: const Text('1. Start Mesh (Both Phones)'),
                subtitle: const Text('Advertises & Scans automatically'),
                onTap: () {
                   demoCtrl.startMesh();
                   _addLog("Mesh Started...");
                },
              ),
              ListTile(
                leading: const Icon(Icons.vibration),
                title: const Text('2. Trigger Crash (Phone A)'),
                subtitle: const Text('Simulates >2.9G Impact'),
                onTap: () {
                   sensorModule.simulateCrash();
                   _addLog("Manual Crash Triggered!");
                },
              ),
            ],
          ),
          
          const Divider(thickness: 2),
          
          // 2. Peers Section
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Connected Peers (Mesh)", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            height: 100,
            child: StreamBuilder<List<String>>(
              stream: meshModule.peersStream,
              initialData: const [],
              builder: (context, snapshot) {
                final peers = snapshot.data ?? [];
                if (peers.isEmpty) {
                  return const Center(child: Text("No peers connected.\n(Start Mesh on both devices)", textAlign: TextAlign.center));
                }
                return ListView.builder(
                  itemCount: peers.length,
                  itemBuilder: (context, index) => Card(
                    color: Colors.green.withOpacity(0.2),
                    child: ListTile(
                      leading: const Icon(Icons.phone_android),
                      title: Text(peers[index]),
                      trailing: const Icon(Icons.check_circle, color: Colors.green),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const Divider(thickness: 2),
          
          // 3. Logs / Messages Section
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Live Logs & Messages", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: StreamBuilder<Map<String, dynamic>>(
              stream: meshModule.messageStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  // Side effect in build is bad practice usually, but for simple debug dashboard it's okay-ish
                  // or better, wrap in a listener widget. For now, we rely on the list view below updating
                  // when we set state from outside?
                  // Actually, let's just use a listener in initState ideally. 
                  // But to keep it simple, we'll just show the latest snapshot here 
                  // and use a separate text for history if we were listening properly.
                  
                  // For this hackathon widget, let's just listen to the stream in initState.
                  return Container(); 
                }
                return Container();
              },
            ),
          ),
          
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.black12,
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                   return Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                     child: Text(_logs[index], style: const TextStyle(fontFamily: "monospace", fontSize: 12)),
                   );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Listen to mesh messages to add to log
    final meshModule = Provider.of<MeshModule>(context, listen: false);
    meshModule.messageStream.listen((msg) {
      _addLog("RECEIVED SOS: ${msg['device_id']}");
      _startAlarm();
    });
    
    // Listen to internal sensor logs (not exposed via stream easily without refactor)
    // We already log via print();
  }
  
  void _startAlarm() {
    // Visual alarm
    showDialog(
      context: context, 
      builder: (_) => AlertDialog(
        backgroundColor: Colors.red,
        title: const Text("SOS RECEIVED!", style: TextStyle(color: Colors.white)),
        content: const Icon(Icons.warning, size: 80, color: Colors.white),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("ACKNOWLEDGE", style: TextStyle(color: Colors.white))
          )
        ],
      )
    );
  }
}
