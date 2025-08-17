import '../models/subscription.dart';
import '../utils/helpers.dart';

class AnalyticsService {
  /// Calculates spending trends over time
  static Map<String, double> calculateMonthlyTrends(List<Subscription> subscriptions, int months) {
    final Map<String, double> monthlyData = {};
    final DateTime now = DateTime.now();
    final DateTime start = DateTime(now.year, now.month - months);

    for (var sub in subscriptions) {
      if (sub.startDate.isAfter(now)) continue;
      DateTime billing = sub.startDate.isBefore(start) ? start : sub.startDate;

      while (billing.isBefore(now)) {
        final key = '${billing.year}-${billing.month.toString().padLeft(2, '0')}';
        monthlyData[key] = (monthlyData[key] ?? 0) + sub.amount;
        billing = getNextBillingDateFrom(sub.frequency, billing);
      }
    }

    return monthlyData;
  }

  /// Calculates category breakdown
  static Map<String, double> calculateCategoryBreakdown(List<Subscription> subscriptions) {
    final Map<String, double> categoryMap = {};
    
    for (var sub in subscriptions) {
      final category = sub.category.isNotEmpty ? sub.category : 'Other';
      categoryMap[category] = (categoryMap[category] ?? 0) + sub.amount;
    }
    
    return categoryMap;
  }

  /// Calculates frequency breakdown
  static Map<String, double> calculateFrequencyBreakdown(List<Subscription> subscriptions) {
    final Map<String, double> freqMap = {};
    
    for (var sub in subscriptions) {
      final freq = sub.frequency.toLowerCase().contains('week')
          ? 'Weekly'
          : sub.frequency.toLowerCase().contains('year')
              ? 'Yearly'
              : 'Monthly';
      freqMap[freq] = (freqMap[freq] ?? 0) + sub.amount;
    }
    
    return freqMap;
  }

  /// Predicts future spending
  static Map<String, double> predictFutureSpending(List<Subscription> subscriptions) {
    final DateTime now = DateTime.now();
    
    return {
      '1 Month': _calculateTotal(subscriptions, now, DateTime(now.year, now.month + 1, now.day)),
      '3 Months': _calculateTotal(subscriptions, now, DateTime(now.year, now.month + 3, now.day)),
      '6 Months': _calculateTotal(subscriptions, now, DateTime(now.year, now.month + 6, now.day)),
      '1 Year': _calculateTotal(subscriptions, now, DateTime(now.year + 1, now.month, now.day)),
    };
  }

  static double _calculateTotal(List<Subscription> subs, DateTime start, DateTime end) {
    double total = 0.0;
    for (var sub in subs) {
      total += _estimateCostWithinRange(sub, start, end);
    }
    return total;
  }

  static double _estimateCostWithinRange(Subscription sub, DateTime start, DateTime end) {
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
