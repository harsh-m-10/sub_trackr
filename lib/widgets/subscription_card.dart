import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subscription.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../providers/currency_provider.dart';

class SubscriptionCard extends StatelessWidget {
  final Subscription subscription;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SubscriptionCard({
    super.key,
    required this.subscription,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final screenSize = MediaQuery.of(context).size;
    final padding = screenSize.width * 0.04; // 4% of screen width
    final spacing = screenSize.height * 0.01; // 1% of screen height
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenSize.width * 0.03),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subscription.appName,
                        style: TextStyle(
                          fontSize: screenSize.width * 0.045, // 4.5% of screen width
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (subscription.planName.isNotEmpty) ...[
                        SizedBox(height: spacing),
                        Text(
                          subscription.planName,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: screenSize.width * 0.035, // 3.5% of screen width
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FutureBuilder<String>(
                      future: currencyProvider.getFormattedAmount(subscription.amount, subscription.currency),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return SizedBox(
                            width: screenSize.width * 0.05,
                            height: screenSize.width * 0.05,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        }
                        
                        final formattedAmount = snapshot.data ?? '${subscription.currency}${subscription.amount.toStringAsFixed(2)}';
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formattedAmount,
                              style: TextStyle(
                                fontSize: screenSize.width * 0.05, // 5% of screen width
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            if (subscription.currency != currencyProvider.selectedCurrency) ...[
                              Text(
                                '${subscription.currency}${subscription.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: screenSize.width * 0.03, // 3% of screen width
                                  color: Colors.grey[600],
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                    Text(
                      subscription.frequency,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: screenSize.width * 0.03, // 3% of screen width
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (subscription.category.isNotEmpty) ...[
              SizedBox(height: spacing * 1.2),
              Wrap(
                spacing: spacing,
                runSpacing: spacing * 0.5,
                children: subscription.category.split(', ').map((cat) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: padding * 0.5,
                      vertical: padding * 0.25,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(screenSize.width * 0.03),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: screenSize.width * 0.03, // 3% of screen width
                        color: Colors.blue[700],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (onEdit != null || onDelete != null) ...[
              SizedBox(height: spacing * 1.6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onEdit != null)
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: Icon(Icons.edit, size: screenSize.width * 0.045),
                      label: Text(
                        'Edit',
                        style: TextStyle(fontSize: screenSize.width * 0.035),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(
                          horizontal: padding * 0.5,
                          vertical: spacing,
                        ),
                      ),
                    ),
                  if (onEdit != null && onDelete != null)
                    SizedBox(width: spacing),
                  if (onDelete != null)
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: Icon(Icons.delete, size: screenSize.width * 0.045),
                      label: Text(
                        'Delete',
                        style: TextStyle(fontSize: screenSize.width * 0.035),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(
                          horizontal: padding * 0.5,
                          vertical: spacing,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
