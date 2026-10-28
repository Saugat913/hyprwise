import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/features/subscription/data/subscription_service.dart';

/// Facade for purchases adhering to Hyprwise subscription architecture.
class PurchaseService {
  PurchaseService._();
  static final instance = PurchaseService._();

  SubscriptionService get _service => getIt<SubscriptionService>();

  ValueNotifier<bool> get isPro => _service.isProNotifier;
  ValueNotifier<bool> get isSupporter => _service.isSupporterNotifier;
  ValueNotifier<bool> get everSupported => _service.everSupportedNotifier;

  Future<void> restore() => _service.restorePurchases();
  Future<void> logIn(String id) async {
    if (_service.isConfigured) {
      await Purchases.logIn(id);
      await _service.checkEntitlement();
    }
  }
  Future<void> logOut() => _service.resetOnLogout();
}
