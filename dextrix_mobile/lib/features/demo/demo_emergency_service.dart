import 'package:flutter/foundation.dart';

class DemoEmergencyService extends ChangeNotifier {
  static final DemoEmergencyService instance = DemoEmergencyService._();
  DemoEmergencyService._();

  bool meshActive = false;
  bool emergencyActive = false;
  bool scanning = false;
  List<String> nearbyRiders = [];

  void startMesh() {
    print("DemoEmergencyService: Mesh Started. Scanning...");
    meshActive = true;
    scanning = true;
    nearbyRiders.clear(); // Reset on new scan
    notifyListeners();
    
    // In Real Mode: We wait for actual discovery or manual injection
  }

  void stopMesh() {
    meshActive = false;
    scanning = false;
    nearbyRiders.clear();
    notifyListeners();
  }

  // Judge Control: Manually inject a rider to simulate real network discovery
  void injectDiscoveredRider(String name) {
    if (!meshActive) return;
    
    print("DemoEmergencyService: Discovered Peer - $name");
    if (!nearbyRiders.contains(name)) {
      nearbyRiders.add(name);
      scanning = false; // Found someone, so we can show list (or keep scanning true if we want continuous)
      // Let's keep scanning true if we want "Scanning..." to act as a status, 
      // but usually if we have a list, we show the list. 
      // User asked: "UI shows: Scanning... If riders exist -> show list". 
      // So we can deduce: if list not empty, show list. 
      notifyListeners();
    }
  }

  void simulateCrash() {
    print("DemoEmergencyService: Crash Logic Triggered!");
    emergencyActive = true;
    notifyListeners();
  }

  void cancelEmergency() {
    print("DemoEmergencyService: Emergency Cancelled/Resolved.");
    emergencyActive = false;
    notifyListeners();
  }
}
