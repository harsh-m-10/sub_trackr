import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/subscription.dart';
import 'db/hive_boxes.dart';
import 'screens/home_screen.dart';
import 'theme/theme_provider.dart';
import 'services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermissions() async {
  await [
    Permission.notification,
    Permission.storage,
    Permission.scheduleExactAlarm,
  ].request();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(SubscriptionAdapter());
  await Hive.openBox<Subscription>(HiveBoxes.subscriptionBox);
  await NotificationService.initialize(); 
  // await NotificationService.requestPermission(); 
  await requestPermissions();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const SubTrackrApp(),
    ),
  );
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
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}
