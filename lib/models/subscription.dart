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
  String category; // NEW FIELD!

  Subscription({
    required this.appName,
    required this.planName,
    required this.amount,
    required this.frequency,
    required this.startDate,
    this.category = 'Other', // Default if user doesn't choose
  });
}
