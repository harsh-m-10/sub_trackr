import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import '../db/hive_boxes.dart';
import '../models/subscription.dart';
import 'add_subscription_screen.dart';
import '../widgets/banner_ad_widget.dart';

class ScanAppsScreen extends StatefulWidget {
  const ScanAppsScreen({super.key});

  @override
  State<ScanAppsScreen> createState() => _ScanAppsScreenState();
}

class _ScanAppsScreenState extends State<ScanAppsScreen> {
  List<AppInfo> allApps = [];
  final Set<String> ignoredApps = {};
  final Set<String> selectedApps = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    try {
      setState(() {
        _isLoading = true;
        allApps = [];
      });

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
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        allApps = [];
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading apps: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
    final screenSize = MediaQuery.of(context).size;
    final padding = screenSize.width * 0.04; // 4% of screen width
    final spacing = screenSize.height * 0.015; // 1.5% of screen height
    final iconSize = screenSize.width * 0.06; // 6% of screen width

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage App Subscriptions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApps,
            tooltip: 'Refresh apps',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: spacing),
                  Text(
                    'Scanning installed apps...',
                    style: TextStyle(fontSize: screenSize.width * 0.04),
                  ),
                ],
              ),
            )
          : allApps.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.apps,
                        size: screenSize.width * 0.16, // 16% of screen width
                        color: Colors.grey,
                      ),
                      SizedBox(height: spacing),
                      Text(
                        'No apps found',
                        style: TextStyle(
                          fontSize: screenSize.width * 0.045,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: spacing * 0.5),
                      Text(
                        'Try refreshing or check permissions',
                        style: TextStyle(
                          fontSize: screenSize.width * 0.035,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(padding),
                  itemCount: allApps.length,
                  itemBuilder: (context, index) {
                    final app = allApps[index];
                    final isIgnored = ignoredApps.contains(app.packageName);

                    if (isIgnored) return const SizedBox.shrink();

                    return Padding(
                      padding: EdgeInsets.only(bottom: spacing),
                      child: ListTile(
                        leading: app.icon != null
                            ? CircleAvatar(
                                backgroundImage: MemoryImage(app.icon!),
                                radius: iconSize * 0.5,
                              )
                            : Icon(Icons.android, size: iconSize),
                        title: Text(
                          app.name,
                          style: TextStyle(fontSize: screenSize.width * 0.04),
                        ),
                        subtitle: Text(
                          app.packageName,
                          style: TextStyle(fontSize: screenSize.width * 0.03),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () {
                                _openAddSubscription(app.name);
                                selectedApps.add(app.packageName);
                                ignoredApps.remove(app.packageName);
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: padding * 0.5,
                                  vertical: spacing * 0.5,
                                ),
                              ),
                              child: Text(
                                'Add',
                                style: TextStyle(fontSize: screenSize.width * 0.035),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _toggleIgnore(app.packageName),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: padding * 0.5,
                                  vertical: spacing * 0.5,
                                ),
                              ),
                              child: Text(
                                'Ignore',
                                style: TextStyle(fontSize: screenSize.width * 0.035),
                              ),
                            ),
                          ],
                        ),
                        tileColor: selectedApps.contains(app.packageName)
                            ? Colors.green.withAlpha((255 * 0.1).round())
                            : null,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: padding * 0.5,
                          vertical: spacing * 0.5,
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(padding * 0.75),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancelSelection,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: screenSize.height * 0.018,
                      ),
                      textStyle: TextStyle(
                        fontSize: screenSize.width * 0.04,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirmSelection,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: screenSize.height * 0.018,
                      ),
                      textStyle: TextStyle(
                        fontSize: screenSize.width * 0.04,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
          // Banner ad at the very bottom with standard size
          const BannerAdWidget(useStandardSize: true),
        ],
      ),
    );
  }
}
