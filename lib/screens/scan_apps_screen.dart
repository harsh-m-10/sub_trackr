import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import '../db/hive_boxes.dart';
import '../models/subscription.dart';
import 'add_subscription_screen.dart';

class ScanAppsScreen extends StatefulWidget {
  const ScanAppsScreen({super.key});

  @override
  State<ScanAppsScreen> createState() => _ScanAppsScreenState();
}

class _ScanAppsScreenState extends State<ScanAppsScreen> {
  List<AppInfo> allApps = [];
  final Set<String> ignoredApps = {};
  final Set<String> selectedApps = {};

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    final List<Subscription> subscriptions = HiveBoxes.getSubscriptionsBox().values.toList();
    final Set<String> subscribedAppNames = subscriptions.map((s) => s.appName.toLowerCase()).toSet();

    List<AppInfo> apps = await InstalledApps.getInstalledApps(true, true); // include system apps & icons

    // Filter out services/system-related apps and subscribed apps
    apps = apps.where((app) {
      final name = app.name.trim().toLowerCase();
      return name.isNotEmpty &&
          !name.contains("service") &&
          !subscribedAppNames.contains(name);
    }).toList();

    apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    setState(() {
      allApps = apps;
    });
  }

  void _toggleIgnore(String packageName) {
    setState(() {
      ignoredApps.add(packageName);
      selectedApps.remove(packageName);
    });
  }

  Future<void> _openAddSubscription(String appName) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddSubscriptionScreen(
          prefillAppName: appName,
        ),
      ),
    );

    // Refresh app list to remove the subscribed one
    _loadApps();
  }

  void _confirmSelection() {
    Navigator.pop(context);
  }

  void _cancelSelection() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage App Subscriptions'),
      ),
      body: allApps.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: allApps.length,
              itemBuilder: (context, index) {
                final app = allApps[index];
                final isIgnored = ignoredApps.contains(app.packageName);

                if (isIgnored) return const SizedBox.shrink();

                return ListTile(
                  leading: app.icon != null
                      ? CircleAvatar(backgroundImage: MemoryImage(app.icon!))
                      : const Icon(Icons.android),
                  title: Text(app.name),
                  subtitle: Text(app.packageName),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () {
                          _openAddSubscription(app.name);
                          selectedApps.add(app.packageName);
                          ignoredApps.remove(app.packageName);
                        },
                        child: const Text('Add'),
                      ),
                      TextButton(
                        onPressed: () => _toggleIgnore(app.packageName),
                        child: const Text('Ignore'),
                      ),
                    ],
                  ),
                  tileColor: selectedApps.contains(app.packageName)
                      ? Colors.green.withAlpha((255 * 0.1).round())
                      : null,
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _cancelSelection,
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _confirmSelection,
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
