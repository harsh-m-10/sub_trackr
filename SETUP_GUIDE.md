# SubTrackr Development Setup Guide

This guide will help you set up the SubTrackr project for development.

## Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK**: 3.7.2 or higher
- **Dart SDK**: 3.0.0 or higher
- **Android Studio** or **VS Code** with Flutter extensions
- **Git**
- **Android SDK** (for Android development)
- **Xcode** (for iOS development, macOS only)

## Installation Steps

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/sub_trackr.git
cd sub_trackr
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Generate Hive Adapters

The project uses Hive for local data storage. Generate the required adapters:

```bash
flutter packages pub run build_runner build
```

### 4. Configure API Keys (Optional)

If you want to test AdMob functionality:

1. Copy the template file:
   ```bash
   cp lib/config/api_keys_template.dart lib/config/api_keys.dart
   ```

2. Edit `lib/config/api_keys.dart` and add your AdMob IDs:
   ```dart
   static const String admobAppId = 'ca-app-pub-xxxxxxxxxxxxxxxx~xxxxxxxxxx';
   static const String admobBannerAdUnitId = 'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx';
   ```

**Note**: The app will work without AdMob configuration, but ads won't display.

### 5. Run the App

```bash
flutter run
```

## Project Structure

```
sub_trackr/
├── lib/
│   ├── config/                 # Configuration files
│   ├── db/                     # Database setup
│   ├── models/                 # Data models
│   ├── providers/              # State management
│   ├── screens/                # UI screens
│   ├── services/               # Business logic
│   ├── utils/                  # Utility functions
│   ├── widgets/                # Reusable widgets
│   └── main.dart              # App entry point
├── android/                    # Android-specific files
├── ios/                       # iOS-specific files
├── test/                      # Test files
└── pubspec.yaml              # Dependencies
```

## Key Dependencies

- **Hive**: Local NoSQL database
- **Provider**: State management
- **FL Chart**: Data visualization
- **Flutter Local Notifications**: Local notifications
- **Installed Apps**: App detection
- **Google Mobile Ads**: AdMob integration
- **HTTP**: API calls for currency conversion

## Development Workflow

### 1. Code Style

Follow the official Dart style guide. The project includes `analysis_options.yaml` for linting rules.

### 2. Testing

Run tests:
```bash
flutter test
```

### 3. Building

Build for Android:
```bash
flutter build apk --release
```

Build for iOS:
```bash
flutter build ios --release
```

### 4. Code Generation

If you modify Hive models, regenerate adapters:
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

## Common Issues and Solutions

### 1. Build Runner Issues

If you encounter build runner conflicts:
```bash
flutter packages pub run build_runner clean
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### 2. Permission Issues (Android)

Ensure the app has proper permissions in `android/app/src/main/AndroidManifest.xml`:
- `READ_INSTALLED_APPS`
- `POST_NOTIFICATIONS` (Android 13+)

### 3. iOS Build Issues

For iOS development:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Set up your development team
3. Configure bundle identifier

### 4. AdMob Issues

If ads aren't showing:
1. Check your AdMob configuration
2. Ensure you're using test ad unit IDs during development
3. Check network connectivity

## Debugging

### 1. Enable Debug Logging

The app includes comprehensive logging. Check the console for:
- Database operations
- Notification scheduling
- Currency conversion
- Ad loading status

### 2. Database Inspection

To inspect Hive database:
1. Run the app in debug mode
2. Check the console for database paths
3. Use Hive Inspector (if available) or manually inspect files

### 3. Notification Testing

Test notifications:
1. Add a subscription with reminders
2. Set reminder days to 0 for immediate testing
3. Check notification permissions

## Performance Considerations

### 1. Memory Management

- Dispose of controllers properly
- Use `const` constructors where possible
- Avoid memory leaks in long-running operations

### 2. Database Operations

- Use batch operations for multiple database writes
- Implement proper error handling
- Consider database migration strategies

### 3. UI Performance

- Use `ListView.builder` for large lists
- Implement proper widget keys
- Optimize image loading and caching

## Deployment

### 1. Android Release

1. Generate a keystore:
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Create `android/app/signing.properties`:
   ```properties
   storeFile=../upload-keystore.jks
   storePassword=your_keystore_password
   keyAlias=upload
   keyPassword=your_key_password
   ```

3. Build the release:
   ```bash
   flutter build appbundle --release
   ```

### 2. iOS Release

1. Configure signing in Xcode
2. Set up App Store Connect
3. Build and archive:
   ```bash
   flutter build ios --release
   ```

## Support

If you encounter issues:

1. Check the existing issues on GitHub
2. Create a new issue with detailed information
3. Include your environment details and error logs
4. Provide steps to reproduce the issue

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed contribution guidelines.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
