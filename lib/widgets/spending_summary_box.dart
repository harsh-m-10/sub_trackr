import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../providers/currency_provider.dart';

class SpendingSummaryBox extends StatelessWidget {
  final String selectedPeriod;
  final double totalSpending;
  final ValueChanged<String> onPeriodChanged;

  const SpendingSummaryBox({
    super.key,
    required this.selectedPeriod,
    required this.totalSpending,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final screenSize = MediaQuery.of(context).size;
    final padding = screenSize.width * 0.04; // 4% of screen width
    final spacing = screenSize.height * 0.01; // 1% of screen height
    
    return Container(
      width: double.infinity,
      height: double.infinity, // Use full height from parent
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff2193b0), Color(0xff6dd5ed)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(screenSize.width * 0.03),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Total $selectedPeriod Spending',
            style: TextStyle(
              fontSize: screenSize.width * 0.045, // 4.5% of screen width
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: spacing * 0.8),
          Text(
            formatCurrency(totalSpending, currencyProvider.selectedCurrency),
            style: TextStyle(
              fontSize: screenSize.width * 0.08, // 8% of screen width
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: spacing * 1.2),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: padding * 0.6,
              vertical: padding * 0.2,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(screenSize.width * 0.05),
            ),
            child: DropdownButton<String>(
              value: selectedPeriod,
              dropdownColor: const Color(0xff2193b0),
              style: TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.w600,
                fontSize: screenSize.width * 0.04, // 4% of screen width
              ),
              underline: Container(),
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: screenSize.width * 0.05,
              ),
              items: ['Weekly', 'Monthly', 'Yearly']
                  .map((period) => DropdownMenuItem(
                        value: period,
                        child: Text(
                          period,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenSize.width * 0.04,
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  onPeriodChanged(value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
