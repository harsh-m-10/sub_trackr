// ignore_for_file: unnecessary_cast

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sub_trackr/screens/settings_screen.dart';
import 'package:sub_trackr/screens/analytics_screen.dart';

import '../db/hive_boxes.dart';
import '../models/subscription.dart';
import '../services/notification_service.dart';
import '../utils/helpers.dart';
import '../providers/currency_provider.dart';
import '../services/currency_conversion_service.dart';
import 'add_subscription_screen.dart';
import 'scan_apps_screen.dart';
import 'edit_subscription_screen.dart';
import '../widgets/subscription_card.dart';
import '../widgets/spending_summary_box.dart';
import '../widgets/banner_ad_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  String selectedPeriod = "Monthly";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Start periodic reminder checking when app becomes active
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.startPeriodicChecking();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.stopPeriodicChecking();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      // App became active, start checking reminders
      NotificationService.startPeriodicChecking();
      
      // Also check for reminders immediately when app resumes
      _checkRemindersOnResume();
    } else if (state == AppLifecycleState.paused || 
               state == AppLifecycleState.inactive || 
               state == AppLifecycleState.detached) {
      // App went to background, stop periodic checking
      NotificationService.stopPeriodicChecking();
    }
  }
  
  /// Check for reminders when app resumes
  void _checkRemindersOnResume() async {
    try {
      final subscriptionBox = HiveBoxes.getSubscriptionsBox();
      final subscriptions = subscriptionBox.values.toList();
      
      if (subscriptions.isNotEmpty) {
        await NotificationService.checkForRemindersWithData(subscriptions);
      }
    } catch (e) {
      print('Error checking reminders on resume: $e');
    }
  }

  Future<double> _calculateTotalWithConversion(List<Subscription> subscriptions, String targetCurrency) async {
    double total = 0.0;
    
    for (final subscription in subscriptions) {
      final normalizedAmount = normalizeAmountForPeriod(subscription, selectedPeriod);
      final convertedAmount = await CurrencyConversionService.convertAmount(
        normalizedAmount, 
        subscription.currency, 
        targetCurrency
      );
      total += convertedAmount;
    }
    
    return total;
  }

  void _editSubscription(Subscription subscription, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSubscriptionScreen(
          subscription: subscription,
          subscriptionIndex: index,
        ),
      ),
    );
  }

  void _deleteSubscription(int index) async {
    try {
      final box = HiveBoxes.getSubscriptionsBox();
      final subscription = box.getAt(index) as Subscription?;

      if (subscription != null) {
        final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Subscription'),
            content: Text('Are you sure you want to delete "${subscription.appName}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );

        if (shouldDelete == true) {
          try {
            // Cancel any scheduled notifications using Hive key as ID
            final dynamic key = box.keyAt(index);
            if (key is int) {
              await NotificationService.cancelMultipleReminders(key);
            }
            await subscription.delete();
            setState(() {});
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${subscription.appName} deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error deleting subscription: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionBox = HiveBoxes.getSubscriptionsBox();
    final screenSize = MediaQuery.of(context).size;
    final padding = screenSize.width * 0.04; // 4% of screen width
    final spacing = screenSize.height * 0.02; // 2% of screen height

    return Scaffold(
      appBar: AppBar(
        title: const Text('SubTrackr'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Analytics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            children: [
              Consumer<CurrencyProvider>(
                builder: (context, currencyProvider, child) {
                  return ValueListenableBuilder(
                    valueListenable: subscriptionBox.listenable(),
                    builder: (context, box, _) {
                      final List<Subscription> subscriptions = box.values.cast<Subscription>().toList();
                      
                      return FutureBuilder<double>(
                        future: _calculateTotalWithConversion(subscriptions, currencyProvider.selectedCurrency),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Container(
                              height: screenSize.height * 0.25, // 25% of screen height
                              padding: EdgeInsets.all(padding),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xff2193b0), Color(0xff6dd5ed)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(screenSize.width * 0.03),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              ),
                            );
                          }
                          
                          final totalSpending = snapshot.data ?? 0.0;
                          
                          return SizedBox(
                            width: double.infinity,
                            height: screenSize.height * 0.25, // 25% of screen height
                            child: SpendingSummaryBox(
                              selectedPeriod: selectedPeriod,
                              totalSpending: totalSpending,
                              onPeriodChanged: (value) => setState(() => selectedPeriod = value),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
              SizedBox(height: spacing),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AddSubscriptionScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: screenSize.height * 0.018, // 1.8% of screen height
                          horizontal: padding,
                        ),
                        textStyle: TextStyle(
                          fontSize: screenSize.width * 0.04, // 4% of screen width
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Add Subscription'),
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ScanAppsScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: screenSize.height * 0.018, // 1.8% of screen height
                          horizontal: padding,
                        ),
                        textStyle: TextStyle(
                          fontSize: screenSize.width * 0.04, // 4% of screen width
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Manage Subscriptions'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing),
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: subscriptionBox.listenable(),
                  builder: (context, box, _) {
                    final List<Subscription> subscriptions = box.values.cast<Subscription>().toList();

                    if (box.isEmpty) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.subscriptions_outlined,
                            size: screenSize.width * 0.2, // 20% of screen width
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                          ),
                          SizedBox(height: spacing),
                          Text(
                            'Welcome to SubTrackr!',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: screenSize.width * 0.06, // 6% of screen width
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: spacing * 0.8),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: padding * 0.5),
                            child: Text(
                              'Start tracking your subscriptions to take control of your recurring expenses',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                fontSize: screenSize.width * 0.035, // 3.5% of screen width
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: spacing * 1.6),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AddSubscriptionScreen()),
                                );
                              },
                              icon: Icon(Icons.add, size: screenSize.width * 0.05),
                              label: Text(
                                'Add Your First Subscription',
                                style: TextStyle(fontSize: screenSize.width * 0.04),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: padding * 1.5,
                                  vertical: screenSize.height * 0.018,
                                ),
                                textStyle: TextStyle(
                                  fontSize: screenSize.width * 0.04,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: spacing * 0.6),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ScanAppsScreen()),
                                );
                              },
                              icon: Icon(Icons.search, size: screenSize.width * 0.05),
                              label: Text(
                                'Scan Installed Apps',
                                style: TextStyle(fontSize: screenSize.width * 0.04),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: padding * 1.5,
                                  vertical: screenSize.height * 0.018,
                                ),
                                textStyle: TextStyle(
                                  fontSize: screenSize.width * 0.04,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Removed banner ad from empty state for consistency
                        ],
                      );
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: subscriptions.length,
                            itemBuilder: (context, index) {
                              final sub = subscriptions[index];
                              return Padding(
                                padding: EdgeInsets.only(bottom: spacing * 0.5),
                                child: SubscriptionCard(
                                  subscription: sub,
                                  onEdit: () => _editSubscription(sub, index),
                                  onDelete: () => _deleteSubscription(index),
                                ),
                              );
                            },
                          ),
                        ),
                        // Banner ad at the bottom with standard size
                        const BannerAdWidget(useStandardSize: true),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
