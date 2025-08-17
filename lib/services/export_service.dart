import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/subscription.dart';
import '../utils/helpers.dart';

class ExportService {
  /// Exports subscriptions to CSV format
  static Future<String> exportToCSV(List<Subscription> subscriptions, DateTimeRange? dateRange) async {
    final StringBuffer csv = StringBuffer();
    
    // Add CSV header
    csv.writeln('App Name,Plan Name,Amount,Frequency,Start Date,Category,Next Billing Date,Monthly Cost,Yearly Cost');
    
    // Add data rows
    for (final subscription in subscriptions) {
      // Apply date range filter if specified
      if (dateRange != null) {
        if (subscription.startDate.isBefore(dateRange.start) || 
            subscription.startDate.isAfter(dateRange.end)) {
          continue;
        }
      }
      
      final nextBilling = calculateNextBillingDate(subscription);
      final monthlyCost = normalizeAmountForPeriod(subscription, 'Monthly');
      final yearlyCost = normalizeAmountForPeriod(subscription, 'Yearly');
      
      csv.writeln([
        _escapeCsvField(subscription.appName),
        _escapeCsvField(subscription.planName),
        subscription.amount.toString(),
        _escapeCsvField(subscription.frequency),
        subscription.startDate.toIso8601String().split('T')[0], // Date only
        _escapeCsvField(subscription.category),
        nextBilling.toIso8601String().split('T')[0], // Date only
        monthlyCost.toStringAsFixed(2),
        yearlyCost.toStringAsFixed(2),
      ].join(','));
    }
    
    return csv.toString();
  }

  /// Exports subscriptions to JSON format (for backup/restore)
  static String exportToJSON(List<Subscription> subscriptions) {
    final List<Map<String, dynamic>> data = subscriptions.map((sub) => {
      'appName': sub.appName,
      'planName': sub.planName,
      'amount': sub.amount,
      'frequency': sub.frequency,
      'startDate': sub.startDate.toIso8601String(),
      'category': sub.category,
      'reminderDays': sub.reminderDays,
    }).toList();
    
    return data.toString();
  }

  /// Shares the exported file
  static Future<void> shareFile(String content, String filename, String mimeType) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$filename');
      
      await file.writeAsString(content);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'SubTrackr Export: $filename',
        subject: 'SubTrackr Data Export',
      );
    } catch (e) {
      print('Error sharing file: $e');
      rethrow;
    }
  }

  /// Exports and shares CSV file
  static Future<void> exportAndShareCSV(List<Subscription> subscriptions, DateTimeRange? dateRange) async {
    try {
      final csvContent = await exportToCSV(subscriptions, dateRange);
      
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final filename = 'subtrackr_export_$dateStr.csv';
      
      await shareFile(csvContent, filename, 'text/csv');
    } catch (e) {
      print('Error exporting CSV: $e');
      rethrow;
    }
  }

  /// Exports and shares JSON backup file
  static Future<void> exportAndShareJSON(List<Subscription> subscriptions) async {
    try {
      final jsonContent = exportToJSON(subscriptions);
      
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final filename = 'subtrackr_backup_$dateStr.json';
      
      await shareFile(jsonContent, filename, 'application/json');
    } catch (e) {
      print('Error exporting JSON: $e');
      rethrow;
    }
  }

  /// Escapes CSV fields that contain commas or quotes
  static String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// Gets export summary statistics
  static Map<String, dynamic> getExportSummary(List<Subscription> subscriptions, DateTimeRange? dateRange) {
    final filteredSubs = dateRange != null 
        ? subscriptions.where((s) => s.startDate.isAfter(dateRange.start) && s.startDate.isBefore(dateRange.end)).toList()
        : subscriptions;
    
    final totalMonthly = calculateTotalSpending(filteredSubs, 'Monthly');
    final totalYearly = calculateTotalSpending(filteredSubs, 'Yearly');
    
    return {
      'totalSubscriptions': filteredSubs.length,
      'totalMonthlySpending': totalMonthly,
      'totalYearlySpending': totalYearly,
      'dateRange': dateRange != null 
          ? '${dateRange.start.toLocal().toString().split(' ')[0]} to ${dateRange.end.toLocal().toString().split(' ')[0]}'
          : 'All Time',
    };
  }
}
