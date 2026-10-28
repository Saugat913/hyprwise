import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/features/subscription/data/subscription_service.dart';

class Paywalls {
  Paywalls._();

  /// Pro paywall: shows only if the user isn't Pro yet. Returns true if they have Pro afterwards.
  static Future<bool> requirePro() async {
    final sub = getIt<SubscriptionService>();
    if (sub.isPro) return true;

    final result = await sub.presentPaywallIfNeeded();
    return result == PaywallResult.purchased ||
        result == PaywallResult.restored ||
        result == PaywallResult.notPresented ||
        sub.isPro;
  }

  /// Supporter tip jar: always shown (people can tip more than once)
  static Future<void> showTipJar() async {
    final sub = getIt<SubscriptionService>();
    try {
      final offerings = await Purchases.getOfferings();
      final supporter = offerings.getOffering(SubscriptionService.offeringSupporter);
      if (supporter != null && supporter.availablePackages.isNotEmpty) {
        await RevenueCatUI.presentPaywall(
          offering: supporter,
          displayCloseButton: true,
        );
      } else {
        await RevenueCatUI.presentPaywall(
          displayCloseButton: true,
        );
      }
      await sub.checkEntitlement();
    } catch (e) {
      debugPrint('[Paywalls] showTipJar notice: $e');
    }
  }
}
