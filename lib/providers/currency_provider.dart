import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../services/currency_conversion_service.dart';

class CurrencyProvider extends ChangeNotifier {
  String _selectedCurrency = AppConstants.defaultCurrency;
  static const String _currencyKey = 'selected_currency';

  String get selectedCurrency => _selectedCurrency;

  CurrencyProvider() {
    _loadSavedCurrency();
  }

  Future<void> _loadSavedCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCurrency = prefs.getString(_currencyKey);
      if (savedCurrency != null && AppConstants.availableCurrencies.contains(savedCurrency)) {
        _selectedCurrency = savedCurrency;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading saved currency: $e');
    }
  }

  Future<void> setCurrency(String currency) async {
    if (AppConstants.availableCurrencies.contains(currency) && currency != _selectedCurrency) {
      _selectedCurrency = currency;
      notifyListeners();
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_currencyKey, currency);
      } catch (e) {
        print('Error saving currency: $e');
      }
    }
  }

  Future<void> resetToDefault() async {
    await setCurrency(AppConstants.defaultCurrency);
  }

  /// Convert amount from original currency to selected currency
  Future<double> convertAmount(double amount, String originalCurrency) async {
    if (originalCurrency == _selectedCurrency) {
      return amount;
    }
    
    try {
      return await CurrencyConversionService.convertAmount(amount, originalCurrency, _selectedCurrency);
    } catch (e) {
      print('Error converting currency: $e');
      return amount; // Fallback to original amount
    }
  }

  /// Get formatted amount with conversion
  Future<String> getFormattedAmount(double amount, String originalCurrency) async {
    final convertedAmount = await convertAmount(amount, originalCurrency);
    return '${_selectedCurrency}${convertedAmount.toStringAsFixed(2)}';
  }

  /// Get conversion info for debugging
  Future<Map<String, dynamic>> getConversionInfo(double amount, String originalCurrency) async {
    if (originalCurrency == _selectedCurrency) {
      return {
        'original': '$originalCurrency$amount',
        'converted': '$_selectedCurrency$amount',
        'rate': 1.0,
        'converted': false,
      };
    }

    try {
      final rate = await CurrencyConversionService.getExchangeRate(originalCurrency, _selectedCurrency);
      final convertedAmount = amount * rate;
      
      return {
        'original': '$originalCurrency$amount',
        'converted': '$_selectedCurrency${convertedAmount.toStringAsFixed(2)}',
        'rate': rate,
        'converted': true,
      };
    } catch (e) {
      return {
        'original': '$originalCurrency$amount',
        'converted': '$_selectedCurrency$amount (conversion failed)',
        'rate': 1.0,
        'error': e.toString(),
      };
    }
  }
}
