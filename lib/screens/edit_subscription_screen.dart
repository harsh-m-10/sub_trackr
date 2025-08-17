import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../db/hive_boxes.dart';
import '../models/subscription.dart';
import '../services/notification_service.dart';
import '../utils/helpers.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/reminder_options_widget.dart';
import '../providers/currency_provider.dart';
import '../utils/constants.dart';

class EditSubscriptionScreen extends StatefulWidget {
  final Subscription subscription;
  final int subscriptionIndex;

  const EditSubscriptionScreen({
    super.key,
    required this.subscription,
    required this.subscriptionIndex,
  });

  @override
  State<EditSubscriptionScreen> createState() => _EditSubscriptionScreenState();
}

class _EditSubscriptionScreenState extends State<EditSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _appNameController;
  late TextEditingController _planNameController;
  late TextEditingController _amountController;
  late DateTime _startDate;
  late String _selectedFrequency;
  late int _customNumber;
  late String _customUnit;
  late Set<String> selectedCategories;
  late List<int> selectedReminderDays;
  late TimeOfDay _notificationTime; // Add notification time
  late String _selectedCurrency; // Add currency field

  final List<String> frequencyOptions = ['Weekly', 'Monthly', 'Yearly', 'Custom'];
  final List<String> categoryOptions = ['Entertainment', 'Productivity', 'Finance', 'Education', 'Health', 'Other'];

  @override
  void initState() {
    super.initState();
    _appNameController = TextEditingController(text: widget.subscription.appName);
    _planNameController = TextEditingController(text: widget.subscription.planName);
    _amountController = TextEditingController(text: widget.subscription.amount.toString());
    _startDate = widget.subscription.startDate;
    _selectedFrequency = widget.subscription.frequency;
    _customNumber = 1;
    _customUnit = 'Week';
    
    // Parse custom frequency if it exists
    if (_selectedFrequency.startsWith('Every ')) {
      final parts = _selectedFrequency.split(' ');
      if (parts.length >= 3) {
        _customNumber = int.tryParse(parts[1]) ?? 1;
        _customUnit = parts[2].replaceAll('s', '');
        _selectedFrequency = 'Custom';
      }
    }
    
    selectedCategories = widget.subscription.category.isNotEmpty 
        ? widget.subscription.category.split(', ').toSet()
        : <String>{};
    selectedReminderDays = List.from(widget.subscription.reminderDays);
    
    // Initialize notification time (default to 9:00 AM if not set)
    _notificationTime = const TimeOfDay(hour: 9, minute: 0);
    
    // Initialize currency from subscription
    _selectedCurrency = widget.subscription.currency;
  }

  void _saveSubscription() async {
    if (_formKey.currentState!.validate()) {
      String frequency = _selectedFrequency;

      if (_selectedFrequency == 'Custom') {
        frequency = 'Every $_customNumber $_customUnit${_customNumber > 1 ? 's' : ''}';
      }

      final updatedSubscription = Subscription(
        appName: _appNameController.text.trim(),
        planName: _planNameController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        frequency: frequency,
        startDate: _startDate,
        category: selectedCategories.join(', '),
        reminderDays: selectedReminderDays,
        currency: _selectedCurrency, // Add currency
      );

      final box = HiveBoxes.getSubscriptionsBox();
      
      // Cancel old notifications
      await NotificationService.cancelMultipleReminders(widget.subscriptionIndex);
      
      // Update the subscription
      await box.putAt(widget.subscriptionIndex, updatedSubscription);

      // Schedule new notifications
      final DateTime nextBillingDate = calculateNextBillingDate(updatedSubscription);
      await NotificationService.scheduleMultipleReminders(
        baseId: widget.subscriptionIndex,
        title: "Upcoming subscription: ${updatedSubscription.appName}",
        body: "${formatCurrency(updatedSubscription.amount, _selectedCurrency)} due on ${nextBillingDate.toLocal().toString().split(' ')[0]}",
        billingDate: nextBillingDate,
        reminderDays: selectedReminderDays,
        notificationTime: _notificationTime, // Add notification time
      );

      if (mounted) Navigator.pop(context);
    }
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

  Widget _buildNotificationTimePicker() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Notification Time',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Time: ${_notificationTime.format(context)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Notifications will be sent at this time on reminder days',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Subscription'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSubscription,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _appNameController,
                decoration: const InputDecoration(labelText: 'App Name'),
                validator: (value) => value!.isEmpty ? 'Enter App Name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _planNameController,
                decoration: const InputDecoration(labelText: 'Plan Name (Optional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount (in ${_selectedCurrency})',
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
              const SizedBox(height: 12),
              Consumer<CurrencyProvider>(
                builder: (context, currencyProvider, child) {
                  return DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    items: AppConstants.availableCurrencies.map((currency) {
                      return DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCurrency = value;
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedFrequency,
                items: frequencyOptions.map((freq) => DropdownMenuItem(value: freq, child: Text(freq))).toList(),
                onChanged: (value) => setState(() => _selectedFrequency = value!),
                decoration: const InputDecoration(labelText: 'Billing Frequency'),
              ),
              const SizedBox(height: 12),
              if (_selectedFrequency == 'Custom')
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        value: _customNumber,
                        items: List.generate(30, (index) => index + 1).map((num) => DropdownMenuItem(value: num, child: Text('$num'))).toList(),
                        onChanged: (value) => setState(() => _customNumber = value!),
                        decoration: const InputDecoration(labelText: 'Every'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: _customUnit,
                        items: ['Week', 'Month'].map((unit) => DropdownMenuItem(value: unit, child: Text(unit))).toList(),
                        onChanged: (value) => setState(() => _customUnit = value!),
                        decoration: const InputDecoration(labelText: 'Unit'),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              ListTile(
                title: Text('Start Date: ${_startDate.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickStartDate,
              ),
              const SizedBox(height: 16),
              const Text('Select Categories:', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8.0,
                children: categoryOptions.map((cat) {
                  final isSelected = selectedCategories.contains(cat);
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        selected ? selectedCategories.add(cat) : selectedCategories.remove(cat);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              ReminderOptionsWidget(
                selectedDays: selectedReminderDays,
                onChanged: (days) {
                  setState(() {
                    selectedReminderDays = days;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildNotificationTimePicker(),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveSubscription,
                child: const Text('Save Changes'),
              ),
              const SizedBox(height: 16),
              // Banner ad at the bottom
              const BannerAdWidget(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
