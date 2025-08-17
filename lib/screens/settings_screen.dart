// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/hive_boxes.dart';
import '../models/subscription.dart';
import '../theme/theme_provider.dart';
import '../providers/currency_provider.dart';
import '../utils/constants.dart';
import '../services/ads_service.dart';
import '../services/currency_conversion_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currencyProvider = Provider.of<CurrencyProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: themeProvider.themeMode == ThemeMode.dark,
            onChanged: (value) {
              themeProvider.toggleTheme(value);
            },
            secondary: const Icon(Icons.brightness_6),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Currency'),
            subtitle: Text('Selected: ${currencyProvider.selectedCurrency}'),
            onTap: () => _showCurrencyPicker(context, currencyProvider),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Reset All Subscriptions'),
            onTap: () => _confirmResetSubscriptions(context),
          ),
        ],
      ),
    );
  }

  void _confirmResetSubscriptions(BuildContext context) async {
    try {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Reset'),
          content: const Text('Are you sure you want to delete all saved subscriptions? This cannot be undone.'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context, false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete All'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );

      if (confirm == true) {
        try {
          final box = HiveBoxes.getSubscriptionsBox();
          await box.clear();
          
          // Cancel all scheduled notifications
          // await NotificationService.cancelAll(); // This line was removed as per the edit hint
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('All subscriptions deleted successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error deleting subscriptions: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
      applicationIcon: const FlutterLogo(size: 48),
      children: [
        const Text('Track all your app subscriptions easily. Built with ❤️ using Flutter.'),
        const SizedBox(height: 8),
        Text('Developer: ${AppConstants.developerName}'),
      ],
    );
  }

  void _openPrivacyPolicy(BuildContext context) {
    // For now, show a dialog. In production, link to your hosted privacy policy
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const Text(
          'SubTrackr respects your privacy:\n\n'
          '• All data is stored locally on your device\n'
          '• No personal information is collected or shared\n'
          '• Notifications are sent locally only\n'
          '• App scanning only shows app names, no personal data\n\n'
          'Full privacy policy available at:\n'
          '${AppConstants.privacyPolicyUrl}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openFeedback(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Feedback & Support'),
        content: const Text(
          'We\'d love to hear from you!\n\n'
          '• Found a bug? Let us know\n'
          '• Have a feature request?\n'
          '• Need help with the app?\n\n'
          'Contact us at:\n'
          '${AppConstants.supportEmail}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, CurrencyProvider currencyProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: AppConstants.availableCurrencies.length,
            itemBuilder: (context, index) {
              final currency = AppConstants.availableCurrencies[index];
              return ListTile(
                title: Text(currency),
                trailing: currencyProvider.selectedCurrency == currency ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () async {
                  await currencyProvider.setCurrency(currency);
                  Navigator.pop(context);
                  if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Currency changed to $currency'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
