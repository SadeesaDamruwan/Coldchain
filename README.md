Since you've built a full-stack IoT solution with **Flutter**, **Firebase**, and **ESP32**—and even navigated the tricky waters of **Xcode** and **Gradle** configurations—your README should reflect the technical depth of the project.

Here is a professional, comprehensive `README.md` for **ColdChain**.

---

# 🧊 ColdChain: IoT Smart Cold Chain Monitor

**ColdChain** is a real-time logistics monitoring solution designed to track temperature and humidity for sensitive cargo (vaccines, food, chemicals). It utilizes an ESP32 hardware unit to stream environmental data to a Flutter mobile dashboard via Firebase, providing instant alerts for environmental breaches.

## 🚀 Key Features

* **Real-time Dashboard:** Live temperature and humidity streaming with dynamic status indicators (Safe, Warning, Critical).
* **Smart Alerts:** Instant push notifications triggered by hardware sensors (DHT11/22 and Magnetic Door Switch).
* **Shipment Management:** Easily add and categorize containers with unique IDs and starting locations.
* **Animated UI:** Smooth transitions and custom-built splash screens for a premium user experience.
* **Cross-Platform:** Optimized for both iOS (via CocoaPods/APNs) and Android (via Gradle/FCM).

---

## 🛠 Tech Stack

### Mobile Application
* **Framework:** Flutter (Dart)
* **State Management:** StatefulWidgets with StreamBuilder for real-time sync.
* **Navigation:** Custom bottom navigation architecture.

### Backend & Cloud
* **Database:** * **Cloud Firestore:** Stores container metadata and current status.
    * **Realtime Database:** Handles high-frequency telemetry from IoT devices.
* **Functions:** Node.js Cloud Functions for processing telemetry and sending FCM notifications.
* **Auth:** Firebase Database Secrets for secure hardware communication.

### Hardware (IoT)
* **Microcontroller:** ESP32 / Arduino
* **Sensors:** * **DHT11/22:** Temperature and Humidity.
    * **Magnetic Reed Switch:** Detects unauthorized container door opening.

---

## ⚙️ Setup & Installation

### 1. Flutter Mobile App
1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/coldchain.git
    ```
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Android Configuration:**
    * Place `google-services.json` in `android/app/`.
    * Enable **Core Library Desugaring** in `build.gradle.kts`.
4.  **iOS Configuration:**
    * Place `GoogleService-Info.plist` in `ios/Runner/`.
    * Run `pod install` in the `ios` directory.

### 2. Firebase Configuration
* Enable **Firestore** and **Realtime Database**.
* **Rules:** Ensure your database rules allow read/write access for your prototype.
* **Messaging:** Set up **FCM (Android)** and **APNs (iOS)** for push notifications.

### 3. ESP32 Hardware
1.  Open the `.ino` file in Arduino IDE.
2.  Install `Firebase ESP32 Client` and `DHT sensor library`.
3.  Update the `WIFI_SSID`, `WIFI_PASSWORD`, and `FIREBASE_AUTH` secret.
4.  Upload to your ESP32.

---

## 📁 Project Structure

```text
lib/
├── models/          # Data blueprints (ContainerModel)
├── screens/         # UI Screens (Dashboard, Shipments, Alerts)
├── services/        # Firebase & Notification logic
└── main.dart        # App entry point & initialization
android/             # Optimized Gradle & Proguard settings
ios/                 # CocoaPods & APNs configuration
```

---

## ⚠️ Known Build Fixes

If you encounter the **Kotlin Daemon** or **Xcode hanging** errors during build:
* **Android:** Increase JVM memory in `gradle.properties` (`-Xmx2048m`).
* **iOS:** Ensure `BoringSSL` is linked properly and avoid using the "Track" feature if building on low-resource machines to save RAM during compilation.

---

## 👨‍💻 Author
**Mahadurage Sadeesa Damruwan** *Student ID: 10965346* *NSBM Green University / Plymouth University Partnership*

---

### How to use this:
1.  Create a new file in your project root named `README.md`.
2.  Paste the content above.
3.  Replace the `your-username` link with your actual GitHub link.
