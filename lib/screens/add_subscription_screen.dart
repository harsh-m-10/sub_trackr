import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../db/hive_boxes.dart';
import '../models/subscription.dart';
import '../services/notification_service.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/reminder_options_widget.dart';
import '../providers/currency_provider.dart';
import '../utils/helpers.dart';

class AddSubscriptionScreen extends StatefulWidget {
  final String? prefillAppName;

  const AddSubscriptionScreen({super.key, this.prefillAppName});

  @override
  State<AddSubscriptionScreen> createState() => _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState extends State<AddSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _appNameController = TextEditingController();
  final TextEditingController _planNameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  DateTime _startDate = DateTime.now();

  String _selectedFrequency = 'Monthly';
  int _customNumber = 1;
  String _customUnit = 'Week';
  TimeOfDay _notificationTime = const TimeOfDay(hour: 9, minute: 0); // Default: 9:00 AM

  final List<String> frequencyOptions = ['Weekly', 'Monthly', 'Yearly', 'Custom'];
  final List<String> categoryOptions = ['Entertainment', 'Productivity', 'Finance', 'Education', 'Health', 'Other'];
  final Set<String> selectedCategories = {};
  List<int> selectedReminderDays = [1]; // Default: 1 day before

  @override
  void initState() {
    super.initState();
    if (widget.prefillAppName != null) {
      _appNameController.text = widget.prefillAppName!;
    }
  }

  void _saveSubscription() async {
    if (_formKey.currentState!.validate()) {
      try {
        String frequency = _selectedFrequency;

        if (_selectedFrequency == 'Custom') {
          frequency = 'Every $_customNumber $_customUnit${_customNumber > 1 ? 's' : ''}';
        }

        final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
        final subscription = Subscription(
          appName: _appNameController.text.trim(),
          planName: _planNameController.text.trim(),
          amount: double.parse(_amountController.text.trim()),
          frequency: frequency,
          startDate: _startDate,
          category: selectedCategories.join(', '),
          reminderDays: selectedReminderDays,
          currency: currencyProvider.selectedCurrency,
        );

        final box = HiveBoxes.getSubscriptionsBox();
        final int id = await box.add(subscription);

        final DateTime nextBillingDate = _calculateNextBillingDate(subscription);
        print('=== Subscription Details ===');
        print('Start Date: ${subscription.startDate}');
        print('Frequency: ${subscription.frequency}');
        print('Calculated Next Billing Date: $nextBillingDate');
        print('Selected Reminder Days: $selectedReminderDays');
        print('Notification Time: $_notificationTime');
        
        try {
          await NotificationService.scheduleMultipleReminders(
            baseId: id,
            title: "Upcoming subscription: ${subscription.appName}",
            body: "${formatCurrency(subscription.amount, currencyProvider.selectedCurrency)} due on ${nextBillingDate.toLocal().toString().split(' ')[0]}",
            billingDate: nextBillingDate,
            reminderDays: selectedReminderDays,
            notificationTime: _notificationTime,
          );
          print('Notifications scheduled successfully for subscription ID: $id');
        } catch (e) {
          // Notification scheduling failed, but subscription was saved
          print('Failed to schedule notifications: $e');
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subscription added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving subscription: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  DateTime _calculateNextBillingDate(Subscription sub) {
    final freq = sub.frequency.toLowerCase();
    final date = sub.startDate;

    if (freq.contains('weekly')) return date.add(const Duration(days: 7));
    if (freq.contains('monthly')) {
      // Handle month overflow properly
      int newMonth = date.month + 1;
      int newYear = date.year;
      if (newMonth > 12) {
        newMonth = 1;
        newYear++;
      }
      return DateTime(newYear, newMonth, date.day);
    }
    if (freq.contains('yearly')) return DateTime(date.year + 1, date.month, date.day);

    if (freq.startsWith('every')) {
      final parts = freq.split(' ');
      if (parts.length >= 3) {
        final num = int.tryParse(parts[1]) ?? 1;
        final unit = parts[2];
        if (unit.startsWith('week')) return date.add(Duration(days: 7 * num));
        if (unit.startsWith('month')) {
          // Handle month overflow properly for custom months
          int newMonth = date.month + num;
          int newYear = date.year;
          while (newMonth > 12) {
            newMonth -= 12;
            newYear++;
          }
          return DateTime(newYear, newMonth, date.day);
        }
      }
    }

    return date;
  }

  void _pickStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _planNameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final padding = screenSize.width * 0.04; // 4% of screen width
    final spacing = screenSize.height * 0.015; // 1.5% of screen height
    final fieldHeight = screenSize.height * 0.06; // 6% of screen height

    return Scaffold(
      appBar: AppBar(title: const Text('Add Subscription')),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                SizedBox(
                  height: fieldHeight,
                  child: TextFormField(
                    controller: _appNameController,
                    decoration: InputDecoration(
                      labelText: 'App Name',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: padding * 0.5,
                        vertical: padding * 0.3,
                      ),
                    ),
                    validator: (value) => value!.isEmpty ? 'Enter App Name' : null,
                  ),
                ),
                SizedBox(height: spacing),
                SizedBox(
                  height: fieldHeight,
                  child: TextFormField(
                    controller: _planNameController,
                    decoration: InputDecoration(
                      labelText: 'Plan Name (Optional)',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: padding * 0.5,
                        vertical: padding * 0.3,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: spacing),
                Consumer<CurrencyProvider>(
                  builder: (context, currencyProvider, child) {
                    return SizedBox(
                      height: fieldHeight,
                      child: TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: 'Amount (in ${currencyProvider.selectedCurrency})',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: padding * 0.5,
                            vertical: padding * 0.3,
                          ),
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter Amount';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Enter a valid amount greater than 0';
                          }
                          return null;
                        },
                      ),
                    );
                  },
                ),
                SizedBox(height: spacing),
                SizedBox(
                  height: fieldHeight,
                  child: DropdownButtonFormField<String>(
                    value: _selectedFrequency,
                    items: frequencyOptions.map((freq) => DropdownMenuItem(value: freq, child: Text(freq))).toList(),
                    onChanged: (value) => setState(() => _selectedFrequency = value!),
                    decoration: InputDecoration(
                      labelText: 'Billing Frequency',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: padding * 0.5,
                        vertical: padding * 0.3,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: spacing),
                if (_selectedFrequency == 'Custom')
                  SizedBox(
                    height: fieldHeight,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<int>(
                            value: _customNumber,
                            items: List.generate(30, (index) => index + 1).map((num) => DropdownMenuItem(value: num, child: Text('$num'))).toList(),
                            onChanged: (value) => setState(() => _customNumber = value!),
                            decoration: InputDecoration(
                              labelText: 'Every',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: padding * 0.5,
                                vertical: padding * 0.3,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: spacing),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            value: _customUnit,
                            items: ['Week', 'Month'].map((unit) => DropdownMenuItem(value: unit, child: Text(unit))).toList(),
                            onChanged: (value) => setState(() => _customUnit = value!),
                            decoration: InputDecoration(
                              labelText: 'Unit',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: padding * 0.5,
                                vertical: padding * 0.3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: spacing),
                SizedBox(
                  height: fieldHeight,
                  child: ListTile(
                    title: Text(
                      'Start Date: ${_startDate.toLocal().toString().split(' ')[0]}',
                      style: TextStyle(fontSize: screenSize.width * 0.035),
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _pickStartDate,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: padding * 0.5,
                      vertical: padding * 0.3,
                    ),
                  ),
                ),
                SizedBox(height: spacing * 1.2),
                Text(
                  'Select Categories:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: screenSize.width * 0.04,
                  ),
                ),
                SizedBox(height: spacing * 0.5),
                Wrap(
                  spacing: spacing,
                  runSpacing: spacing * 0.5,
                  children: categoryOptions.map((cat) {
                    final isSelected = selectedCategories.contains(cat);
                    return ChoiceChip(
                      label: Text(
                        cat,
                        style: TextStyle(fontSize: screenSize.width * 0.035),
                      ),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          isSelected ? selectedCategories.remove(cat) : selectedCategories.add(cat);
                        });
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: spacing * 1.6),
                ReminderOptionsWidget(
                  selectedDays: selectedReminderDays,
                  onChanged: (days) {
                    setState(() {
                      selectedReminderDays = days;
                    });
                  },
                ),
                SizedBox(height: spacing * 1.2),
                _buildNotificationTimePicker(screenSize, padding, spacing),
                SizedBox(height: spacing * 1.6),
                SizedBox(
                  height: fieldHeight * 1.2,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveSubscription,
                    style: ElevatedButton.styleFrom(
                      textStyle: TextStyle(
                        fontSize: screenSize.width * 0.04,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Save Subscription'),
                  ),
                ),
                SizedBox(height: spacing * 1.2),
                // Banner ad at the bottom with standard size
                const BannerAdWidget(useStandardSize: true),
                SizedBox(height: spacing),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationTimePicker(Size screenSize, double padding, double spacing) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.blue, size: screenSize.width * 0.05),
                SizedBox(width: spacing),
                Text(
                  'Notification Time',
                  style: TextStyle(
                    fontSize: screenSize.width * 0.04,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing),
            InkWell(
              onTap: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: _notificationTime,
                );
                if (picked != null) {
                  setState(() {
                    _notificationTime = picked;
                  });
                }
              },
              child: Container(
                padding: EdgeInsets.all(padding * 0.75),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(screenSize.width * 0.02),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Time: ${_notificationTime.format(context)}',
                      style: TextStyle(fontSize: screenSize.width * 0.04),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            SizedBox(height: spacing * 0.5),
            Text(
              'Notifications will be sent at this time on reminder days',
              style: TextStyle(
                fontSize: screenSize.width * 0.03,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
