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


