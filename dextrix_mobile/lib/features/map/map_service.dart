import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'map_module.dart';

class MapService implements MapModule {
  final _locationController = StreamController<Map<String, double>>.broadcast();
  // Using a list to store active alerts for the map
  final _activeAlertsController = StreamController<List<Map<String, dynamic>>>.broadcast();
  final List<Map<String, dynamic>> _localAlerts = [];
  
  StreamSubscription<Position>? _positionStream;

  @override
  Stream<Map<String, double>> get locationStream => _locationController.stream;

  @override
  Stream<List<Map<String, dynamic>>> get activeAlertsStream => _activeAlertsController.stream;

  @override
  Future<void> startTracking() async {
    // Check permissions
    if (await _checkPermission()) {
       _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
      ).listen((Position position) {
        _locationController.add({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': position.timestamp.millisecondsSinceEpoch.toDouble(),
        });
      });
    }
  }

  @override
  Future<void> stopTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;
  }

  @override
  void addSimulatedAlert(double lat, double lng) {
    print("[MapService] Adding simulated alert at $lat, $lng");
    final alert = {
      'id': 'sim-${DateTime.now().millisecondsSinceEpoch}',
      'latitude': lat,
      'longitude': lng,
      'type': 'simulated',
    };
    _localAlerts.add(alert);
    _activeAlertsController.add(List.from(_localAlerts));
  }
  
  Future<bool> _checkPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }
}
