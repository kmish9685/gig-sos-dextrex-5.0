/// Emergency State Manager Interface
/// Responsible for maintaining the "Single Source of Truth" for app safety status.

enum AppSafetyState {
  idle,            // Normal operation
  preAlert,        // Crash detected, countdown running
  sosActive,       // Emitting SOS signal
  sosReceived,     // Received SOS from peer
  relaying,        // Forwarding another SOS (Mesh node)
}

abstract class EmergencyModule {
  /// Current safety state of the app.
  Stream<AppSafetyState> get stateStream;

  /// Starts the emergency sequence (usually from sensor trigger).
  void triggerEmergency();

  /// Cancels an active countdown or SOS.
  void cancelEmergency();

  /// Acknowledges receiving an alert and prepares to help.
  void acknowledgeAlert(String alertId);

  /// Relay an alert to others (become a mesh node).
  void relayAlert(String alertId);
}


