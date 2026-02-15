import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:rxdart/rxdart.dart';
import 'sensor_module.dart';

/// Implementation of SensorModule using sensors_plus package.
class SensorService implements SensorModule {
  final _crashController = StreamController<double>.broadcast();
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  
  // Configuration
  static const double CRASH_THRESHOLD_G = 3.5; // Trigger at 2.5G (approx 24.5 m/s^2)
  static const double GRAVITY = 9.81;
  static const int DETECTION_WINDOW_MS = 200;

  @override
  Stream<List<double>> get accelerometerStream => 
      accelerometerEvents.map((event) => [event.x, event.y, event.z]);

  @override
  Stream<double> get crashDetectionStream => _crashController.stream;

  @override
  Future<void> startMonitoring() async {
    if (_accelSubscription != null) return;
    
    // We use a simple window or direct threshold for now.
    // In a real app, we'd use a sliding window average to reduce noise.
    _accelSubscription = accelerometerEvents.listen((event) {
      _analyzeSensorData(event);
    });
  }

  @override
  Future<void> stopMonitoring() async {
    await _accelSubscription?.cancel();
    _accelSubscription = null;
  }

  @override
  void simulateCrash() {
    _crashController.add(5.0); // Simulate a 5G impact
    print("[SensorService] Simulated Crash Triggered!");
  }

  void _analyzeSensorData(AccelerometerEvent event) {
    // Calculate total G-force magnitude
    final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    final gForce = magnitude / GRAVITY;

    if (gForce > CRASH_THRESHOLD_G) {
      // Simple debounce could be added here if needed
      // preventing multiple triggers for the same crash
       _crashController.add(gForce);
       print("[SensorService] CRASH DETECTED! Force: ${gForce.toStringAsFixed(2)}G");
    }
  }
}
