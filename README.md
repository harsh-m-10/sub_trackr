# SubTrackr 📱

SubTrackr is a simple and powerful Flutter-based app to track your subscriptions, analyze your spending, and get timely reminders for upcoming renewals.

---

## ✨ Features

- 📋 Add & manage subscriptions with flexible billing cycles (weekly, monthly, yearly, or custom)
- 🔍 Scan installed apps and add subscriptions directly
- 📊 Visualize spending trends with pie charts and line graphs
- 🗓 View subscription spending for custom date ranges
- 🔔 Get notification reminders one day before renewals
- 💾 Offline-first: Data stored locally using Hive
- ⚡ Smooth, lightweight, and minimal UI

---

## 🛠 Tech Stack

- [Flutter](https://flutter.dev/) – Frontend framework
- [Hive](https://docs.hivedb.dev/) – Lightweight NoSQL database
- [Device Apps](https://pub.dev/packages/device_apps) – Fetch installed apps
- [FL Chart](https://pub.dev/packages/fl_chart) – Beautiful charts
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications) – Schedule local reminders

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK installed (>=3.0.0 recommended)
- Android Studio / VS Code with Flutter plugin
- Android device or emulator

### Setup Instructions

1. Clone the repository:

    ```bash
    git clone https://github.com/your-username/sub_trackr.git
    cd sub_trackr
    ```

2. Install dependencies:

    ```bash
    flutter pub get
    ```

3. Run the app:

    ```bash
    flutter run
    ```

4. To build the release APK (for distribution):

    ```bash
    flutter build apk --release
    ```

   The release APK will be available at:  
   `build/app/outputs/flutter-apk/app-release.apk`

## ⚙️ Permissions Required

- READ_INSTALLED_APPS – To scan and list installed apps
- POST_NOTIFICATIONS – To send subscription renewal notifications (Android 13+)
- Internet permission (default for Flutter apps)
- The app asks for necessary permissions at runtime when needed.

---

## 🛡 License

This project is licensed under the MIT License — you are free to use, modify, and distribute it.

---

## 📦 Folder Structure

```plaintext
lib/
│
├── db/
│   └── hive_boxes.dart       # Hive box utility
│
├── models/
│   └── subscription.dart     # Subscription data model
│
├── screens/
│   ├── add_subscription_screen.dart
│   ├── analytics_screen.dart
│   └── scan_apps_screen.dart
│
├── services/
│   └── notification_service.dart   # Notification handling
│
├── main.dart                  # App entry point
```
