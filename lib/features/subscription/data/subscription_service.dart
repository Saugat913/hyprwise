import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:firebase_analytics/firebase_analytics.dart' show AnalyticsEventItem;
import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/telemetry/telemetry_service.dart';
import 'package:finance_tracker/features/assistant/viewmodels/assistant_view_model.dart';
import 'package:finance_tracker/features/auth/data/auth_service.dart';
import 'package:finance_tracker/core/network/api_client.dart';

enum SubscriptionTier { free, pro }

/// Access state returned from RevenueCat entitlements.
/// A Supporter purchase unlocks both `pro_access` and `supporter`.
class Access {
  final bool isPro;
  final bool isSupporter;
  const Access(this.isPro, this.isSupporter);
}

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.title,
    required this.priceString,
    required this.period,
    this.badge,
    this.savingsPercent,
    this.isLifetime = false,
    this.package,
  });

  final String id;
  final String title;
  final String priceString;
  final String period;
  final String? badge;
  final int? savingsPercent;
  final bool isLifetime;
  final Package? package;
}

class SubscriptionService extends ChangeNotifier {
  SubscriptionService({
    required this.authService,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final AuthService authService;
  final FlutterSecureStorage _storage;

  bool _isPro = false;
  bool _isSupporter = false;
  bool _hasActiveRevenueCatEntitlement = false;
  DateTime? _proExpiryDate;
  bool _isConfigured = false;
  Offerings? _offerings;
  Package? _proMonthlyPackage;
  Package? _proYearlyPackage;
  List<Package> _supporterPackages = const [];
  CustomerInfo? _customerInfo;

  bool get isPro => _isPro || _isSupporter || (authService.currentUser?.isPro ?? false);
  bool get isSupporter => _isSupporter;
  DateTime? get proExpiryDate => _proExpiryDate;
  Offerings? get offerings => _offerings;
  Package? get proMonthlyPackage => _proMonthlyPackage;
  Package? get proYearlyPackage => _proYearlyPackage;
  List<Package> get supporterPackages => _supporterPackages;
  CustomerInfo? get customerInfo => _customerInfo;
  bool get isConfigured => _isConfigured;

  /// Whether RevenueCat has valid offering packages ready to display in native UI
  bool get hasValidOfferings {
    if (!_isConfigured || _offerings == null) return false;
    final current = _offerings?.current ?? _offerings?.getOffering(offeringPro);
    return current != null && current.availablePackages.isNotEmpty;
  }

  static const _proKey = 'subscription_is_pro';
  static const _supporterKey = 'subscription_is_supporter';
  static const _proExpiryKey = 'subscription_pro_expiry';

  /// Entitlement identifiers configured in RevenueCat dashboard
  static const String entitlementPro = 'pro_access';
  static const String entitlementSupporter = 'supporter';

  /// Offering identifiers configured in RevenueCat dashboard
  static const String offeringPro = 'default';
  static const String offeringSupporter = 'supporter';

  /// RevenueCat API key provided for Hyprwise (loaded via .env / --dart-define)
  static const String defaultApiKey = AppConfig.defaultRevenueCatKey;
  static String get googleApiKey => AppConfig.revenueCatGoogleKey.isNotEmpty
      ? AppConfig.revenueCatGoogleKey
      : defaultApiKey;
  static String get appleApiKey => AppConfig.revenueCatAppleKey.isNotEmpty
      ? AppConfig.revenueCatAppleKey
      : defaultApiKey;

  /// Fallback static plans used only before store offerings load
  static const defaultAvailablePlans = [
    SubscriptionPlan(
      id: 'monthly',
      title: 'Monthly Plan',
      priceString: r'$2.99',
      period: 'month',
    ),
    SubscriptionPlan(
      id: 'yearly',
      title: 'Yearly Plan',
      priceString: r'$12.99',
      period: 'year',
      badge: 'Best Value',
      savingsPercent: 64,
    ),
  ];

  /// Dynamic plans using live `package.storeProduct.priceString` when available
  List<SubscriptionPlan> get activePlans {
    final monthlyPkg = _proMonthlyPackage;
    final yearlyPkg = _proYearlyPackage;
    return [
      SubscriptionPlan(
        id: 'monthly',
        title: monthlyPkg?.storeProduct.title.isNotEmpty == true
            ? monthlyPkg!.storeProduct.title
            : 'Monthly Plan',
        priceString: monthlyPkg?.storeProduct.priceString ?? r'$2.99',
        period: 'month',
        package: monthlyPkg,
      ),
      SubscriptionPlan(
        id: 'yearly',
        title: yearlyPkg?.storeProduct.title.isNotEmpty == true
            ? yearlyPkg!.storeProduct.title
            : 'Yearly Plan',
        priceString: yearlyPkg?.storeProduct.priceString ?? r'$12.99',
        period: 'year',
        badge: 'Best Value',
        savingsPercent: 64,
        package: yearlyPkg,
      ),
    ];
  }

  static List<SubscriptionPlan> get availablePlans => defaultAvailablePlans;

  Future<void> load() async {
    try {
      final rawPro = await _storage.read(key: _proKey);
      _isPro = rawPro == 'true';
      final rawSupporter = await _storage.read(key: _supporterKey);
      _isSupporter = rawSupporter == 'true';
      final rawExpiry = await _storage.read(key: _proExpiryKey);
      if (rawExpiry != null) {
        _proExpiryDate = DateTime.tryParse(rawExpiry);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading subscription cache: $e');
    }
  }

  /// Initializes the RevenueCat v11 SDK at startup
  Future<void> initRevenueCat() async {
    try {
      if (kIsWeb) return;
      final apiKey = Platform.isAndroid ? googleApiKey : appleApiKey;
      if (apiKey.isEmpty) {
        debugPrint('[RevenueCat] No API key configured; operating in local mode.');
        return;
      }

      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      } else {
        await Purchases.setLogLevel(LogLevel.info);
      }

      final config = PurchasesConfiguration(apiKey);
      final userId = authService.currentUser?.id;
      if (userId != null && userId.isNotEmpty && !authService.isGuest) {
        config.appUserID = userId;
      }
      await Purchases.configure(config);
      _isConfigured = true;

      // Stay updated when a purchase, renewal or expiry happens
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _handleCustomerInfo(customerInfo);
      });

      // Fetch initial customer info
      final info = await Purchases.getCustomerInfo();
      _handleCustomerInfo(info);

      // Load Pro ('default') and Supporter ('supporter') offerings
      await loadPlans();
      debugPrint(
        '[RevenueCat] Initialized v11 with entitlements: $entitlementPro, $entitlementSupporter',
      );
    } catch (e) {
      debugPrint('[RevenueCat] Initialization notice: $e');
    }
  }

  /// Checks `pro_access` and `supporter` entitlements directly from RevenueCat
  Future<Access> getAccess() async {
    if (!_isConfigured) {
      return Access(isPro, isSupporter);
    }
    final info = await Purchases.getCustomerInfo();
    _handleCustomerInfo(info);
    final active = info.entitlements.active;
    return Access(
      active.containsKey(entitlementPro) || active.containsKey(entitlementSupporter),
      active.containsKey(entitlementSupporter),
    );
  }

  /// Registers a listener for live CustomerInfo entitlement updates
  void listenForChanges(void Function(Access) onChange) {
    if (!_isConfigured) return;
    Purchases.addCustomerInfoUpdateListener((info) {
      _handleCustomerInfo(info);
      final a = info.entitlements.active;
      onChange(
        Access(
          a.containsKey(entitlementPro) || a.containsKey(entitlementSupporter),
          a.containsKey(entitlementSupporter),
        ),
      );
    });
  }

  /// Loads `default` (Pro monthly/annual) and `supporter` offerings from RevenueCat
  Future<void> loadPlans() async {
    if (!_isConfigured) return;
    try {
      final offerings = await Purchases.getOfferings();
      _offerings = offerings;

      // Pro: default offering
      final pro = offerings.current ?? offerings.getOffering(offeringPro);
      _proMonthlyPackage = pro?.monthly;
      _proYearlyPackage = pro?.annual;

      // Supporter tiers
      final supporter = offerings.getOffering(offeringSupporter);
      _supporterPackages = supporter?.availablePackages ?? [];
      notifyListeners();
    } catch (e) {
      debugPrint('[RevenueCat] Error loading offerings: $e');
    }
  }

  /// Internal handler for CustomerInfo updates
  void _handleCustomerInfo(CustomerInfo info) {
    _customerInfo = info;
    final activeEntitlements = info.entitlements.active;
    final proEntitlement = activeEntitlements[entitlementPro] ??
        activeEntitlements[entitlementSupporter] ??
        info.entitlements.all[entitlementPro];
    final hasSupporter = activeEntitlements.containsKey(entitlementSupporter);
    final active = activeEntitlements.containsKey(entitlementPro) || hasSupporter;

    _hasActiveRevenueCatEntitlement = active;
    _isPro = active;
    _isSupporter = hasSupporter;

    if (proEntitlement?.expirationDate != null) {
      _proExpiryDate = DateTime.tryParse(proEntitlement!.expirationDate!);
    } else if (active) {
      _proExpiryDate = null;
    }

    _storage.write(key: _proKey, value: _isPro ? 'true' : 'false');
    _storage.write(key: _supporterKey, value: _isSupporter ? 'true' : 'false');
    if (_proExpiryDate != null) {
      _storage.write(key: _proExpiryKey, value: _proExpiryDate!.toIso8601String());
    } else {
      _storage.delete(key: _proExpiryKey);
    }

    authService.updateProStatus(_isPro);
    notifyListeners();

    // Ensure active RevenueCat entitlement is synced to the Hyprwise server
    if (active) {
      final userId = authService.currentUser?.id ?? info.originalAppUserId;
      unawaited(
        ApiClient.instance
            .verifySubscription(
              appUserId: userId,
              planId: hasSupporter ? entitlementSupporter : entitlementPro,
            )
            .catchError((_) => null),
      );
    }
  }

  /// Checks entitlement directly from RevenueCat and validates with Hyprwise server
  Future<bool> checkEntitlement() async {
    if (_isConfigured) {
      try {
        final info = await Purchases.getCustomerInfo();
        _handleCustomerInfo(info);
      } catch (e) {
        debugPrint('[RevenueCat] Error checking entitlement: $e');
      }
    }
    await syncWithServer();
    return isPro;
  }

  /// Synchronizes Pro subscription status and AI quota directly from the Hyprwise backend server
  Future<bool> syncWithServer() async {
    try {
      final status = await ApiClient.instance.getSubscriptionStatus();
      if (status != null) {
        if (status['dailyAiQueriesUsed'] is int && getIt.isRegistered<AssistantViewModel>()) {
          getIt<AssistantViewModel>().updateQuotaFromServer(
            used: status['dailyAiQueriesUsed'] as int,
            left: status['dailyAiQueriesLeft'] as int?,
          );
        } else if (status['dailyAiQueriesLeft'] is int && getIt.isRegistered<AssistantViewModel>()) {
          final left = status['dailyAiQueriesLeft'] as int;
          final used = (5 - left).clamp(0, 5);
          getIt<AssistantViewModel>().updateQuotaFromServer(used: used, left: left);
        }
        if (status['isPro'] != null) {
          final serverPro = status['isPro'] as bool;
          // If RevenueCat reports an active entitlement locally, never downgrade to false;
          // instead push verification to the server.
          if (_hasActiveRevenueCatEntitlement && !serverPro) {
            final userId = authService.currentUser?.id ??
                _customerInfo?.originalAppUserId ??
                'default_user';
            await ApiClient.instance.verifySubscription(
              appUserId: userId,
              planId: _isSupporter ? entitlementSupporter : entitlementPro,
            );
            return true;
          }
          if (serverPro != _isPro) {
            _isPro = serverPro;
            await _storage.write(key: _proKey, value: _isPro ? 'true' : 'false');
            authService.updateProStatus(_isPro);
            notifyListeners();
          }
          return isPro;
        }
      }
    } catch (e) {
      debugPrint('[Subscription] Server status sync notice: $e');
    }
    return isPro;
  }

  /// Sets pro status for debugging / local testing
  Future<void> setDebugPro(bool pro) async {
    _isPro = pro;
    await _storage.write(key: _proKey, value: pro ? 'true' : 'false');
    authService.updateProStatus(pro);
    notifyListeners();
  }

  /// Updates pro state from canonical user authentication response and links RevenueCat appUserID
  Future<void> setServerProStatus(bool serverPro) async {
    if (_isConfigured && !authService.isGuest) {
      final userId = authService.currentUser?.id;
      if (userId != null && userId.isNotEmpty) {
        try {
          final logInResult = await Purchases.logIn(userId);
          _handleCustomerInfo(logInResult.customerInfo);
        } catch (e) {
          debugPrint('[RevenueCat] logIn notice: $e');
        }
      }
    }
    if (!_hasActiveRevenueCatEntitlement) {
      _isPro = serverPro;
      await _storage.write(key: _proKey, value: _isPro ? 'true' : 'false');
      authService.updateProStatus(_isPro);
      notifyListeners();
    }
  }

  /// Resets local cached subscription state on sign-out
  Future<void> resetOnLogout() async {
    if (_isConfigured) {
      try {
        final isAnon = await Purchases.isAnonymous;
        if (!isAnon) {
          await Purchases.logOut();
        }
      } catch (e) {
        debugPrint('[RevenueCat] logOut notice: $e');
      }
    }
    _isPro = false;
    _isSupporter = false;
    _hasActiveRevenueCatEntitlement = false;
    _proExpiryDate = null;
    await _storage.delete(key: _proKey);
    await _storage.delete(key: _supporterKey);
    await _storage.delete(key: _proExpiryKey);
    notifyListeners();
  }

  /// Presents the native RevenueCat Paywall
  Future<PaywallResult> presentPaywall({Offering? offering}) async {
    if (!_isConfigured) return PaywallResult.error;
    // If offerings aren't available yet or products aren't registered, avoid triggering
    // native RevenueCat error activity (which shows Error 23 / ConfigurationError dialog).
    // Return PaywallResult.error so callers gracefully fall back to the Flutter paywall screen.
    if (!hasValidOfferings && offering == null) {
      debugPrint('[RevenueCatUI] No valid offerings/products registered yet. Falling back to Flutter paywall.');
      return PaywallResult.error;
    }
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
    if (!hasValidOfferings && offering == null) {
      debugPrint('[RevenueCatUI] No valid offerings/products registered yet. Falling back to Flutter paywall.');
      return PaywallResult.error;
    }
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

  /// Purchases a specific RevenueCat [Package] using v11 `Purchases.purchase(PurchaseParams.package(package))`
  Future<Access> buy(Package package) async {
    try {
      TelemetryService.instance.trackEvent(
        'subscription_purchase_attempt',
        {'package_id': package.identifier},
      );
      final purchaseResult = await Purchases.purchase(PurchaseParams.package(package));
      final customerInfo = purchaseResult.customerInfo;
      _handleCustomerInfo(customerInfo);

      final access = await getAccess();
      if (access.isPro) {
        await TelemetryService.instance.logPurchase(
          currency: package.storeProduct.currencyCode,
          value: package.storeProduct.price,
          transactionId: customerInfo.originalAppUserId,
          items: [
            AnalyticsEventItem(
              itemId: package.storeProduct.identifier,
              itemName: package.storeProduct.title,
              price: package.storeProduct.price,
            ),
          ],
        );
        await TelemetryService.instance.setUserProperty(name: 'is_pro', value: 'true');

        final userId = authService.currentUser?.id ?? customerInfo.originalAppUserId;
        try {
          await ApiClient.instance.verifySubscription(
            appUserId: userId,
            planId: package.identifier,
          );
          await syncWithServer();
        } catch (_) {}
      }
      return access;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('[RevenueCat] User cancelled purchase.');
        return Access(isPro, isSupporter);
      }
      debugPrint('[RevenueCat] Purchase PlatformException: $e (code: $code)');
      rethrow;
    }
  }

  /// Purchases a specific subscription plan by matching its RevenueCat package
  Future<bool> subscribe(SubscriptionPlan plan) async {
    TelemetryService.instance.trackEvent('subscription_purchase_attempt', {'plan_id': plan.id});
    if (_isConfigured) {
      if (_offerings == null) {
        await loadPlans();
      }
      final pkg = plan.package ??
          (() {
            final currentOffering = _offerings?.current;
            final targetId = plan.id.toLowerCase();
            if (targetId == 'yearly' || targetId.contains('annual')) {
              return _proYearlyPackage ??
                  currentOffering?.annual ??
                  currentOffering?.availablePackages.where((p) {
                    final pId = p.identifier.toLowerCase();
                    final prodId = p.storeProduct.identifier.toLowerCase();
                    return pId.contains('annual') ||
                        pId.contains('yearly') ||
                        prodId.contains('yearly') ||
                        prodId.contains('annual');
                  }).firstOrNull;
            }
            return _proMonthlyPackage ??
                currentOffering?.monthly ??
                currentOffering?.availablePackages.where((p) {
                  final pId = p.identifier.toLowerCase();
                  final prodId = p.storeProduct.identifier.toLowerCase();
                  return pId.contains('monthly') ||
                      pId.contains('month') ||
                      prodId.contains('monthly');
                }).firstOrNull;
          })();

      if (pkg != null) {
        try {
          final access = await buy(pkg);
          return access.isPro;
        } on PlatformException catch (_) {
          return false;
        } catch (e) {
          debugPrint('[RevenueCat] Native purchase error: $e');
          return false;
        }
      }
      return isPro;
    }

    // Offline / unit test environment fallback when RevenueCat is not configured
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _isPro = true;
    _proExpiryDate = plan.isLifetime
        ? null
        : DateTime.now().add(
            plan.id.contains('year') ? const Duration(days: 365) : const Duration(days: 30),
          );

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

  /// Restores previous purchases from Play Store / App Store
  Future<Access> restorePurchases() async {
    TelemetryService.instance.trackEvent('purchases_restore_attempt');
    if (_isConfigured) {
      try {
        final customerInfo = await Purchases.restorePurchases();
        _handleCustomerInfo(customerInfo);
        if (isPro) {
          final userId = authService.currentUser?.id ?? customerInfo.originalAppUserId;
          try {
            await ApiClient.instance.verifySubscription(
              appUserId: userId,
              planId: _isSupporter ? entitlementSupporter : entitlementPro,
            );
            await syncWithServer();
          } catch (_) {}
        }
        TelemetryService.instance.trackEvent('purchases_restored_success');
        return Access(isPro, isSupporter);
      } catch (e) {
        debugPrint('[RevenueCat] Restore error: $e');
      }
    }
    await load();
    return Access(isPro, isSupporter);
  }
}
