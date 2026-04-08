# 🕌 Adhani - Islamic Prayer Times App

<div align="center">
  <img src="assets/mainIcon.png" width="150" alt="Adhani Logo">
  <br/>
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.7.2+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
  [![Kotlin](https://img.shields.io/badge/Kotlin-Native_Android-7F52FF?style=for-the-badge&logo=kotlin&logoColor=white)](https://kotlinlang.org)
</div>

## 📖 About
**Adhani** is a comprehensive, beautifully designed Islamic app built with Flutter. It provides accurate, location-based prayer times, a dynamic Qibla compass, localized Adhan (call to prayer) notifications, and a robust Android background countdown service. 

Designed for reliability, Adhani utilizes extensive native Kotlin code on Android to ensure that Adhan alarms and prayer countdowns trigger flawlessly, even when the application is completely killed or the device is rebooted.

## ✨ Features
- **🌍 Accurate Prayer Times:** Calculates exact daily prayer timings locally using device coordinates (via the `adhan` library) or falling back to the Aladhan API.
- **🧭 Qibla Compass:** A smooth, responsive compass pointing to Mecca using native device sensors and high-quality SVGs.
- **⏱️ Persistent Countdown Service:** A live, persistent background notification on Android showing the countdown to the next prayer, seamlessly transitioning between days.
- **🔔 Reliable Adhan Alarms:** Custom Android background workers, alarm schedulers, and receivers guarantee Adhan audio plays accurately in the background seamlessly.
- **🌙 Audio Playback:** High-quality background Adhan audio playback when prayer times arrive.
- **🔄 Auto-Resume on Boot:** Automatically re-schedules pending prayer notifications when the device restarts.

## 🛠️ Tech Stack & Technologies
### Frontend (Flutter)
- **State Management:** [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod)
- **Prayer Algorithms:** [`adhan`](https://pub.dev/packages/adhan)
- **Location Services:** [`geolocator`](https://pub.dev/packages/geolocator) & [`geocoding`](https://pub.dev/packages/geocoding)
- **Qibla Direction:** [`flutter_qiblah`](https://pub.dev/packages/flutter_qiblah)
- **Audio:** [`just_audio`](https://pub.dev/packages/just_audio)
- **Storage:** [`shared_preferences`](https://pub.dev/packages/shared_preferences)
- **Local Notifications:** [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications)
- **Assets/UI:** `flutter_svg`, Cairo & modern typography, SVG graphics.

### Native Android (Kotlin)
The app features deep Android integration to bypass typical battery optimization constraints:
- **`PrayerCountdownService`**: Foreground service for continuous live countdowns.
- **`PrayerUpdateWorker`**: WorkManager implementation to sync times in the background.
- **`AdhanAlarmService` & `AdhdanPlayer`**: Native media playback handling dedicated to alarms.
- **`AlarmSchedulerHelper` & `BootReceiver`**: Handling precise `AlarmManager` scheduling and restoring alarms on boot.

## 📂 Project Structure
```text
Adhanuk/
├── android/app/src/main/kotlin/...
│   └── com/example/myadhan/       # 🚀 Heavy native Kotlin backend for services, receivers, workers
├── assets/                        # 🖼️ Images, icons, audio effects, and compass SVGs
├── lib/
│   ├── controller/                # 🧠 Application logic and coordination
│   ├── model/                     # 📦 Data structures and API models
│   ├── providers/                 # 💧 Riverpod state management providers
│   ├── services/                  # 🔌 Dart wrappers for APIs, Location, Adhan Logic
│   └── view/                      # 🎨 UI Screens, Widgets, and Layouts
└── pubspec.yaml                   # 📜 Dependencies & Configurations
```

## 📸 Screenshots


| Home Dashboard | Qibla Compass | Settings / Preferences | Active Notification |
|:---:|:---:|:---:|:---:|

| <img width="412" height="917" alt="home" src="https://github.com/user-attachments/assets/7af0c2a4-e038-441b-b7c2-208165dbd679" /> | <img width="412" height="917" alt="compass" src="https://github.com/user-attachments/assets/ddc2f61b-c534-4069-b469-473760e41c7e" /> | <img src="placeholder_path/settings.png" width="200"/> | <img width="412" height="917" alt="prayerTimeList" src="https://github.com/user-attachments/assets/9207f318-b1ca-4633-b55d-c2d7eec5aa09" /> |

## 🚀 Setup & Installation

Follow these steps to run the app locally.

### Prerequisites
- Flutter SDK (v3.7.2 or higher constraint)
- Dart SDK
- Android Studio / Xcode configured with an emulator or physical device.

### Installation
1. **Clone the repository**
   ```bash
   git clone https://github.com/ki1lux/Adhanuk.git
   cd Adhanuk
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Environment / API Setup**
   - *Note: Adhani fetches real-time prayer calculations either locally via the `adhan` Dart package or the free [Aladhan API](https://aladhan.com/). No custom `.env` file or API key is required to be configured locally.*

4. **Run the Application**
   ```bash
   flutter run
   ```
   *(For testing native background features, it is highly recommended to test on a physical Android device!)*

## 🤝 Contributing
Contributions, issues, and feature requests are welcome! Feel free to check the issues page.

---
**Made with ❤️ using Flutter & Kotlin.**
