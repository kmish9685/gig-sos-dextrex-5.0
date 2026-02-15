import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Alerts')),
      body: const Center(
        child: Text('Map View Placeholder\n(Use flutter_map or google_maps_flutter)'),
      ),
    );
  }
}
