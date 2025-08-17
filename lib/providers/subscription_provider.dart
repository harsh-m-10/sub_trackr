import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/subscription.dart';
import '../db/hive_boxes.dart';

class SubscriptionProvider extends ChangeNotifier {
  List<Subscription> _subscriptions = [];
  bool _isLoading = false;

  List<Subscription> get subscriptions => _subscriptions;
  bool get isLoading => _isLoading;

  Future<void> loadSubscriptions() async {
    _isLoading = true;
    notifyListeners();

    try {
      final box = HiveBoxes.getSubscriptionsBox();
      _subscriptions = box.values.cast<Subscription>().toList();
    } catch (e) {
      debugPrint('Error loading subscriptions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSubscription(Subscription subscription) async {
    try {
      final box = HiveBoxes.getSubscriptionsBox();
      await box.add(subscription);
      await loadSubscriptions();
    } catch (e) {
      debugPrint('Error adding subscription: $e');
    }
  }

  Future<void> updateSubscription(int index, Subscription subscription) async {
    try {
      final box = HiveBoxes.getSubscriptionsBox();
      await box.putAt(index, subscription);
      await loadSubscriptions();
    } catch (e) {
      debugPrint('Error updating subscription: $e');
    }
  }

  Future<void> deleteSubscription(int index) async {
    try {
      final box = HiveBoxes.getSubscriptionsBox();
      await box.deleteAt(index);
      await loadSubscriptions();
    } catch (e) {
      debugPrint('Error deleting subscription: $e');
    }
  }

  Future<void> clearAllSubscriptions() async {
    try {
      final box = HiveBoxes.getSubscriptionsBox();
      await box.clear();
      await loadSubscriptions();
    } catch (e) {
      debugPrint('Error clearing subscriptions: $e');
    }
  }
}
