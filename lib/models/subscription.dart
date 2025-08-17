import 'package:hive/hive.dart';

part 'subscription.g.dart';

@HiveType(typeId: 0)
class Subscription extends HiveObject {
  @HiveField(0)
  String appName;

  @HiveField(1)
  String planName;

  @HiveField(2)
  double amount;

  @HiveField(3)
  String frequency;

  @HiveField(4)
  DateTime startDate;

  @HiveField(5)
  String category;

  @HiveField(6)
  List<int> reminderDays; // Days before billing to send reminders

  @HiveField(7)
  String currency; // Original currency of the subscription

  Subscription({
    required this.appName,
    required this.planName,
    required this.amount,
    required this.frequency,
    required this.startDate,
    this.category = 'Other', // Default if user doesn't choose
    this.reminderDays = const [1], // Default: 1 day before
    this.currency = '\$', // Default to dollar
  });
}
