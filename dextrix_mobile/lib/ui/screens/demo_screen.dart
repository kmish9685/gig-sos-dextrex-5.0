import 'package:flutter/material.dart';

class DemoScreen extends StatelessWidget {
  const DemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demo Control Panel')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Simulate Crash'),
            onTap: () {
              // TODO: Trigger crash logic
            },
          ),
          ListTile(
            title: const Text('Simulate Incoming SOS'),
            onTap: () {
              // TODO: Trigger mesh receive logic
            },
          ),
          SwitchListTile(
            title: const Text('God Mode (Override Sensors)'),
            value: false,
            onChanged: (val) {},
          ),
        ],
      ),
    );
  }
}
