# SubTrackr

A comprehensive Flutter-based subscription tracking application designed to help users manage their recurring app subscriptions, analyze spending patterns, and receive timely renewal reminders.

## Overview

SubTrackr is a privacy-focused, offline-first subscription management app that allows users to track their app subscriptions, visualize spending patterns, and get smart reminders for upcoming renewals. Built with Flutter, it provides a smooth, responsive experience across different device sizes.

## Features

### Core Functionality
- **Subscription Management**: Add, edit, and delete subscriptions with flexible billing cycles
- **Smart App Scanning**: Automatically detect installed apps and suggest subscription additions
- **Multi-Currency Support**: Track subscriptions in 11+ currencies with real-time conversion
- **Advanced Analytics**: Visualize spending patterns with interactive charts and insights
- **Smart Notifications**: Configurable reminder system for upcoming renewals
- **Data Export**: Export subscription data in CSV and JSON formats

### Technical Features
- **Offline-First**: All data stored locally using Hive database
- **Privacy-Focused**: No cloud sync, complete user data control
- **Responsive Design**: Adaptive UI that works on phones and tablets
- **Material Design 3**: Modern, accessible interface
- **Real-time Currency Conversion**: Live exchange rates with caching

## Tech Stack

- **Framework**: Flutter 3.7.2+
- **Database**: Hive (local NoSQL database)
- **State Management**: Provider pattern
- **Charts**: FL Chart for data visualization
- **Notifications**: Flutter Local Notifications
- **App Detection**: Installed Apps plugin
- **Currency Conversion**: HTTP API integration with caching
- **Monetization**: Google AdMob integration

## Getting Started

### Prerequisites

- Flutter SDK (3.7.2 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code with Flutter extensions
- Android device or emulator (API level 21+)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/harsh-m-10/sub_trackr.git
   cd sub_trackr
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Building for Release

**Android APK:**
```bash
flutter build apk --release
```

**Android App Bundle (recommended for Play Store):**
```bash
flutter build appbundle --release
```

The release files will be available at:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

## Configuration

### AdMob Setup

1. Create an AdMob account and get your app ID
2. Update the AdMob IDs in `lib/services/ads_service.dart`
3. Add your app ID to `android/app/src/main/AndroidManifest.xml`

### App Signing

1. Generate a keystore file for app signing
2. Create `android/app/signing.properties` with your keystore details
3. Ensure the keystore file is in the correct location

### Permissions

The app requires the following permissions:
- `READ_INSTALLED_APPS`: To scan and list installed applications
- `POST_NOTIFICATIONS`: To send subscription renewal reminders (Android 13+)
- Internet access for currency conversion and ads

## Project Structure

```
lib/
├── db/
│   └── hive_boxes.dart              # Database configuration
├── models/
│   ├── subscription.dart            # Data model
│   └── subscription.g.dart          # Generated Hive adapter
├── providers/
│   ├── currency_provider.dart       # Currency state management
│   ├── subscription_provider.dart   # Subscription state management
│   └── analytics_provider.dart      # Analytics state management
├── screens/
│   ├── home_screen.dart             # Main dashboard
│   ├── add_subscription_screen.dart # Add new subscriptions
│   ├── edit_subscription_screen.dart # Edit existing subscriptions
│   ├── scan_apps_screen.dart        # App scanning interface
│   ├── analytics_screen.dart        # Spending analytics
│   └── settings_screen.dart         # App settings
├── services/
│   ├── notification_service.dart    # Notification management
│   ├── currency_conversion_service.dart # Currency conversion
│   ├── app_scanner_service.dart     # App detection
│   ├── export_service.dart          # Data export
│   └── ads_service.dart             # AdMob integration
├── widgets/
│   ├── subscription_card.dart       # Subscription display
│   ├── spending_summary_box.dart    # Spending overview
│   ├── banner_ad_widget.dart        # Ad display
│   └── reminder_options_widget.dart # Reminder configuration
├── utils/
│   ├── constants.dart               # App constants
│   └── helpers.dart                 # Utility functions
└── main.dart                        # App entry point
```

## Key Features Implementation

### Subscription Management
- Flexible billing cycles (weekly, monthly, yearly, custom)
- Category-based organization
- Start date tracking
- Reminder configuration

### Analytics and Insights
- Spending breakdown by category and frequency
- Interactive pie charts and visualizations
- Date range filtering
- Spending predictions and trends

### Smart Notifications
- Configurable reminder days
- Custom notification times
- Background processing
- Permission handling

### Data Export
- CSV export with detailed information
- JSON backup format
- Date range filtering
- Share integration

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow Flutter best practices and conventions
- Maintain code documentation
- Write tests for new features
- Ensure responsive design across devices
- Test on both Android and iOS platforms

## Security and Privacy

- All data is stored locally on the device
- No personal information is collected or transmitted
- No cloud synchronization
- User controls all data export and sharing
- Minimal required permissions

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support, feature requests, or bug reports:
- Create an issue on GitHub
- Contact: harsh.m.1004@gmail.com
- Privacy Policy: https://harsh-m-10.github.io/sub_trackr/privacy_policy.html

## Acknowledgments

- Flutter team for the amazing framework
- Hive team for the lightweight database
- FL Chart team for the beautiful charts
- All contributors and beta testers

## Version History

- **v1.0.0**: Initial release with core subscription tracking features
- Analytics and spending visualization
- Multi-currency support
- Smart notifications
- App scanning functionality
