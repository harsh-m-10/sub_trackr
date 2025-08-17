import 'package:sub_trackr/models/subscription.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

/// Responsive sizing utilities for consistent UX across different screen sizes
class ResponsiveSizing {
  static double getScreenWidth(BuildContext context) => MediaQuery.of(context).size.width;
  static double getScreenHeight(BuildContext context) => MediaQuery.of(context).size.height;
  
  // Padding and spacing based on screen width (4% of screen width)
  static double getPadding(BuildContext context) => getScreenWidth(context) * 0.04;
  
  // Spacing between elements based on screen height (2% of screen height)
  static double getSpacing(BuildContext context) => getScreenHeight(context) * 0.02;
  
  // Field heights based on screen height (6% of screen height)
  static double getFieldHeight(BuildContext context) => getScreenHeight(context) * 0.06;
  
  // Font sizes based on screen width
  static double getTitleFontSize(BuildContext context) => getScreenWidth(context) * 0.06;
  static double getHeadingFontSize(BuildContext context) => getScreenWidth(context) * 0.045;
  static double getBodyFontSize(BuildContext context) => getScreenWidth(context) * 0.04;
  static double getSmallFontSize(BuildContext context) => getScreenWidth(context) * 0.035;
  static double getCaptionFontSize(BuildContext context) => getScreenWidth(context) * 0.03;
  
  // Icon sizes based on screen width
  static double getIconSize(BuildContext context) => getScreenWidth(context) * 0.05;
  static double getSmallIconSize(BuildContext context) => getScreenWidth(context) * 0.04;
  
  // Border radius based on screen width
  static double getBorderRadius(BuildContext context) => getScreenWidth(context) * 0.03;
  static double getLargeBorderRadius(BuildContext context) => getScreenWidth(context) * 0.05;
  
  // Button heights based on screen height
  static double getButtonHeight(BuildContext context) => getScreenHeight(context) * 0.06;
  static double getLargeButtonHeight(BuildContext context) => getScreenHeight(context) * 0.08;
}

/// Returns the next billing date given a frequency string and a base date.
///
/// Supported frequencies:
/// - 'Weekly', 'Monthly', 'Yearly'
/// - Custom: strings like 'Every 2 Weeks' or 'Every 3 Months'
DateTime getNextBillingDateFrom(String frequency, DateTime from) {
  final String freq = frequency.toLowerCase();

  if (freq == 'weekly') return from.add(const Duration(days: 7));
  if (freq == 'monthly') return DateTime(from.year, from.month + 1, from.day);
  if (freq == 'yearly') return DateTime(from.year + 1, from.month, from.day);

  if (freq.startsWith('every')) {
    final parts = freq.split(' ');
    if (parts.length >= 3) {
      final int n = int.tryParse(parts[1]) ?? 1;
      final String unit = parts[2];
      if (unit.startsWith('week')) return from.add(Duration(days: 7 * n));
      if (unit.startsWith('month')) return DateTime(from.year, from.month + n, from.day);
      if (unit.startsWith('year')) return DateTime(from.year + n, from.month, from.day);
    }
  }

  // Fallback: roughly one month later
  return DateTime(from.year, from.month + 1, from.day);
}

/// Calculates the next billing date for a subscription based on its start date
/// and frequency.
DateTime calculateNextBillingDate(Subscription subscription) {
  return getNextBillingDateFrom(subscription.frequency, subscription.startDate);
}

/// Normalizes a subscription's amount into a target period ('Weekly' | 'Monthly' | 'Yearly').
///
/// Heuristics used (kept consistent with existing UI logic):
/// - 1 month ≈ 4 weeks for conversions
double normalizeAmountForPeriod(Subscription subscription, String targetPeriod) {
  final String freq = subscription.frequency.toLowerCase();
  final double amount = subscription.amount;
  final String period = targetPeriod.toLowerCase();

  if (period == 'monthly') {
    if (freq.contains('monthly')) return amount;
    if (freq.contains('weekly')) return amount * 4;
    if (freq.contains('yearly')) return amount / 12;
    if (freq.startsWith('every')) {
      final parts = freq.split(' ');
      if (parts.length >= 3) {
        final int n = int.tryParse(parts[1]) ?? 1;
        final String unit = parts[2];
        if (unit.startsWith('week')) return amount * 4 / n;
        if (unit.startsWith('month')) return amount / n;
        if (unit.startsWith('year')) return amount / (12 * n);
      }
    }
  }

  if (period == 'weekly') {
    if (freq.contains('weekly')) return amount;
    if (freq.contains('monthly')) return amount / 4;
    if (freq.contains('yearly')) return amount / 52;
    if (freq.startsWith('every')) {
      final parts = freq.split(' ');
      if (parts.length >= 3) {
        final int n = int.tryParse(parts[1]) ?? 1;
        final String unit = parts[2];
        if (unit.startsWith('week')) return amount / n;
        if (unit.startsWith('month')) return amount / (n * 4);
        if (unit.startsWith('year')) return amount / (n * 52);
      }
    }
  }

  if (period == 'yearly') {
    if (freq.contains('yearly')) return amount;
    if (freq.contains('monthly')) return amount * 12;
    if (freq.contains('weekly')) return amount * 52;
    if (freq.startsWith('every')) {
      final parts = freq.split(' ');
      if (parts.length >= 3) {
        final int n = int.tryParse(parts[1]) ?? 1;
        final String unit = parts[2];
        if (unit.startsWith('week')) return amount * 52 / n;
        if (unit.startsWith('month')) return amount * 12 / n;
        if (unit.startsWith('year')) return amount / n;
      }
    }
  }

  return 0.0;
}

/// Formats currency amount with proper symbol and decimal places
String formatCurrency(double amount, String currencySymbol) {
  // Handle different currency formatting
  switch (currencySymbol) {
    case '₹': // Indian Rupee
      return '₹${amount.toStringAsFixed(2)}';
    case '¥': // Japanese Yen
      return '¥${amount.toInt()}';
    case '₩': // Korean Won
      return '₩${amount.toInt()}';
    case '₽': // Russian Ruble
      return '₽${amount.toStringAsFixed(2)}';
    case '₦': // Nigerian Naira
      return '₦${amount.toStringAsFixed(2)}';
    default: // USD, EUR, GBP, etc.
      return '$currencySymbol${amount.toStringAsFixed(2)}';
  }
}

/// Formats date in a user-friendly way
String formatDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date).inDays;
  
  if (difference == 0) return 'Today';
  if (difference == 1) return 'Yesterday';
  if (difference < 7) return '${difference} days ago';
  if (difference < 30) return '${(difference / 7).floor()} weeks ago';
  if (difference < 365) return '${(difference / 30).floor()} months ago';
  
  return DateFormat('MMM yyyy').format(date);
}

/// Gets a readable frequency description
String getReadableFrequency(String frequency) {
  final freq = frequency.toLowerCase();
  if (freq == 'weekly') return 'Weekly';
  if (freq == 'monthly') return 'Monthly';
  if (freq == 'yearly') return 'Yearly';
  if (freq.startsWith('every')) {
    final parts = freq.split(' ');
    if (parts.length >= 3) {
      final n = int.tryParse(parts[1]) ?? 1;
      final unit = parts[2];
      if (unit.startsWith('week')) return 'Every $n week${n > 1 ? 's' : ''}';
      if (unit.startsWith('month')) return 'Every $n month${n > 1 ? 's' : ''}';
      if (unit.startsWith('year')) return 'Every $n year${n > 1 ? 's' : ''}';
    }
  }
  return frequency;
}

/// Calculates total spending for a list of subscriptions
double calculateTotalSpending(List<Subscription> subscriptions, String period) {
  return subscriptions.fold(0.0, (sum, sub) => sum + normalizeAmountForPeriod(sub, period));
}

/// Gets spending insights for analytics
Map<String, dynamic> getSpendingInsights(List<Subscription> subscriptions) {
  if (subscriptions.isEmpty) {
    return {
      'biggestExpense': null,
      'totalMonthly': 0.0,
      'totalYearly': 0.0,
      'categoryBreakdown': {},
      'savingsOpportunity': null,
      'subscriptions': subscriptions, // Include subscriptions for proper currency conversion
    };
  }

  // Find biggest expense
  final biggestExpense = subscriptions.reduce((a, b) => a.amount > b.amount ? a : b);
  
  // Calculate totals
  final totalMonthly = calculateTotalSpending(subscriptions, 'Monthly');
  final totalYearly = calculateTotalSpending(subscriptions, 'Yearly');
  
  // Category breakdown
  final categoryBreakdown = <String, double>{};
  for (final sub in subscriptions) {
    final category = sub.category.isNotEmpty ? sub.category : 'Other';
    categoryBreakdown[category] = (categoryBreakdown[category] ?? 0) + sub.amount;
  }
  
  // Find potential savings (expensive subscriptions)
  final expensiveSubs = subscriptions.where((s) => s.amount > totalMonthly * 0.3).toList();
  final savingsOpportunity = expensiveSubs.isNotEmpty ? expensiveSubs.first : null;
  
  return {
    'biggestExpense': biggestExpense,
    'totalMonthly': totalMonthly,
    'totalYearly': totalYearly,
    'categoryBreakdown': categoryBreakdown,
    'savingsOpportunity': savingsOpportunity,
    'subscriptions': subscriptions, // Include subscriptions for proper currency conversion
  };
}
