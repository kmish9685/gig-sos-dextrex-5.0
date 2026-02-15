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

class EmergencyService implements EmergencyModule {
  @override
  Stream<AppSafetyState> get stateStream => Stream.value(AppSafetyState.idle); // TODO: Implement

  @override
  void triggerEmergency() {
    // TODO: Transition to preAlert
  }

  @override
  void cancelEmergency() {
    // TODO: Revert to idle
  }

  @override
  void acknowledgeAlert(String alertId) {
    // TODO: Update UI/Log
  }

  @override
  void relayAlert(String alertId) {
    // TODO: Activate mesh relay
  }
}
