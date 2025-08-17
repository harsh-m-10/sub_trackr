import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class CurrencyConversionService {
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest/';
  static const String _cacheKey = 'currency_rates_cache';
  static const String _cacheTimestampKey = 'currency_rates_timestamp';
  static const int _cacheDurationHours = 24;

  // Cache for exchange rates
  static Map<String, double> _cachedRates = {};
  static DateTime? _lastCacheTime;

  // Currency symbol to code mapping
  static const Map<String, String> _currencySymbols = {
    '\$': 'USD',
    '₹': 'INR',
    '€': 'EUR',
    '£': 'GBP',
    '¥': 'JPY',
    '₽': 'RUB',
    '₩': 'KRW',
    '₪': 'ILS',
    '₨': 'PKR',
    '₦': 'NGN',
    '₡': 'CRC',
    '₫': 'VND',
    '₱': 'PHP',
    '₲': 'PYG',
    '₴': 'UAH',
    '₸': 'KZT',
    '₺': 'TRY',
    '₼': 'AZN',
    '₾': 'GEL',
    '₿': 'BTC',
  };

  /// Convert currency symbol to currency code
  static String _getCurrencyCode(String currencySymbol) {
    return _currencySymbols[currencySymbol] ?? currencySymbol;
  }

  /// Get exchange rate between two currencies
  static Future<double> getExchangeRate(String fromCurrency, String toCurrency) async {
    // If same currency, return 1.0
    if (fromCurrency == toCurrency) {
      return 1.0;
    }

    // Convert symbols to codes
    final fromCode = _getCurrencyCode(fromCurrency);
    final toCode = _getCurrencyCode(toCurrency);

    // If same code, return 1.0
    if (fromCode == toCode) {
      return 1.0;
    }

    // Try to get from cache first
    final cachedRate = _getCachedRate(fromCode, toCode);
    if (cachedRate != null) {
      print('Using cached rate: 1 $fromCode = $cachedRate $toCode');
      return cachedRate;
    }

    // Try to fetch from API
    try {
      final rate = await _fetchExchangeRate(fromCode, toCode);
      if (rate != null) {
        _cacheExchangeRate(fromCode, toCode, rate);
        return rate;
      }
    } catch (e) {
      print('Error fetching exchange rate: $e');
    }

    // Fallback to cached rates if available
    final fallbackRate = _getCachedRate(fromCode, toCode);
    if (fallbackRate != null) {
      return fallbackRate;
    }

    // Last resort: return 1.0 (no conversion)
    print('No exchange rate available for $fromCode to $toCode, using 1.0');
    return 1.0;
  }

  /// Convert amount from one currency to another
  static Future<double> convertAmount(double amount, String fromCurrency, String toCurrency) async {
    final rate = await getExchangeRate(fromCurrency, toCurrency);
    final convertedAmount = amount * rate;
    print('Converting $amount $fromCurrency to $toCurrency: $amount × $rate = $convertedAmount');
    return convertedAmount;
  }

  /// Fetch exchange rate from API
  static Future<double?> _fetchExchangeRate(String fromCode, String toCode) async {
    try {
      print('Fetching rate from API: $fromCode to $toCode');
      final response = await http.get(
        Uri.parse('$_baseUrl$fromCode'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        final rate = rates[toCode] as double?;
        
        if (rate != null) {
          print('Fetched live rate: 1 $fromCode = $rate $toCode');
          return rate;
        } else {
          print('Rate not found in API response for $toCode');
          print('Available rates: ${rates.keys.take(10).toList()}');
        }
      } else {
        print('API response error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching from API: $e');
    }
    return null;
  }

  /// Get cached exchange rate
  static double? _getCachedRate(String fromCode, String toCode) {
    _loadCacheFromStorage();
    
    if (_lastCacheTime == null) return null;
    
    // Check if cache is still valid (24 hours)
    final now = DateTime.now();
    if (now.difference(_lastCacheTime!).inHours > _cacheDurationHours) {
      _clearCache();
      return null;
    }

    final key = '${fromCode}_$toCode';
    return _cachedRates[key];
  }

  /// Cache exchange rate
  static void _cacheExchangeRate(String fromCode, String toCode, double rate) {
    final key = '${fromCode}_$toCode';
    _cachedRates[key] = rate;
    _saveCacheToStorage();
  }

  /// Load cache from SharedPreferences
  static Future<void> _loadCacheFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ratesJson = prefs.getString(_cacheKey);
      final timestamp = prefs.getInt(_cacheTimestampKey);
      
      if (ratesJson != null && timestamp != null) {
        _cachedRates = Map<String, double>.from(
          json.decode(ratesJson).map((key, value) => MapEntry(key, value.toDouble())),
        );
        _lastCacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } catch (e) {
      print('Error loading cache: $e');
    }
  }

  /// Save cache to SharedPreferences
  static Future<void> _saveCacheToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(_cachedRates));
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error saving cache: $e');
    }
  }

  /// Clear cache
  static void _clearCache() {
    _cachedRates.clear();
    _lastCacheTime = null;
    _saveCacheToStorage();
  }

  /// Force refresh cache (for testing or manual refresh)
  static Future<void> refreshCache() async {
    _clearCache();
    print('Currency cache refreshed');
  }

  /// Get cache status for debugging
  static Map<String, dynamic> getCacheStatus() {
    return {
      'cachedRates': _cachedRates.length,
      'lastCacheTime': _lastCacheTime?.toString() ?? 'Never',
      'isValid': _lastCacheTime != null && 
                 DateTime.now().difference(_lastCacheTime!).inHours <= _cacheDurationHours,
      'cachedKeys': _cachedRates.keys.take(5).toList(),
    };
  }
}
