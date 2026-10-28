import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:firebase_analytics/firebase_analytics.dart' show AnalyticsEventItem;
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/telemetry/telemetry_service.dart';
import 'package:finance_tracker/features/auth/data/auth_service.dart';
import 'package:finance_tracker/core/network/api_client.dart';

enum SubscriptionTier { free, pro }

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.title,
    required this.priceString,
    required this.period,
    this.badge,
    this.savingsPercent,
    this.isLifetime = false,
  });

  final String id;
  final String title;
  final String priceString;
  final String period;
  final String? badge;
  final int? savingsPercent;
  final bool isLifetime;
}

class SubscriptionService extends ChangeNotifier {
  SubscriptionService({
    required this.authService,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final AuthService authService;
  final FlutterSecureStorage _storage;

  bool _isPro = false;
  DateTime? _proExpiryDate;
  bool _isConfigured = false;
  Offerings? _offerings;
  CustomerInfo? _customerInfo;

  bool get isPro => _isPro || (authService.currentUser?.isPro ?? false);
  DateTime? get proExpiryDate => _proExpiryDate;
  Offerings? get offerings => _offerings;
  CustomerInfo? get customerInfo => _customerInfo;
  bool get isConfigured => _isConfigured;

  static const _proKey = 'subscription_is_pro';
  static const _proExpiryKey = 'subscription_pro_expiry';

  /// Primary entitlement identifier configured in RevenueCat dashboard
  static const String entitlementPro = 'pro_access';

  /// RevenueCat API key provided for Hyprwise (loaded via .env / --dart-define)
  static const String defaultApiKey = AppConfig.defaultRevenueCatKey;
  static String get googleApiKey => AppConfig.revenueCatGoogleKey.isNotEmpty
      ? AppConfig.revenueCatGoogleKey
      : defaultApiKey;
  static String get appleApiKey => AppConfig.revenueCatAppleKey.isNotEmpty
      ? AppConfig.revenueCatAppleKey
      : defaultApiKey;

  /// Configured products for Hyprwise Pro:
  /// - Monthly (monthly) - Monthly subscription
  /// - Yearly (yearly) - Yearly subscription
  /// - Lifetime (lifetime) - One-time purchase
  static const availablePlans = [
    SubscriptionPlan(
      id: 'monthly',
      title: 'Monthly Plan',
      priceString: r'$3.99',
      period: 'month',
    ),
    SubscriptionPlan(
      id: 'yearly',
      title: 'Yearly Plan',
      priceString: r'$29.99',
      period: 'year',
      badge: 'Best Value',
      savingsPercent: 37,
    ),
    SubscriptionPlan(
      id: 'lifetime',
      title: 'Lifetime Access',
      priceString: r'$79.99',
      period: 'one-time',
      badge: 'Pay Once, Keep Forever',
      isLifetime: true,
    ),
  ];

  Future<void> load() async {
    try {
      final rawPro = await _storage.read(key: _proKey);
      _isPro = rawPro == 'true';
      final rawExpiry = await _storage.read(key: _proExpiryKey);
      if (rawExpiry != null) {
        _proExpiryDate = DateTime.tryParse(rawExpiry);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading subscription cache: $e');
    }
  }

  /// Initializes the RevenueCat SDK with official PurchasesConfiguration
  Future<void> initRevenueCat() async {
    try {
      if (kIsWeb) return;
      final apiKey = Platform.isAndroid ? googleApiKey : appleApiKey;
      if (apiKey.isEmpty) {
        debugPrint('[RevenueCat] No API key configured; operating in local mode.');
        return;
      }

      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);
      final config = PurchasesConfiguration(apiKey);
      await Purchases.configure(config);
      _isConfigured = true;

      // Real-time listener for customer entitlement updates across devices
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _handleCustomerInfo(customerInfo);
      });

      // Fetch initial customer info
      final info = await Purchases.getCustomerInfo();
      _handleCustomerInfo(info);

      // Load products and offerings from RevenueCat dashboard
      _offerings = await Purchases.getOfferings();
      notifyListeners();
      debugPrint('[RevenueCat] Initialized successfully with entitlement: $entitlementPro');
    } catch (e) {
      debugPrint('[RevenueCat] Initialization notice: $e');
    }
  }

  /// Internal handler for CustomerInfo updates
  void _handleCustomerInfo(CustomerInfo info) {
    _customerInfo = info;
    final proEntitlement = info.entitlements.all[entitlementPro];
    final active = proEntitlement?.isActive ?? false;
    _isPro = active;

    if (proEntitlement?.expirationDate != null) {
      _proExpiryDate = DateTime.tryParse(proEntitlement!.expirationDate!);
    } else if (active) {
      // Lifetime or non-expiring purchase
      _proExpiryDate = null;
    }

    _storage.write(key: _proKey, value: _isPro ? 'true' : 'false');
    if (_proExpiryDate != null) {
      _storage.write(key: _proExpiryKey, value: _proExpiryDate!.toIso8601String());
    } else {
      _storage.delete(key: _proExpiryKey);
    }

    authService.updateProStatus(_isPro);
    notifyListeners();
  }

  /// Checks entitlement directly from RevenueCat server
  Future<bool> checkEntitlement() async {
    if (_isConfigured) {
      try {
        final info = await Purchases.getCustomerInfo();
        _handleCustomerInfo(info);
        return isPro;
      } catch (e) {
        debugPrint('[RevenueCat] Error checking entitlement: $e');
      }
    }
    return isPro;
  }

  /// Presents the native RevenueCat Paywall
  Future<PaywallResult> presentPaywall({Offering? offering}) async {
    if (!_isConfigured) return PaywallResult.error;
    try {
      TelemetryService.instance.trackEvent('paywall_presented', {'trigger': 'direct'});
      final result = await RevenueCatUI.presentPaywall(
        offering: offering,
        displayCloseButton: true,
      );
      if (result == PaywallResult.purchased || result == PaywallResult.restored) {
        await checkEntitlement();
      }
      return result;
    } catch (e) {
      debugPrint('[RevenueCatUI] Error presenting paywall: $e');
      return PaywallResult.error;
    }
  }

  /// Presents the native RevenueCat Paywall only if user does NOT already have pro_access
  Future<PaywallResult> presentPaywallIfNeeded({Offering? offering}) async {
    if (!_isConfigured) return PaywallResult.notPresented;
    try {
      TelemetryService.instance.trackEvent('paywall_presented', {'trigger': 'if_needed'});
      final result = await RevenueCatUI.presentPaywallIfNeeded(
        entitlementPro,
        offering: offering,
        displayCloseButton: true,
      );
      if (result == PaywallResult.purchased || result == PaywallResult.restored) {
        await checkEntitlement();
      }
      return result;
    } catch (e) {
      debugPrint('[RevenueCatUI] Error presenting paywall if needed: $e');
      return PaywallResult.error;
    }
  }

  /// Presents the native RevenueCat Customer Center for managing subscriptions
  Future<void> presentCustomerCenter() async {
    if (!_isConfigured) return;
    try {
      TelemetryService.instance.trackEvent('customer_center_presented');
      await RevenueCatUI.presentCustomerCenter();
      await checkEntitlement();
    } catch (e) {
      debugPrint('[RevenueCatUI] Error presenting customer center: $e');
    }
  }

  /// Purchases a specific subscription or one-time lifetime plan
  Future<bool> subscribe(SubscriptionPlan plan) async {
    TelemetryService.instance.trackEvent('subscription_purchase_attempt', {'plan_id': plan.id});
    if (_isConfigured && _offerings != null) {
      try {
        final currentOffering = _offerings?.current;
        final targetId = plan.id.toLowerCase();

        // Find package matching either lifetime, yearly, or monthly
        final pkg = currentOffering?.availablePackages.where((p) {
          final pId = p.identifier.toLowerCase();
          final prodId = p.storeProduct.identifier.toLowerCase();
          if (targetId == 'lifetime') {
            return pId.contains('lifetime') || prodId.contains('lifetime');
          } else if (targetId == 'yearly' || targetId.contains('annual')) {
            return pId.contains('annual') || pId.contains('yearly') || prodId.contains('yearly') || prodId.contains('annual');
          } else {
            return pId.contains('monthly') || pId.contains('month') || prodId.contains('monthly');
          }
        }).firstOrNull;

        if (pkg != null) {
          final customerInfo = await Purchases.purchasePackage(pkg);
          _handleCustomerInfo(customerInfo);

          // Firebase Analytics Purchase tracking
          await TelemetryService.instance.logPurchase(
            currency: pkg.storeProduct.currencyCode,
            value: pkg.storeProduct.price,
            transactionId: customerInfo.originalAppUserId,
            items: [
              AnalyticsEventItem(
                itemId: pkg.storeProduct.identifier,
                itemName: pkg.storeProduct.title,
                price: pkg.storeProduct.price,
              ),
            ],
          );
          await TelemetryService.instance.setUserProperty(name: 'is_pro', value: 'true');

          return isPro;
        }
      } on PlatformException catch (e) {
        final errorCode = PurchasesErrorHelper.getErrorCode(e);
        if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
          debugPrint('[RevenueCat] User cancelled purchase.');
          return false;
        }
        debugPrint('[RevenueCat] Native purchase PlatformException: $e (code: $errorCode)');
      } catch (e) {
        debugPrint('[RevenueCat] Native purchase error: $e');
      }
    }

    // Fallback sandbox / dev activation
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _isPro = true;
    _proExpiryDate = plan.isLifetime
        ? null
        : DateTime.now().add(plan.id.contains('year') ? const Duration(days: 365) : const Duration(days: 30));

    await _storage.write(key: _proKey, value: 'true');
    if (_proExpiryDate != null) {
      await _storage.write(key: _proExpiryKey, value: _proExpiryDate!.toIso8601String());
    } else {
      await _storage.delete(key: _proExpiryKey);
    }

    authService.updateProStatus(true);
    TelemetryService.instance.trackEvent('subscription_activated', {
      'plan_id': plan.id,
      'is_dev_fallback': true,
    });
    await TelemetryService.instance.setUserProperty(name: 'is_pro', value: 'true');

    // Sync Pro activation to Tilvane server
    final userId = authService.currentUser?.id ?? 'default_user';
    try {
      await ApiClient.instance.verifySubscription(
        appUserId: userId,
        planId: plan.id,
      );
    } catch (_) {}

    notifyListeners();
    return true;
  }

  /// Restores previous purchases
  Future<void> restorePurchases() async {
    TelemetryService.instance.trackEvent('purchases_restore_attempt');
    if (_isConfigured) {
      try {
        final customerInfo = await Purchases.restorePurchases();
        _handleCustomerInfo(customerInfo);
        TelemetryService.instance.trackEvent('purchases_restored_success');
        return;
      } catch (e) {
        debugPrint('[RevenueCat] Restore error: $e');
      }
    }
    await load();
  }
}
