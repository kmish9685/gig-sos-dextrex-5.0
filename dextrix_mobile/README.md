# Dextrix 5.0 Mobile App

## Setup
1. Ensure Flutter SDK is installed.
2. Run `flutter pub get` to install dependencies (list them in pubspec.yaml).
3. Connect an Android device (required for WiFi Direct/BLE).
4. Run `flutter run`.

## Structure
- `lib/features/`: Contains core logic modules (Sensor, Mesh, Emergency).
- `lib/ui/`: Contains screens and widgets.
- `lib/data/`: Data layer (Repositories, Models).

## Key Modules
- **Sensor**: Handles accelerometer and crash detection.
- **Mesh**: Handles P2P communication (BLE/WiFi Direct).
- **Emergency**: Manages the app's safety state.

## Demo Mode
To test without physical crashes, use the Demo Screen to simulate events.
