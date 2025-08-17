// This is a template file for API keys and sensitive configuration
// Copy this file to api_keys.dart and fill in your actual values
// DO NOT commit the actual api_keys.dart file to version control

class ApiKeys {
  // AdMob Configuration
  static const String admobAppId = 'ca-app-pub-xxxxxxxxxxxxxxxx~xxxxxxxxxx';
  static const String admobBannerAdUnitId = 'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx';
  
  // Currency Conversion API (if using a different service)
  static const String currencyApiKey = 'your_currency_api_key_here';
  
  // Firebase Configuration (if using Firebase)
  static const String firebaseApiKey = 'your_firebase_api_key_here';
  static const String firebaseProjectId = 'your_firebase_project_id_here';
  
  // Other API keys can be added here
  static const String analyticsApiKey = 'your_analytics_api_key_here';
}

// Usage example:
// import 'package:your_app/config/api_keys.dart';
// 
// Then use: ApiKeys.admobAppId
