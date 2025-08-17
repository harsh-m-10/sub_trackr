import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import '../models/subscription.dart';
import '../db/hive_boxes.dart';

class AppScannerService {
  /// Scans installed apps and filters out already subscribed ones
  static Future<List<AppInfo>> getAvailableApps() async {
    try {
      final List<Subscription> subscriptions = HiveBoxes.getSubscriptionsBox().values.toList();
      final Set<String> subscribedAppNames = subscriptions.map((s) => s.appName.toLowerCase()).toSet();

      List<AppInfo> apps = await InstalledApps.getInstalledApps(true, true);

      // Filter out system services and already subscribed apps
      apps = apps.where((app) {
        final name = app.name.trim().toLowerCase();
        return name.isNotEmpty &&
            !name.contains("service") &&
            !name.contains("system") &&
            !name.contains("com.android") &&
            !name.contains("com.google") &&
            !subscribedAppNames.contains(name);
      }).toList();

      // Sort alphabetically
      apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      return apps;
    } catch (e) {
      print('Error scanning apps: $e');
      return [];
    }
  }

  /// Checks if an app is already subscribed
  static bool isAppSubscribed(String appName) {
    try {
      final List<Subscription> subscriptions = HiveBoxes.getSubscriptionsBox().values.toList();
      return subscriptions.any((sub) => sub.appName.toLowerCase() == appName.toLowerCase());
    } catch (e) {
      print('Error checking subscription: $e');
      return false;
    }
  }

  /// Gets app suggestions based on common subscription apps
  static List<String> getSuggestedApps() {
    return [
      'Netflix',
      'Spotify',
      'YouTube Premium',
      'Disney+',
      'Amazon Prime',
      'Microsoft 365',
      'Adobe Creative Cloud',
      'Dropbox',
      'LastPass',
      'Grammarly',
    ];
  }
}
