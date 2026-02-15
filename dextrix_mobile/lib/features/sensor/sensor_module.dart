/// Core Sensor Module Interface
/// Responsible for device movement monitoring and crash detection.
abstract class SensorModule {
  /// Stream of accelerometer events (x, y, z).
  Stream<List<double>> get accelerometerStream;

  /// Stream that emits when a crash is detected.
  /// Returns the G-force magnitude that triggered it.
  Stream<double> get crashDetectionStream;

  /// Starts listening to sensors.
  Future<void> startMonitoring();

  /// Stops listening to sensors to save battery.
  Future<void> stopMonitoring();

  /// Manually triggers a "crash" event for demo purposes.
  void simulateCrash();
}

/// Implementation stub for SensorModule
class SensorService implements SensorModule {
  @override
  Stream<List<double>> get accelerometerStream => Stream.empty(); // TODO: Implement

  @override
  Stream<double> get crashDetectionStream => Stream.empty(); // TODO: Implement

  @override
  Future<void> startMonitoring() async {
    // TODO: Initialize sensors
  }

  @override
  Future<void> stopMonitoring() async {
    // TODO: Dispose sensors
  }

  @override
  void simulateCrash() {
    // TODO: Emit event to stream
  }
}
