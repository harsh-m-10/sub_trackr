// ignore_for_file: unnecessary_cast

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sub_trackr/screens/settings_screen.dart';
import 'package:sub_trackr/screens/analytics_screen.dart';

import '../db/hive_boxes.dart';
import '../models/subscription.dart';
import 'add_subscription_screen.dart';
import 'scan_apps_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedPeriod = "Monthly";

  double _calculateTotal(List<Subscription> subscriptions) {
    return subscriptions.fold(0.0, (sum, sub) {
      final freq = sub.frequency.toLowerCase();

      if (selectedPeriod == 'Monthly') {
        if (freq.contains('monthly')) return sum + sub.amount;
        if (freq.contains('weekly')) return sum + (sub.amount * 4);
        if (freq.contains('yearly')) return sum + (sub.amount / 12);
        if (freq.startsWith('every')) {
          final parts = freq.split(' ');
          if (parts.length >= 3) {
            final num = int.tryParse(parts[1]) ?? 1;
            final unit = parts[2];
            if (unit.startsWith('week')) return sum + (sub.amount * 4 / num);
            if (unit.startsWith('month')) return sum + (sub.amount / num);
          }
        }
      }

      if (selectedPeriod == 'Weekly') {
        if (freq.contains('weekly')) return sum + sub.amount;
        if (freq.contains('monthly')) return sum + (sub.amount / 4);
        if (freq.contains('yearly')) return sum + (sub.amount / 52);
        if (freq.startsWith('every')) {
          final parts = freq.split(' ');
          if (parts.length >= 3) {
            final num = int.tryParse(parts[1]) ?? 1;
            final unit = parts[2];
            if (unit.startsWith('week')) return sum + (sub.amount / num);
            if (unit.startsWith('month')) return sum + (sub.amount / (num * 4));
          }
        }
      }

      if (selectedPeriod == 'Yearly') {
        if (freq.contains('yearly')) return sum + sub.amount;
        if (freq.contains('monthly')) return sum + (sub.amount * 12);
        if (freq.contains('weekly')) return sum + (sub.amount * 52);
        if (freq.startsWith('every')) {
          final parts = freq.split(' ');
          if (parts.length >= 3) {
            final num = int.tryParse(parts[1]) ?? 1;
            final unit = parts[2];
            if (unit.startsWith('week')) return sum + (sub.amount * 52 / num);
            if (unit.startsWith('month')) return sum + (sub.amount * 12 / num);
          }
        }
      }

      return sum;
    });
  }

  void _deleteSubscription(int index) async {
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
        await subscription.delete();
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionBox = HiveBoxes.getSubscriptionsBox();

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ValueListenableBuilder(
              valueListenable: subscriptionBox.listenable(),
              builder: (context, box, _) {
                final List<Subscription> subscriptions = box.values.cast<Subscription>().toList();
                final totalSpending = _calculateTotal(subscriptions);

                return SizedBox(
                  height: 180,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Total $selectedPeriod Spending',
                          style: const TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${totalSpending.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        DropdownButton<String>(
                          value: selectedPeriod,
                          dropdownColor: Colors.blueAccent,
                          style: const TextStyle(color: Colors.white),
                          underline: Container(),
                          items: ['Weekly', 'Monthly', 'Yearly']
                              .map((period) => DropdownMenuItem(value: period, child: Text(period)))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => selectedPeriod = value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
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
                    child: const Text('Add Subscription'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ScanAppsScreen()),
                      );
                    },
                    child: const Text('Manage Subscriptions'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: subscriptionBox.listenable(),
                builder: (context, box, _) {
                  if (box.isEmpty) {
                    return const Center(child: Text('No subscriptions yet.'));
                  }

                  final List<Subscription> subscriptions = box.values.cast<Subscription>().toList();

                  return ListView.builder(
                    itemCount: subscriptions.length,
                    itemBuilder: (context, index) {
                      final sub = subscriptions[index];
                      return Card(
                        child: ListTile(
                          title: Text(sub.appName),
                          subtitle: Text('${sub.planName} • ₹${sub.amount} • ${sub.frequency}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteSubscription(index),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
