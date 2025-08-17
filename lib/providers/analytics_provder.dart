import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../utils/helpers.dart';

class AnalyticsProvider extends ChangeNotifier {
  DateTimeRange? _selectedRange;
  bool _showBarChart = true;
  bool _showCategoryBreakdown = false;

  DateTimeRange? get selectedRange => _selectedRange;
  bool get showBarChart => _showBarChart;
  bool get showCategoryBreakdown => _showCategoryBreakdown;

  void setDateRange(DateTimeRange? range) {
    _selectedRange = range;
    notifyListeners();
  }

  void toggleChartType() {
    _showBarChart = !_showBarChart;
    notifyListeners();
  }

  void toggleBreakdownType() {
    _showCategoryBreakdown = !_showCategoryBreakdown;
    notifyListeners();
  }

  double calculateTotalSpending(List<Subscription> subscriptions, DateTime start, DateTime end) {
    double total = 0.0;
    for (var sub in subscriptions) {
      total += _estimateCostWithinRange(sub, start, end);
    }
    return total;
  }

  double _estimateCostWithinRange(Subscription sub, DateTime start, DateTime end) {
    if (sub.startDate.isAfter(end)) return 0.0;

    final String freq = sub.frequency.toLowerCase();
    final double amount = sub.amount;
    DateTime billing = sub.startDate.isBefore(start) ? start : sub.startDate;
    double total = 0.0;

    while (billing.isBefore(end)) {
      if (!billing.isBefore(start)) total += amount;
      billing = getNextBillingDateFrom(freq, billing);
    }

    return total;
  }
}
