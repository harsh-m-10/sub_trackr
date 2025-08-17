class AppConstants {
  // App Information
  static const String appName = 'SubTrackr';
  static const String appVersion = '1.0.0';
  static const String developerName = 'Harsh M';
  
  // App Store Links (update these before release)
  static const String privacyPolicyUrl = 'https://harshm.dev/subtrackr/privacy-policy';
  static const String termsOfServiceUrl = 'https://harshm.dev/subtrackr/terms-of-service';
  static const String supportEmail = 'support@harshm.dev';
  
  // Default Values
  static const String defaultCurrency = '\$';
  static const List<String> availableCurrencies = ['\$', '₹', '€', '£', '¥', '₩', '₽', '₦', 'R\$', 'A\$', 'C\$'];
  static const List<String> defaultCategories = [
    'Entertainment',
    'Productivity', 
    'Finance',
    'Education',
    'Health',
    'Other'
  ];
  
  // Notification Settings
  static const int defaultReminderDays = 1;
  static const String notificationChannelId = 'subtrackr_channel';
  static const String notificationChannelName = 'Subscription Reminders';
  static const String notificationChannelDescription = 'Notifies about upcoming subscription renewals';
  
  // UI Constants
  static const double cardBorderRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const double defaultSpacing = 12.0;
}
