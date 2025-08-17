import '../models/subscription.dart';
import '../utils/helpers.dart';

class SubscriptionService {
  /// Calculates the total spending for a given period
  static double calculateTotalSpending(List<Subscription> subscriptions, String period) {
    return subscriptions.fold(0.0, (sum, sub) => sum + normalizeAmountForPeriod(sub, period));
  }

  /// Gets subscriptions expiring within the next X days
  static List<Subscription> getExpiringSubscriptions(List<Subscription> subscriptions, int days) {
    final now = DateTime.now();
    final threshold = now.add(Duration(days: days));
    
    return subscriptions.where((sub) {
      final nextBilling = calculateNextBillingDate(sub);
      return nextBilling.isBefore(threshold) && nextBilling.isAfter(now);
    }).toList();
  }

  /// Groups subscriptions by category
  static Map<String, List<Subscription>> groupByCategory(List<Subscription> subscriptions) {
    final Map<String, List<Subscription>> grouped = {};
    
    for (final sub in subscriptions) {
      final category = sub.category.isNotEmpty ? sub.category : 'Other';
      grouped.putIfAbsent(category, () => []).add(sub);
    }
    
    return grouped;
  }

  /// Gets the most expensive subscription
  static Subscription? getMostExpensive(List<Subscription> subscriptions) {
    if (subscriptions.isEmpty) return null;
    
    return subscriptions.reduce((a, b) => a.amount > b.amount ? a : b);
  }

  /// Calculates average monthly spending
  static double getAverageMonthlySpending(List<Subscription> subscriptions) {
    if (subscriptions.isEmpty) return 0.0;
    
    final total = calculateTotalSpending(subscriptions, 'Monthly');
    return total / subscriptions.length;
  }
}
