import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../db/hive_boxes.dart';
import '../models/subscription.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  DateTimeRange? selectedRange;
  bool showBarChart = true;
  bool showCategoryBreakdown = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            onPressed: _pickDateRange,
            icon: const Icon(Icons.date_range),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                showBarChart = !showBarChart;
              });
            },
            icon: Icon(showBarChart ? Icons.pie_chart : Icons.bar_chart),
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

            final totalSpending = _calculateTotal(subscriptions, start, end);
            final predictionOneMonth = _calculateTotal(subscriptions, now, DateTime(now.year, now.month + 1, now.day));
            final predictionThreeMonths = _calculateTotal(subscriptions, now, DateTime(now.year, now.month + 3, now.day));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSummaryCard(totalSpending),
                const SizedBox(height: 16),
                _buildPredictionCard(predictionOneMonth, predictionThreeMonths),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Spending Trends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        const Text('Category'),
                        Switch(
                          value: showCategoryBreakdown,
                          onChanged: (value) => setState(() => showCategoryBreakdown = value),
                        ),
                        const Text('Cycle'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: showBarChart
                          ? _buildBarChart(subscriptions)
                          : _buildPieChart(subscriptions),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => selectedRange = picked);
    }
  }

  double _calculateTotal(List<Subscription> subs, DateTime start, DateTime end) {
    double total = 0.0;
    for (var sub in subs) {
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
      billing = _getNextBillingDate(freq, billing);
    }

    return total;
  }

  Widget _buildBarChart(List<Subscription> subscriptions) {
    final Map<String, double> monthlyData = {};
    final DateTime now = DateTime.now();
    final DateTime start = DateTime(now.year - 1, now.month);

    for (var sub in subscriptions) {
      if (sub.startDate.isAfter(now)) continue;
      DateTime billing = sub.startDate.isBefore(start) ? start : sub.startDate;

      while (billing.isBefore(now)) {
        final key = '${billing.year}-${billing.month.toString().padLeft(2, '0')}';
        monthlyData[key] = (monthlyData[key] ?? 0) + sub.amount;
        billing = _getNextBillingDate(sub.frequency.toLowerCase(), billing);
      }
    }

    final keys = monthlyData.keys.toList()..sort();
    final spots = keys.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), monthlyData[entry.value]!);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                int index = value.toInt();
                if (index >= 0 && index < keys.length) {
                  return Text(keys[index].split('-')[1]); // Show month only
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withAlpha((255 * 0.3).toInt()),
            ),
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
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

  Widget _buildPredictionCard(double one, double three) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.orangeAccent,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Spending Prediction', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Next 1 Month: ₹${one.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 6),
            Text('Next 3 Months: ₹${three.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double totalSpending) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xff2193b0), Color(0xff6dd5ed)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('Total Spending', style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 8),
          Text('₹${totalSpending.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            selectedRange == null
                ? 'This Month'
                : '${selectedRange!.start.toLocal().toString().split(' ')[0]} → ${selectedRange!.end.toLocal().toString().split(' ')[0]}',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(List<Subscription> subs) {
    final data = showCategoryBreakdown
        ? _groupSpendingByCategory(subs)
        : _groupSpendingByFrequency(subs);

    final sections = data.entries.map((e) {
      return PieChartSectionData(
        value: e.value,
        title: '${e.key}\n₹${e.value.toStringAsFixed(0)}',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 30,
        sectionsSpace: 2,
      ),
    );
  }

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
