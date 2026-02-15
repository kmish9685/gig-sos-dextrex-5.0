/// Map & Visualization Module Interface
/// Responsible for location tracking and rendering alerts on a map.

abstract class MapModule {
  /// Stream of current user location.
  Stream<Map<String, double>> get locationStream; // {lat, lng}

  /// List of active alerts to display on map.
  Stream<List<Map<String, dynamic>>> get activeAlertsStream;

  /// Start tracking location (for breadcrumbs).
  Future<void> startTracking();

  /// Stop tracking location.
  Future<void> stopTracking();

  /// Add a simulated alert marker for demo.
  void addSimulatedAlert(double lat, double lng);
}

class MapService implements MapModule {
  @override
  Stream<Map<String, double>> get locationStream => Stream.empty(); // TODO: Implement

  @override
  Stream<List<Map<String, dynamic>>> get activeAlertsStream => Stream.empty(); // TODO: Implement

  @override
  Future<void> startTracking() async {
    // TODO: Init location services
  }

  @override
  Future<void> stopTracking() async {
    // TODO: Stop location services
  }

  @override
  void addSimulatedAlert(double lat, double lng) {
    // TODO: Add to local state
  }
}
