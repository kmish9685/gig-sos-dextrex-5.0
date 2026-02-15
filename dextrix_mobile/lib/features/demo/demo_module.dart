/// Demo / God Mode Controller Interface
/// Responsible for forcing app states to allow non-destructive testing.

abstract class DemoModule {
  /// Toggle "God Mode" (enables manual overrides).
  bool get isGodModeEnabled;

  /// Force the app into a specific state.
  void forceState(String stateName);

  /// Simulate losing network connectivity.
  void toggleNetworkSimulation(bool isOnline);

  /// Inject a fake peer into the mesh.
  void injectFakePeer(String deviceId);
}


