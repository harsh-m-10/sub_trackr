import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:async'; // Added for Timer

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  // Track if we've already checked reminders this session
  static bool _hasCheckedRemindersThisSession = false;
  
  // Timer for periodic checks (only when app is active)
  static Timer? _periodicTimer;
  
  // Track which reminders we've already shown to prevent duplicates
  static final Set<String> _shownReminders = <String>{};
  
  // Track when we last showed each reminder type
  static final Map<String, DateTime> _lastReminderShown = <String, DateTime>{};

  static Future<void> initialize() async {
    print('=== Initializing Notification Service ===');
    
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    try {
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle notification tap
          print('Notification tapped: ${response.payload}');
        },
      );
      print('✅ Notification plugin initialized successfully');

      // Create notification channels for Android
      await _createNotificationChannels();
      print('✅ Notification channels created');

      // Required for scheduling notifications with timezones
      tz.initializeTimeZones();
      print('✅ Timezones initialized');
      
      // Check current timezone
      print('Current timezone: ${tz.local}');
      print('Current time: ${tz.TZDateTime.now(tz.local)}');
      
    } catch (e) {
      print('❌ Error initializing notification service: $e');
      rethrow;
    }
  }

  static Future<void> _createNotificationChannels() async {
    // Main subscription reminders channel
    const AndroidNotificationChannel subscriptionChannel = AndroidNotificationChannel(
      'subtrackr_channel',
      'Subscription Reminders',
      description: 'Notifies about upcoming subscription renewals',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    // Daily reminders channel
    const AndroidNotificationChannel dailyChannel = AndroidNotificationChannel(
      'subtrackr_daily_channel',
      'Daily Reminders',
      description: 'Daily subscription reminders at specific times',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Test notifications channel
    const AndroidNotificationChannel testChannel = AndroidNotificationChannel(
      'subtrackr_test_channel',
      'Test Notifications',
      description: 'Immediate test notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    // Date/time specific channel
    const AndroidNotificationChannel datetimeChannel = AndroidNotificationChannel(
      'subtrackr_datetime_channel',
      'Date/Time Specific Reminders',
      description: 'Reminders at specific dates and times',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    // Create all channels
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(subscriptionChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(dailyChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(testChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(datetimeChannel);
  }

  /// Schedule a notification at a specific time
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    print('=== Scheduling Single Notification ===');
    print('ID: $id');
    print('Title: $title');
    print('Body: $body');
    print('Scheduled Date: $scheduledDate');
    print('Current Time: ${DateTime.now()}');
    print('Time until notification: ${scheduledDate.difference(DateTime.now())}');
    
    try {
      // Use a simpler approach that's more reliable on Android
      final now = DateTime.now();
      final delay = scheduledDate.difference(now);
      
      if (delay.isNegative) {
        print('⚠️ Scheduled time is in the past, showing notification immediately');
        await showNotification(id: id, title: title, body: body);
        return;
      }
      
      // For short delays (less than 1 minute), use a timer approach
      if (delay.inMinutes < 1) {
        print('📱 Using timer approach for short delay: ${delay.inSeconds} seconds');
        Future.delayed(delay, () async {
          try {
            await showNotification(id: id, title: title, body: body);
            print('✅ Timer-based notification delivered: $title');
          } catch (e) {
            print('❌ Timer-based notification failed: $e');
          }
        });
        print('✅ Timer-based notification scheduled: $title in ${delay.inSeconds} seconds');
        return;
      }
      
      // For longer delays, try the zoned schedule approach
      print('⏰ Using zoned schedule for longer delay: ${delay.inMinutes} minutes');
      final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);
      print('TZ DateTime: $tzDateTime');
      
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'subtrackr_channel',
            'Subscription Reminders',
            channelDescription: 'Notifies about upcoming subscription renewals',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      print('✅ Zoned notification scheduled successfully: $title at $scheduledDate');
    } catch (e) {
      print('❌ Error scheduling notification: $e');
      // Fallback: try to show the notification immediately
      print('🔄 Falling back to immediate notification');
      try {
        await showNotification(id: id, title: title, body: body);
        print('✅ Fallback notification shown: $title');
      } catch (fallbackError) {
        print('❌ Fallback notification also failed: $fallbackError');
        rethrow;
      }
    }
  }

  /// Schedule a notification at a specific time of day (e.g., 9:00 AM)
  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOfTime(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'subtrackr_daily_channel',
            'Daily Reminders',
            channelDescription: 'Daily subscription reminders at specific times',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      print('Daily notification scheduled successfully: $title at $hour:$minute');
    } catch (e) {
      print('Error scheduling daily notification: $e');
      rethrow;
    }
  }

  /// Show a simple immediate notification (for testing basic functionality)
  static Future<void> showSimpleTestNotification() async {
    try {
      await showNotification(
        id: 9997,
        title: '🔔 Simple Test',
        body: 'This is a simple immediate notification test!',
      );
      print('✅ Simple test notification shown successfully');
    } catch (e) {
      print('❌ Simple test notification failed: $e');
      rethrow;
    }
  }

  /// Schedule a test notification for 5 seconds from now
  static Future<void> scheduleTestNotification() async {
    final testTime = DateTime.now().add(const Duration(seconds: 5));
    
    try {
      // First, try to show an immediate notification to test if notifications work at all
      await showNotification(
        id: 9998,
        title: '🧪 Immediate Test',
        body: 'This is an immediate test notification from SubTrackr!',
      );
      
      // Then try to schedule the delayed one
      await scheduleNotification(
        id: 9999, // Special ID for test notifications
        title: '🧪 Test Notification',
        body: 'This is a test notification from SubTrackr! If you see this, notifications are working correctly.',
        scheduledDate: testTime,
      );
      print('Test notification scheduled for: $testTime');
    } catch (e) {
      print('Error scheduling test notification: $e');
      rethrow;
    }
  }

  /// Check if we should show a reminder (prevents duplicates and respects timing)
  static bool _shouldShowReminder(String reminderKey, DateTime reminderDate) {
    final now = DateTime.now();
    
    // If we've already shown this reminder today, don't show it again
    if (_shownReminders.contains(reminderKey)) {
      print('🚫 Reminder $reminderKey already shown today, skipping');
      return false;
    }
    
    // Check if it's the right time to show the reminder
    final today = DateTime(now.year, now.month, now.day);
    final reminderDay = DateTime(reminderDate.year, reminderDate.month, reminderDate.day);
    
    // Only show if it's the correct day
    if (today.isAtSameMomentAs(reminderDay)) {
      // Check if we've shown this reminder recently (within last hour)
      final lastShown = _lastReminderShown[reminderKey];
      if (lastShown != null) {
        final timeSinceLastShown = now.difference(lastShown);
        if (timeSinceLastShown.inHours < 1) {
          print('🚫 Reminder $reminderKey shown recently (${timeSinceLastShown.inMinutes} minutes ago), skipping');
          return false;
        }
      }
      
      print('✅ Should show reminder $reminderKey - correct day and timing');
      return true;
    }
    
    print('🚫 Reminder $reminderKey not for today (${reminderDay.toString()}), skipping');
    return false;
  }
  
  /// Mark a reminder as shown to prevent duplicates
  static void _markReminderAsShown(String reminderKey) {
    _shownReminders.add(reminderKey);
    _lastReminderShown[reminderKey] = DateTime.now();
    print('📝 Marked reminder $reminderKey as shown');
  }
  
  /// Clear old reminder tracking (call this daily to reset)
  static void _clearOldReminderTracking() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Remove reminders from previous days
    _shownReminders.clear();
    _lastReminderShown.clear();
    
    print('🧹 Cleared old reminder tracking for new day');
  }
  
  /// Manually clear reminder tracking (for debugging/testing)
  static void clearReminderTracking() {
    _shownReminders.clear();
    _lastReminderShown.clear();
    print('🧹 Manually cleared all reminder tracking');
  }

  /// Get current reminder tracking status (for debugging)
  static Map<String, dynamic> getReminderTrackingStatus() {
    return {
      'shownReminders': _shownReminders.toList(),
      'lastReminderShown': _lastReminderShown.map((k, v) => MapEntry(k, v.toString())),
      'totalShown': _shownReminders.length,
    };
  }

  /// Start periodic reminder checking (call when app becomes active)
  static void startPeriodicChecking() {
    if (_periodicTimer != null) {
      _periodicTimer!.cancel();
    }
    
    print('🔄 Starting periodic reminder checking...');
    
    // Check reminders immediately
    _checkRemindersIfNeeded();
    
    // Clear old tracking when starting (in case it's a new day)
    _clearOldReminderTracking();
    
    // Then check every 2 hours while app is active (reduced from 15 minutes)
    _periodicTimer = Timer.periodic(const Duration(hours: 2), (timer) {
      _checkRemindersIfNeeded();
      
      // Clear old tracking daily
      final now = DateTime.now();
      final lastClear = _lastReminderCheck;
      if (lastClear == null || now.difference(lastClear).inDays >= 1) {
        _clearOldReminderTracking();
      }
    });
    
    print('✅ Periodic reminder checking started (every 2 hours)');
  }
  
  /// Stop periodic reminder checking (call when app goes to background)
  static void stopPeriodicChecking() {
    if (_periodicTimer != null) {
      _periodicTimer!.cancel();
      _periodicTimer = null;
      print('⏹️ Periodic reminder checking stopped');
    }
  }
  
  /// Check reminders if we haven't checked this session or if it's been a while
  static Future<void> _checkRemindersIfNeeded() async {
    try {
      // Check if we need to look for reminders
      final now = DateTime.now();
      final lastCheck = _lastReminderCheck;
      
      // Check if we should look for reminders (every hour or if first time)
      if (!_hasCheckedRemindersThisSession || 
          lastCheck == null || 
          now.difference(lastCheck).inHours >= 1) {
        
        print('🕐 Checking for reminders at ${now.toString()}');
        await _checkAndTriggerRemindersAutomatically();
        _lastReminderCheck = now;
        _hasCheckedRemindersThisSession = true;
      }
    } catch (e) {
      print('❌ Error in automatic reminder check: $e');
    }
  }
  
  // Track when we last checked for reminders
  static DateTime? _lastReminderCheck;
  
  /// Check for reminders with provided subscriptions data
  static Future<void> checkForRemindersWithData(List<dynamic> subscriptions) async {
    try {
      print('🔍 Checking for reminders with ${subscriptions.length} subscriptions...');
      await checkAndTriggerReminders(subscriptions);
    } catch (e) {
      print('❌ Error checking reminders with data: $e');
    }
  }
  
  /// Private method to automatically check and trigger reminders
  static Future<void> _checkAndTriggerRemindersAutomatically() async {
    try {
      print('🔍 Automatically checking for reminders...');
      
      // We'll need to get subscriptions from the caller since we don't have direct access to Hive here
      // This method will be called by the home screen when it has access to subscriptions
      
    } catch (e) {
      print('❌ Automatic reminder check error: $e');
    }
  }

  /// Manually check and trigger reminders for existing subscriptions
  static Future<void> checkAndTriggerReminders(List<dynamic> subscriptions) async {
    print('=== Checking Existing Subscription Reminders ===');
    final now = DateTime.now();
    
    for (final subscription in subscriptions) {
      try {
        final sub = subscription as dynamic;
        final startDate = sub.startDate as DateTime;
        final frequency = sub.frequency as String;
        final reminderDays = sub.reminderDays as List<int>? ?? [1];
        
        print('Checking subscription: ${sub.appName}');
        print('Start date: $startDate');
        print('Frequency: $frequency');
        print('Reminder days: $reminderDays');
        
        // Calculate next billing date
        DateTime nextBilling;
        if (frequency.toLowerCase().contains('weekly')) {
          nextBilling = startDate.add(const Duration(days: 7));
        } else if (frequency.toLowerCase().contains('monthly')) {
          int newMonth = startDate.month + 1;
          int newYear = startDate.year;
          if (newMonth > 12) {
            newMonth = 1;
            newYear++;
          }
          nextBilling = DateTime(newYear, newMonth, startDate.day);
        } else if (frequency.toLowerCase().contains('yearly')) {
          nextBilling = DateTime(startDate.year + 1, startDate.month, startDate.day);
        } else {
          nextBilling = startDate.add(const Duration(days: 30)); // Default to monthly
        }
        
        print('Next billing: $nextBilling');
        
        // Check each reminder day
        for (final days in reminderDays) {
          final reminderDate = nextBilling.subtract(Duration(days: days));
          print('Reminder $days days before: $reminderDate');
          
          // If reminder should be today, show it
          if (reminderDate.year == now.year && 
              reminderDate.month == now.month && 
              reminderDate.day == now.day) {
            print('🎯 TODAY: Should show reminder for ${sub.appName}');
            
            // Create a unique key for this reminder
            final reminderKey = '${sub.appName}_${days}_${reminderDate.toString().split(' ')[0]}';
            
            // Check if we should show this reminder
            if (_shouldShowReminder(reminderKey, reminderDate)) {
              try {
                await showNotification(
                  id: 10000 + subscriptions.indexOf(subscription), // Use unique ID
                  title: "Reminder: ${sub.appName}",
                  body: "Your subscription is due soon!",
                );
                print('✅ Reminder shown for ${sub.appName}');
                
                // Mark as shown to prevent duplicates
                _markReminderAsShown(reminderKey);
              } catch (e) {
                print('❌ Failed to show reminder for ${sub.appName}: $e');
              }
            } else {
              print('🚫 Skipping reminder for ${sub.appName} - already shown or not ready');
            }
          }
        }
      } catch (e) {
        print('❌ Error checking subscription: $e');
      }
    }
  }

  /// Schedule multiple reminders for a subscription
  static Future<void> scheduleMultipleReminders({
    required int baseId,
    required String title,
    required String body,
    required DateTime billingDate,
    required List<int> reminderDays,
    TimeOfDay? notificationTime,
  }) async {
    print('=== Scheduling Multiple Reminders ===');
    print('Base ID: $baseId');
    print('Title: $title');
    print('Body: $body');
    print('Billing Date: $billingDate');
    print('Reminder Days: $reminderDays');
    print('Notification Time: $notificationTime');
    
    // Cancel any existing reminders for this subscription
    await cancelMultipleReminders(baseId);
    
    // Schedule new reminders for each selected day
    for (int i = 0; i < reminderDays.length; i++) {
      final days = reminderDays[i];
      final reminderDate = billingDate.subtract(Duration(days: days));
      
      print('Processing reminder $i: $days days before billing');
      print('Reminder Date: $reminderDate');
      print('Current Time: ${DateTime.now()}');
      
      // Only schedule if the reminder date is in the future OR is today (for same-day reminders)
      if (reminderDate.isAfter(DateTime.now()) || 
          (reminderDate.year == DateTime.now().year && 
           reminderDate.month == DateTime.now().month && 
           reminderDate.day == DateTime.now().day)) {
        
        final reminderId = baseId * 1000 + i; // Create unique ID for each reminder
        
        // If notification time is specified, use it; otherwise use the default time
        DateTime scheduledTime;
        if (notificationTime != null) {
          scheduledTime = DateTime(
            reminderDate.year,
            reminderDate.month,
            reminderDate.day,
            notificationTime.hour,
            notificationTime.minute,
          );
        } else {
          scheduledTime = reminderDate;
        }
        
        print('Scheduling reminder $reminderId for: $scheduledTime');
        
        // If the reminder is for today and the time has passed, show it immediately
        if (scheduledTime.isBefore(DateTime.now())) {
          print('🔄 Reminder $reminderId is for today but time has passed, showing immediately');
          
          // Create a unique key for this reminder
          final reminderKey = 'subscription_${baseId}_${days}_${reminderDate.toString().split(' ')[0]}';
          
          // Check if we should show this reminder
          if (_shouldShowReminder(reminderKey, reminderDate)) {
            try {
              await showNotification(
                id: reminderId,
                title: title,
                body: body,
              );
              print('✅ Immediate reminder $reminderId shown');
              
              // Mark as shown to prevent duplicates
              _markReminderAsShown(reminderKey);
            } catch (e) {
              print('❌ Failed to show immediate reminder $reminderId: $e');
            }
          } else {
            print('🚫 Skipping immediate reminder $reminderId - already shown or not ready');
          }
          continue; // Skip to next reminder
        }
        
        try {
          // For subscription reminders, always try the zoned schedule first
          // as they are typically days in the future
          final tzDateTime = tz.TZDateTime.from(scheduledTime, tz.local);
          await _notificationsPlugin.zonedSchedule(
            reminderId,
            title,
            body,
            tzDateTime,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'subtrackr_channel',
                'Subscription Reminders',
                channelDescription: 'Notifies about upcoming subscription renewals',
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
                // Add these flags to make notifications more reliable
                ongoing: false,
                autoCancel: true,
                showWhen: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            // Add payload for debugging
            payload: 'subscription_reminder_$baseId',
          );
          print('✅ Successfully scheduled reminder $reminderId using zoned schedule');
        } catch (e) {
          print('❌ Failed to schedule reminder $reminderId with zoned schedule: $e');
          // Fallback: try to schedule with a simple delay
          try {
            final delay = scheduledTime.difference(DateTime.now());
            if (delay.inMilliseconds > 0) {
              Future.delayed(delay, () async {
                try {
                  await showNotification(
                    id: reminderId,
                    title: title,
                    body: body,
                  );
                  print('✅ Fallback reminder $reminderId delivered after delay');
                } catch (fallbackError) {
                  print('❌ Fallback reminder $reminderId failed: $fallbackError');
                }
              });
              print('✅ Fallback reminder $reminderId scheduled with delay: ${delay.inDays} days');
            }
          } catch (fallbackError) {
            print('❌ Fallback scheduling also failed for reminder $reminderId: $fallbackError');
          }
        }
      } else {
        print('⚠️ Reminder date $reminderDate is in the past, skipping');
      }
    }
    
    // Get all pending notifications for debugging
    final pendingNotifications = await getPendingNotifications();
    print('Total pending notifications: ${pendingNotifications.length}');
    for (final notification in pendingNotifications) {
      print('Pending: ID=${notification.id}, Title=${notification.title}');
    }
  }

  /// Cancel multiple reminders for a subscription
  static Future<void> cancelMultipleReminders(int baseId) async {
    // Cancel all reminders for a subscription (up to 10 reminders)
    for (int i = 0; i < 10; i++) {
      final reminderId = baseId * 1000 + i;
      await cancelNotification(reminderId);
    }
  }

  /// Cancel a specific notification
  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Check and request notification permissions
  static Future<bool> checkPermissions() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        final bool? granted = await androidImplementation.requestNotificationsPermission();
        print('Notification permission granted: $granted');
        return granted ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking notification permissions: $e');
      return false;
    }
  }

  /// Get all pending notifications (for debugging)
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  /// Show a notification immediately (for testing)
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'subtrackr_test_channel',
            'Test Notifications',
            channelDescription: 'Immediate test notifications',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
        ),
      );
      print('Immediate notification shown: $title');
    } catch (e) {
      print('Error showing immediate notification: $e');
      rethrow;
    }
  }

  /// Helper method to get the next instance of a specific time
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
      0,
    );
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  /// Schedule a notification for a specific date and time
  static Future<void> scheduleDateTimeNotification({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
  }) async {
    final scheduledDate = tz.TZDateTime.from(dateTime, tz.local);
    
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'subtrackr_datetime_channel',
            'Date/Time Specific Reminders',
            channelDescription: 'Reminders at specific dates and times',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      print('DateTime notification scheduled successfully: $title at $scheduledDate');
    } catch (e) {
      print('Error scheduling datetime notification: $e');
      rethrow;
    }
  }
}
