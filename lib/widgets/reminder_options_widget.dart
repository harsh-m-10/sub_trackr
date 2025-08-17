import 'package:flutter/material.dart';

class ReminderOptionsWidget extends StatefulWidget {
  final List<int> selectedDays;
  final Function(List<int>) onChanged;

  const ReminderOptionsWidget({
    super.key,
    required this.selectedDays,
    required this.onChanged,
  });

  @override
  State<ReminderOptionsWidget> createState() => _ReminderOptionsWidgetState();
}

class _ReminderOptionsWidgetState extends State<ReminderOptionsWidget> {
  late List<int> _selectedDays;

  final List<Map<String, dynamic>> _reminderOptions = [
    {'days': 1, 'label': '1 day before', 'icon': Icons.notification_important},
    {'days': 3, 'label': '3 days before', 'icon': Icons.notifications_active},
    {'days': 7, 'label': '1 week before', 'icon': Icons.event_note},
    {'days': 14, 'label': '2 weeks before', 'icon': Icons.calendar_today},
    {'days': 30, 'label': '1 month before', 'icon': Icons.calendar_month},
  ];

  @override
  void initState() {
    super.initState();
    _selectedDays = List.from(widget.selectedDays);
  }

  void _toggleReminder(int days) {
    setState(() {
      if (_selectedDays.contains(days)) {
        _selectedDays.remove(days);
      } else {
        _selectedDays.add(days);
      }
      // Sort the list to maintain consistent order
      _selectedDays.sort();
      widget.onChanged(_selectedDays);
    });
  }

  void _selectAll() {
    setState(() {
      _selectedDays = _reminderOptions.map((option) => option['days'] as int).toList();
      _selectedDays.sort();
      widget.onChanged(_selectedDays);
    });
  }

  void _clearAll() {
    setState(() {
      _selectedDays.clear();
      widget.onChanged(_selectedDays);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reminder Options',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: _selectAll,
                  child: const Text('Select All'),
                ),
                TextButton(
                  onPressed: _clearAll,
                  child: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Choose when you want to be reminded about upcoming renewals',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),

        // Reminder Options
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _reminderOptions.map((option) {
            final days = option['days'] as int;
            final label = option['label'] as String;
            final icon = option['icon'] as IconData;
            final isSelected = _selectedDays.contains(days);

            return InkWell(
              onTap: () => _toggleReminder(days),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        // Custom reminder input
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Custom reminder (days)',
                  hintText: 'e.g., 5',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.add_alarm),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final days = int.tryParse(value);
                  if (days != null && days > 0 && days <= 365) {
                    if (!_selectedDays.contains(days)) {
                      setState(() {
                        _selectedDays.add(days);
                        _selectedDays.sort();
                        widget.onChanged(_selectedDays);
                      });
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                // This will be handled by the onChanged callback
              },
              child: const Text('Add'),
            ),
          ],
        ),

        // Summary
        if (_selectedDays.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You will receive ${_selectedDays.length} reminder${_selectedDays.length > 1 ? 's' : ''} before each renewal',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
