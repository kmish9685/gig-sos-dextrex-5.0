import 'package:flutter/foundation.dart';

class DemoEmergencyService extends ChangeNotifier {
  static final DemoEmergencyService instance = DemoEmergencyService._();
  DemoEmergencyService._();

  bool meshActive = false;
  bool emergencyActive = false;
  List<String> nearbyRiders = [];

  void startMesh() {
    print("DemoEmergencyService: Starting Mesh...");
    meshActive = true;
    notifyListeners();

    Future.delayed(const Duration(seconds: 2), () {
      nearbyRiders = ["Rider Amit", "Rider Rahul", "Rider Sana"];
      print("DemoEmergencyService: Riders Found: $nearbyRiders");
      notifyListeners();
    });
  }

  void stopMesh() {
    meshActive = false;
    nearbyRiders = [];
    notifyListeners();
  }

  void simulateCrash() {
    print("DemoEmergencyService: Crash Simulated!");
    emergencyActive = true;
    notifyListeners();
  }

  void cancelEmergency() {
    print("DemoEmergencyService: Emergency Cancelled.");
    emergencyActive = false;
    notifyListeners();
  }
}
