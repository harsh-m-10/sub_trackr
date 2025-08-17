import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/subscription.dart';
import 'db/hive_boxes.dart';
import 'screens/home_screen.dart';
import 'theme/theme_provider.dart';
import 'providers/currency_provider.dart';
import 'services/notification_service.dart';
import 'services/ads_service.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermissions() async {
  try {
    await [
      Permission.notification,
      Permission.storage,
      Permission.scheduleExactAlarm,
    ].request();
  } catch (e) {
    print('Permission request failed: $e');
    // Continue without permissions - app will still work
  }
}

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Hive.initFlutter();
    Hive.registerAdapter(SubscriptionAdapter());
    await Hive.openBox<Subscription>(HiveBoxes.subscriptionBox);
    
    print('=== Initializing Notification Service ===');
    try {
      await NotificationService.initialize(); 
      await NotificationService.checkPermissions();
      print('✅ Notification service initialized successfully');
    } catch (e) {
      print('❌ Notification service initialization failed: $e');
      // Continue without notifications - app will still work
    }
    
    // await NotificationService.requestPermission(); 
    await requestPermissions();
    await AdsService.initialize();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => CurrencyProvider()),
        ],
        child: const SubTrackrApp(),
      ),
    );
  } catch (e) {
    // Fallback to basic app if initialization fails
    print('App initialization failed: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Failed to initialize app'),
                const SizedBox(height: 8),
                Text('Error: ${e.toString()}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => main(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SubTrackrApp extends StatelessWidget {
  const SubTrackrApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'SubTrackr',
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
