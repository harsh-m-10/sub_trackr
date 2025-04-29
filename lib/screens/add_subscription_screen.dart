import 'package:flutter/material.dart';
import '../db/hive_boxes.dart';
import '../models/subscription.dart';
import '../services/notification_service.dart';

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

  final List<String> frequencyOptions = ['Weekly', 'Monthly', 'Yearly', 'Custom'];
  final List<String> categoryOptions = ['Entertainment', 'Productivity', 'Finance', 'Education', 'Health', 'Other'];
  final Set<String> selectedCategories = {};

  @override
  void initState() {
    super.initState();
    if (widget.prefillAppName != null) {
      _appNameController.text = widget.prefillAppName!;
    }
  }

  void _saveSubscription() async {
    if (_formKey.currentState!.validate()) {
      String frequency = _selectedFrequency;

      if (_selectedFrequency == 'Custom') {
        frequency = 'Every $_customNumber $_customUnit${_customNumber > 1 ? 's' : ''}';
      }

      final subscription = Subscription(
        appName: _appNameController.text.trim(),
        planName: _planNameController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        frequency: frequency,
        startDate: _startDate,
        category: selectedCategories.join(', '),
      );

      final box = HiveBoxes.getSubscriptionsBox();
      final int id = await box.add(subscription);

      final DateTime nextBillingDate = _calculateNextBillingDate(subscription);
      final reminderDate = nextBillingDate.subtract(const Duration(days: 1));
      await NotificationService.scheduleNotification(
        id: id,
        title: "Upcoming subscription: ${subscription.appName}",
        body: "₹${subscription.amount.toStringAsFixed(2)} due on ${nextBillingDate.toLocal().toString().split(' ')[0]}",
        scheduledDate: reminderDate,
      );

      if (mounted) Navigator.pop(context);
    }
  }

  DateTime _calculateNextBillingDate(Subscription sub) {
    final freq = sub.frequency.toLowerCase();
    final date = sub.startDate;

    if (freq.contains('weekly')) return date.add(const Duration(days: 7));
    if (freq.contains('monthly')) return DateTime(date.year, date.month + 1, date.day);
    if (freq.contains('yearly')) return DateTime(date.year + 1, date.month, date.day);

    if (freq.startsWith('every')) {
      final parts = freq.split(' ');
      if (parts.length >= 3) {
        final num = int.tryParse(parts[1]) ?? 1;
        final unit = parts[2];
        if (unit.startsWith('week')) return date.add(Duration(days: 7 * num));
        if (unit.startsWith('month')) return DateTime(date.year, date.month + num, date.day);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Add Subscription')),
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
                decoration: const InputDecoration(labelText: 'Amount (in ₹)'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Enter Amount' : null,
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
                        isSelected ? selectedCategories.remove(cat) : selectedCategories.add(cat);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveSubscription,
                child: const Text('Save Subscription'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
