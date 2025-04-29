import 'package:hive/hive.dart';
import '../models/subscription.dart';

class HiveBoxes {
  static const String subscriptionBox = 'subscriptions';

  static Box<Subscription> getSubscriptionsBox() =>
      Hive.box<Subscription>(subscriptionBox);
}
