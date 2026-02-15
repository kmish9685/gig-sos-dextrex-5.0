# Dextrix 5.0 — Offline Mesh SOS Network 🚀

**"When networks fail, riders don't."**

Dextrix is an offline-first emergency response system designed for gig riders operating in network dead zones. It uses device-to-device mesh networking to propagate SOS alerts without internet connectivity.

## 📱 Core Features (Hackathon MVP)

*   **⚠️ Automatic Crash Detection**: Uses accelerometer data to detect high-impact falls (>2.5G).
*   **📡 Offline Mesh Networking**: Simulates peer discovery and message propagation using local Wi-Fi/Bluetooth protocols (Simulated for Demo Stability).
*   **🆘 Instant SOS Broadcasting**: One-tap activation or auto-trigger after a 5-second countdown.
*   **🛡️ Cancellation Window**: Prevents false alarms with a "I AM SAFE" override.
*   **📍 Breadcrumb Tracking**: Shares last known GPS coordinates with nearby peers.

## 🛠 Tech Stack

*   **Framework**: Flutter (Dart)
*   **State Management**: Singleton Service Architecture (for robust demo control)
*   **Sensors**: `sensors_plus` (Accelerometer polling)
*   **Navigation**: Navigator 2.0 (MaterialApp)

## 🎬 How to Run the Demo (Judge's Guide)

Since actual hardware mesh networking is unstable in crowded hackathon venues, Dextrix includes a **"Real Mode Simulation"** that guarantees a flawless demo.

### 1. Setup
*   Install the APK on 2 devices (Device A & Device B).
*   Turn OFF WiFi/Data (Airplane Mode optional but recommended for effect).

### 2. The Flow
1.  **Activate Mesh**: Tap **"ACTIVATE MESH NETWORK"** on both phones.
2.  **Discovery**: On Device A, tap the **Settings Icon (⚙️)** -> Tap **"+ Rider Amit"**. (Simulates finding a peer).
3.  **Crash**: Shake Device A vigorously OR use **Settings -> Force Hardware Crash**.
4.  **SOS**: Device A shows "CRASH DETECTED" -> 5s Countdown -> "BROADCASTING SOS".
5.  **Alert**: On Device B (Responder), go to **Settings -> Simulate SOS from "Rider Kuldeep"**.
6.  **Result**: Device B flashes RED with an "INCOMING SOS" alert.

## 👨‍💻 Developer Notes

*   **Architecture**: The app uses a `DemoEmergencyService` singleton to manage all safety-critical states (`meshActive`, `emergencyActive`) to ensure instant UI reactivity during the pitch.
*   **Sensor Logic**: The `SensorService` listens to the accelerometer stream. A spike >2.9G triggers the crash flow.
