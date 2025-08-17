import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../db/hive_boxes.dart';
import '../models/subscription.dart';
import '../widgets/banner_ad_widget.dart';
import '../utils/helpers.dart';
import '../services/export_service.dart';
import '../services/currency_conversion_service.dart';
import '../providers/currency_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  DateTimeRange? selectedRange;
  bool showCategoryBreakdown = true;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            onPressed: _pickDateRange,
            icon: const Icon(Icons.date_range),
            tooltip: 'Select Date Range',
          ),
          IconButton(
            onPressed: _exportData,
            icon: const Icon(Icons.download),
            tooltip: 'Export Data',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ValueListenableBuilder(
          valueListenable: HiveBoxes.getSubscriptionsBox().listenable(),
          builder: (context, box, _) {
            final List<Subscription> subscriptions = box.values.toList();
            final DateTime now = DateTime.now();
            final DateTime start = selectedRange?.start ?? DateTime(now.year, now.month, 1);
            final DateTime end = selectedRange?.end ?? now;

            return Consumer<CurrencyProvider>(
              builder: (context, currencyProvider, child) {
                return FutureBuilder<List<double>>(
                  future: Future.wait([
                    _calculateTotalWithConversion(subscriptions, start, end, currencyProvider.selectedCurrency),
                    _calculateTotalWithConversion(subscriptions, now, DateTime(now.year, now.month + 1, now.day), currencyProvider.selectedCurrency),
                    _calculateTotalWithConversion(subscriptions, now, DateTime(now.year, now.month + 3, now.day), currencyProvider.selectedCurrency),
                  ]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(child: CircularProgressIndicator()),
                          SizedBox(height: 16),
                          Center(child: Text('Converting currencies...')),
                        ],
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(child: Text('Error loading data')),
                        ],
                      );
                    }

                    final results = snapshot.data!;
                    final totalSpending = results[0];
                    final predictionOneMonth = results[1];
                    final predictionThreeMonths = results[2];
                    
                    // Get insights using helper function
                    final insights = getSpendingInsights(subscriptions);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSummaryCard(totalSpending),
                        SizedBox(height: screenSize.height * 0.02),
                        _buildInsightsCards(insights),
                        SizedBox(height: screenSize.height * 0.02),
                        _buildPredictionCard(predictionOneMonth, predictionThreeMonths),
                        SizedBox(height: screenSize.height * 0.03),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Spending Breakdown',
                              style: TextStyle(
                                fontSize: screenSize.width * 0.045,
                                fontWeight: FontWeight.bold
                              )
                            ),
                            Row(
                              children: [
                                Text(
                                  'Category',
                                  style: TextStyle(fontSize: screenSize.width * 0.035)
                                ),
                                Switch(
                                  value: showCategoryBreakdown,
                                  onChanged: (value) => setState(() => showCategoryBreakdown = value),
                                ),
                                Text(
                                  'Cycle',
                                  style: TextStyle(fontSize: screenSize.width * 0.035)
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: screenSize.height * 0.015),
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                child: Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenSize.width * 0.03)),
                                  elevation: 4,
                                  child: Padding(
                                    padding: EdgeInsets.all(screenSize.width * 0.03),
                                    child: _buildPieChart(subscriptions),
                                  ),
                                ),
                              ),
                              SizedBox(height: screenSize.height * 0.01),
                              // Banner ad at the bottom with standard size
                              const BannerAdWidget(useStandardSize: true),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    try {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        setState(() => selectedRange = picked);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting date range: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportData() async {
    try {
      final box = HiveBoxes.getSubscriptionsBox();
      final subscriptions = box.values.cast<Subscription>().toList();
      
      await ExportService.exportAndShareCSV(subscriptions, selectedRange);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double _calculateTotal(List<Subscription> subs, DateTime start, DateTime end) {
    double total = 0.0;
    for (var sub in subs) {
      total += _estimateCostWithinRange(sub, start, end);
    }
    return total;
  }

  Future<double> _calculateTotalWithConversion(List<Subscription> subs, DateTime start, DateTime end, String targetCurrency) async {
    double total = 0.0;
    for (var sub in subs) {
      final originalAmount = _estimateCostWithinRange(sub, start, end);
      final convertedAmount = await CurrencyConversionService.convertAmount(
        originalAmount,
        sub.currency,
        targetCurrency,
      );
      total += convertedAmount;
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
      billing = _getNextBillingDate(freq, billing);
    }

    return total;
  }

  DateTime _getNextBillingDate(String freq, DateTime from) {
    if (freq == 'monthly') return DateTime(from.year, from.month + 1, from.day);
    if (freq == 'weekly') return from.add(const Duration(days: 7));
    if (freq == 'yearly') return DateTime(from.year + 1, from.month, from.day);

    if (freq.startsWith('every')) {
      final parts = freq.split(' ');
      if (parts.length >= 3) {
        final n = int.tryParse(parts[1]) ?? 1;
        if (parts[2].contains('week')) return from.add(Duration(days: 7 * n));
        if (parts[2].contains('month')) return DateTime(from.year, from.month + n, from.day);
      }
    }

    return from.add(const Duration(days: 30)); // fallback
  }

  Widget _buildInsightsCards(Map<String, dynamic> insights) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final screenSize = MediaQuery.of(context).size;
    
    return FutureBuilder<Map<String, dynamic>>(
      future: _getConvertedInsights(insights, currencyProvider.selectedCurrency),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Row(
            children: [
              Expanded(child: Center(child: CircularProgressIndicator())),
              SizedBox(width: 12),
              Expanded(child: Center(child: CircularProgressIndicator())),
            ],
          );
        }

        if (!snapshot.hasData) {
          return const Row(
            children: [
              Expanded(child: Center(child: Text('Error loading insights'))),
              SizedBox(width: 12),
              Expanded(child: Center(child: Text('Error loading insights'))),
            ],
          );
        }

        final convertedInsights = snapshot.data!;
        
        return Row(
          children: [
            Expanded(
              child: _buildInsightCard(
                'Biggest Expense',
                insights['biggestExpense'] != null 
                    ? insights['biggestExpense'].appName 
                    : 'None',
                insights['biggestExpense'] != null 
                    ? formatCurrency(convertedInsights['biggestExpenseAmount'], currencyProvider.selectedCurrency)
                    : formatCurrency(0, currencyProvider.selectedCurrency),
                Icons.trending_up,
                Colors.red,
              ),
            ),
            SizedBox(width: screenSize.width * 0.03),
            Expanded(
              child: _buildInsightCard(
                'Monthly Total',
                'Recurring Cost',
                formatCurrency(convertedInsights['totalMonthly'], currencyProvider.selectedCurrency),
                Icons.calendar_month,
                Colors.blue,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, double>> _getConvertedInsights(Map<String, dynamic> insights, String targetCurrency) async {
    final Map<String, double> convertedInsights = {};
    
    // Convert biggest expense amount
    if (insights['biggestExpense'] != null) {
      final biggestExpense = insights['biggestExpense'] as Subscription;
      convertedInsights['biggestExpenseAmount'] = await CurrencyConversionService.convertAmount(
        biggestExpense.amount,
        biggestExpense.currency,
        targetCurrency,
      );
    }
    
    // For total monthly, we need to recalculate it properly from subscriptions
    // instead of assuming it's in USD
    if (insights['subscriptions'] != null) {
      final subscriptions = insights['subscriptions'] as List<Subscription>;
      double totalMonthly = 0.0;
      
      for (final sub in subscriptions) {
        final monthlyAmount = normalizeAmountForPeriod(sub, 'Monthly');
        final convertedAmount = await CurrencyConversionService.convertAmount(
          monthlyAmount,
          sub.currency,
          targetCurrency,
        );
        totalMonthly += convertedAmount;
      }
      
      convertedInsights['totalMonthly'] = totalMonthly;
    } else {
      // Fallback: if no subscriptions data, use the original value
      // but this should not happen in normal flow
      convertedInsights['totalMonthly'] = insights['totalMonthly'] ?? 0.0;
    }
    
    return convertedInsights;
  }

  Widget _buildInsightCard(String title, String subtitle, String value, IconData icon, Color color) {
    final screenSize = MediaQuery.of(context).size;
    final padding = screenSize.width * 0.04;
    final spacing = screenSize.height * 0.01;
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenSize.width * 0.03)),
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: screenSize.width * 0.05),
                SizedBox(width: spacing),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: screenSize.width * 0.035,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing * 0.8),
            Text(
              value,
              style: TextStyle(
                fontSize: screenSize.width * 0.05,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: spacing * 0.4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: screenSize.width * 0.03,
                color: Colors.grey,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionCard(double one, double three) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final screenSize = MediaQuery.of(context).size;
    final padding = screenSize.width * 0.04;
    final spacing = screenSize.height * 0.01;
    
    return FutureBuilder<Map<String, double>>(
      future: _getConvertedPredictions(one, three, currencyProvider.selectedCurrency),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenSize.width * 0.03)),
            color: Colors.orangeAccent,
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenSize.width * 0.03)),
            color: Colors.orangeAccent,
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Center(child: Text('Error loading predictions', style: TextStyle(color: Colors.white, fontSize: screenSize.width * 0.04))),
            ),
          );
        }

        final convertedPredictions = snapshot.data!;
        
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenSize.width * 0.03)),
          color: Colors.orangeAccent,
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              children: [
                Text(
                  'Spending Prediction',
                  style: TextStyle(
                    fontSize: screenSize.width * 0.045,
                    color: Colors.white,
                    fontWeight: FontWeight.bold
                  )
                ),
                SizedBox(height: spacing * 0.8),
                Text(
                  'Next 1 Month: ${formatCurrency(convertedPredictions['oneMonth'] ?? 0.0, currencyProvider.selectedCurrency)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenSize.width * 0.04
                  )
                ),
                SizedBox(height: spacing * 0.6),
                Text(
                  'Next 3 Months: ${formatCurrency(convertedPredictions['threeMonths'] ?? 0.0, currencyProvider.selectedCurrency)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenSize.width * 0.04
                  )
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, double>> _getConvertedPredictions(double oneMonth, double threeMonths, String targetCurrency) async {
    final Map<String, double> convertedPredictions = {};
    
    // The predictions are already calculated in the target currency from the main calculation
    // so we don't need to convert them again - just return them as is
    convertedPredictions['oneMonth'] = oneMonth;
    convertedPredictions['threeMonths'] = threeMonths;
    
    return convertedPredictions;
  }

  Widget _buildSummaryCard(double totalSpending) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final screenSize = MediaQuery.of(context).size;
    final padding = screenSize.width * 0.06;
    final spacing = screenSize.height * 0.01;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(screenSize.width * 0.04),
        gradient: const LinearGradient(
          colors: [Color(0xff2193b0), Color(0xff6dd5ed)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.all(padding),
      child: Column(
        children: [
          Text(
            'Total Spending',
            style: TextStyle(
              color: Colors.white,
              fontSize: screenSize.width * 0.045
            )
          ),
          SizedBox(height: spacing * 0.8),
          Text(
            formatCurrency(totalSpending, currencyProvider.selectedCurrency),
            style: TextStyle(
              fontSize: screenSize.width * 0.08,
              color: Colors.white,
              fontWeight: FontWeight.bold
            )
          ),
          SizedBox(height: spacing * 0.8),
          Text(
            selectedRange == null
                ? 'This Month'
                : '${selectedRange!.start.toLocal().toString().split(' ')[0]} → ${selectedRange!.end.toLocal().toString().split(' ')[0]}',
            style: TextStyle(
              color: Colors.white70,
              fontSize: screenSize.width * 0.035
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(List<Subscription> subs) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final screenSize = MediaQuery.of(context).size;
    
    return FutureBuilder<Map<String, double>>(
      future: showCategoryBreakdown
          ? _groupSpendingByCategoryWithConversion(subs, currencyProvider.selectedCurrency)
          : _groupSpendingByFrequencyWithConversion(subs, currencyProvider.selectedCurrency),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: screenSize.height * 0.02),
                Text(
                  'Converting currencies...',
                  style: TextStyle(fontSize: screenSize.width * 0.035),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.pie_chart_outline,
                  size: screenSize.width * 0.16,
                  color: Colors.grey,
                ),
                SizedBox(height: screenSize.height * 0.02),
                Text(
                  'No data to display',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: screenSize.width * 0.04
                  ),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data!;
        
        return Column(
          children: [
            // Chart title and CTA button
            Padding(
              padding: EdgeInsets.only(bottom: screenSize.height * 0.015),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
              child: Text(
                showCategoryBreakdown ? 'Spending by Category' : 'Spending by Frequency',
                style: TextStyle(
                        fontSize: screenSize.width * 0.04,
                  fontWeight: FontWeight.w600,
                ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showFullScreenChart(context, data, currencyProvider.selectedCurrency, showCategoryBreakdown),
                    icon: Icon(Icons.pie_chart, size: screenSize.width * 0.04),
                    label: Text(
                      'View Chart',
                      style: TextStyle(fontSize: screenSize.width * 0.035),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenSize.width * 0.02,
                        vertical: screenSize.height * 0.008,
                      ),
                      textStyle: TextStyle(fontSize: screenSize.width * 0.035),
                    ),
                  ),
                ],
              ),
            ),
            
            // Summary information instead of chart
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.02),
                child: Column(
                  children: [
                    // Top categories summary
                    Expanded(
                      child: data.isEmpty 
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.pie_chart_outline,
                                  size: screenSize.width * 0.12,
                                  color: Colors.grey.withOpacity(0.6),
                                ),
                                SizedBox(height: screenSize.height * 0.02),
                                Text(
                                  'No data available',
                                  style: TextStyle(
                                    fontSize: screenSize.width * 0.04,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: data.length,
                            itemBuilder: (context, index) {
                              final entry = data.entries.elementAt(index);
                              final category = entry.key;
                              final amount = entry.value;
                              final color = _getColorForCategory(category);
                              
                              return Padding(
                                padding: EdgeInsets.only(bottom: screenSize.height * 0.01),
                                child: Row(
                                  children: [
                                    // Color indicator
                                    Container(
                                      width: screenSize.width * 0.03,
                                      height: screenSize.width * 0.03,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: screenSize.width * 0.02),
                                    // Category name
                                    Expanded(
                                      child: Text(
                                        category,
                                        style: TextStyle(
                                          fontSize: screenSize.width * 0.035,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    // Amount
                                    Text(
                                      formatCurrency(amount, currencyProvider.selectedCurrency),
                                      style: TextStyle(
                                        fontSize: screenSize.width * 0.035,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                    ),
                    
                    // Summary footer
                    if (data.isNotEmpty) ...[
                      Divider(height: 1, color: Colors.grey.withOpacity(0.3)),
                      SizedBox(height: screenSize.height * 0.01),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: screenSize.width * 0.035,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            formatCurrency(
                              data.values.reduce((a, b) => a + b),
                              currencyProvider.selectedCurrency
                            ),
                            style: TextStyle(
                              fontSize: screenSize.width * 0.035,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Compact legend below (inside the card)
            if (data.length > 1) ...[
              SizedBox(height: screenSize.height * 0.015),
              _buildCompactChartLegend(data, currencyProvider.selectedCurrency, screenSize),
            ],
          ],
        );
      },
    );
  }

  /// Build compact legend that fits within the card
  Widget _buildCompactChartLegend(Map<String, double> data, String currency, Size screenSize) {
    final legendItems = data.entries.toList();
    
    return Container(
      padding: EdgeInsets.all(screenSize.width * 0.015),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(screenSize.width * 0.02),
      ),
      child: Wrap(
        spacing: screenSize.width * 0.015,
        runSpacing: screenSize.height * 0.008,
        alignment: WrapAlignment.center,
        children: legendItems.map((entry) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: screenSize.width * 0.025,
                height: screenSize.width * 0.025,
                decoration: BoxDecoration(
                  color: _getColorForCategory(entry.key),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: screenSize.width * 0.008),
              Flexible(
                child: Text(
                  '${entry.key}: ${formatCurrency(entry.value, currency)}',
                  style: TextStyle(
                    fontSize: screenSize.width * 0.028,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// Show full-screen chart modal
  void _showFullScreenChart(BuildContext context, Map<String, double> data, String currency, bool isCategoryBreakdown) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Header with close button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isCategoryBreakdown ? 'Spending by Category' : 'Spending by Frequency',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
                
                // Full-screen chart with proper constraints
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _buildFullScreenPieChart(data, currency),
                  ),
                ),
                
                // Full legend at bottom
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: _buildFullScreenLegend(data, currency),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build full-screen pie chart with proper sizing
  Widget _buildFullScreenPieChart(Map<String, double> data, String currency) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate chart size based on available space
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;
        
        // Use the smaller dimension to ensure chart fits
        final chartSize = (availableWidth < availableHeight ? availableWidth : availableHeight) * 0.7;
        final chartRadius = chartSize / 2;
        
        final sections = data.entries.map((e) {
          final color = _getColorForCategory(e.key);
          return PieChartSectionData(
            value: e.value,
            title: '${e.key}\n${formatCurrency(e.value, currency)}',
            radius: chartRadius,
            titleStyle: TextStyle(
              fontSize: chartRadius * 0.15, // Responsive font size
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            color: color,
            titlePositionPercentageOffset: 0.8,
          );
        }).toList();

        return Center(
          child: Container(
            width: chartSize,
            height: chartSize,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: chartRadius * 0.3,
                sectionsSpace: 2,
                pieTouchData: PieTouchData(
                  enabled: true,
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    // Handle touch events if needed
                  },
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build full-screen legend
  Widget _buildFullScreenLegend(Map<String, double> data, String currency) {
    final legendItems = data.entries.toList();
    
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: legendItems.map((entry) {
    return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
            color: _getColorForCategory(entry.key).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getColorForCategory(entry.key),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _getColorForCategory(entry.key),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${entry.key}: ${formatCurrency(entry.value, currency)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          );
        }).toList(),
    );
  }

  Color _getColorForCategory(String category) {
    // Generate consistent colors for categories
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
    ];
    
    final index = category.hashCode % colors.length;
    return colors[index];
  }

  Future<Map<String, double>> _groupSpendingByFrequencyWithConversion(List<Subscription> subs, String targetCurrency) async {
    final Map<String, double> freqMap = {};
    
    for (var sub in subs) {
      final freq = sub.frequency.toLowerCase().contains('week')
          ? 'Weekly'
          : sub.frequency.toLowerCase().contains('year')
              ? 'Yearly'
              : 'Monthly';
      
      final convertedAmount = await CurrencyConversionService.convertAmount(
        sub.amount, 
        sub.currency, 
        targetCurrency
      );
      
      freqMap[freq] = (freqMap[freq] ?? 0) + convertedAmount;
    }
    
    return freqMap;
  }

  Future<Map<String, double>> _groupSpendingByCategoryWithConversion(List<Subscription> subs, String targetCurrency) async {
    final Map<String, double> catMap = {};
    
    for (var sub in subs) {
      final cat = sub.category.isNotEmpty ? sub.category : 'Other';
      
      final convertedAmount = await CurrencyConversionService.convertAmount(
        sub.amount, 
        sub.currency, 
        targetCurrency
      );
      
      catMap[cat] = (catMap[cat] ?? 0) + convertedAmount;
    }
    
    return catMap;
  }

  // Keep original methods for backward compatibility
  Map<String, double> _groupSpendingByFrequency(List<Subscription> subs) {
    final Map<String, double> freqMap = {};
    for (var sub in subs) {
      final freq = sub.frequency.toLowerCase().contains('week')
          ? 'Weekly'
          : sub.frequency.toLowerCase().contains('year')
              ? 'Yearly'
              : 'Monthly';
      freqMap[freq] = (freqMap[freq] ?? 0) + sub.amount;
    }
    return freqMap;
  }

  Map<String, double> _groupSpendingByCategory(List<Subscription> subs) {
    final Map<String, double> catMap = {};
    for (var sub in subs) {
      final cat = sub.category.isNotEmpty ? sub.category : 'Other';
      catMap[cat] = (catMap[cat] ?? 0) + sub.amount;
    }
    return catMap;
  }
}
