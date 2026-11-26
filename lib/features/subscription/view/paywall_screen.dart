import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';
import 'package:finance_tracker/features/subscription/data/subscription_service.dart';

/// Unified RevenueCat Paywall screen for authenticated Google/Apple users.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    final subService = getIt<SubscriptionService>();
    if (subService.isConfigured) {
      subService.loadPlans();
    }
  }

  @override
  Widget build(BuildContext context) {
    final subService = getIt<SubscriptionService>();

    return ListenableBuilder(
      listenable: subService,
      builder: (context, _) => _buildContent(context, subService),
    );
  }

  Widget _buildContent(
    BuildContext context,
    SubscriptionService subService,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final tr = context.strings;
    final isApplePlatform = !kIsWeb && (Platform.isIOS || Platform.isMacOS);

    // Render RevenueCat UI Paywall when valid offerings exist
    if (subService.isConfigured && subService.hasValidOfferings) {
      return Scaffold(
        body: PaywallView(
          offering: subService.offerings?.current,
          displayCloseButton: true,
          onDismiss: () {
            if (context.mounted) context.pop();
          },
          onPurchaseCompleted: (customerInfo, storeTransaction) async {
            await subService.checkEntitlement();
            if (context.mounted) {
              showToast(context, tr.proActive);
              context.pop();
            }
          },
          onRestoreCompleted: (customerInfo) async {
            await subService.checkEntitlement();
            if (context.mounted) {
              if (subService.isPro) {
                showToast(context, tr.proActive);
                context.pop();
              } else {
                showToast(
                  context,
                  tr.t(
                    'No active subscription found.',
                    ne: 'कुनै सक्रिय सदस्यता फेला परेन।',
                    es: 'No se encontró ninguna suscripción activa.',
                    fr: 'Aucun abonnement actif trouvé.',
                    de: 'Kein aktives Abonnement gefunden.',
                    ja: '有効なサブスクリプションが見つかりませんでした。',
                    zh: '未找到有效的订阅。',
                    it: 'Nessun abbonamento attivo trovato.',
                  ),
                );
              }
            }
          },
          onPurchaseError: (error) {
            if (context.mounted) {
              showToast(context, error.message);
            }
          },
        ),
      );
    }

    // 3. Fallback Paywall View
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hyprwise Pro'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const AppIcon(
                    HugeIcons.strokeRoundedCrown,
                    size: 36,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                Text(
                  'Hyprwise Pro',
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  tr.proUpgradeSubtitle,
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpace.xl),
                AppButton(
                  tr.upgradeToPro,
                  onPressed: () async {
                    if (subService.hasValidOfferings) {
                      final result = await subService.presentPaywallIfNeeded();
                      if (result == PaywallResult.purchased || result == PaywallResult.restored) {
                        if (context.mounted) context.pop();
                      }
                    } else {
                      if (kDebugMode) {
                        await subService.setDebugPro(true);
                        if (context.mounted) {
                          showToast(context, 'Pro unlocked for testing (Dev mode)');
                          context.pop();
                        }
                      } else {
                        final storeName = isApplePlatform ? 'App Store' : 'Google Play';
                        showToast(
                          context,
                          tr.t(
                            'Subscriptions are currently syncing with $storeName. Please check back shortly.',
                            ne: '$storeName मा सदस्यता सिंक गरिँदैछ। कृपया केही समयपछि पुन: प्रयास गर्नुहोस्।',
                            hi: '$storeName के साथ सदस्यता सिंक हो रही है। कृपया कुछ देर बाद पुनः प्रयास करें।',
                          ),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: AppSpace.sm),
                AppButton(
                  tr.t(
                    'Restore Purchases',
                    ne: 'खरिदहरू पुनर्स्थापना गर्नुहोस्',
                    hi: 'खरीदारी पुनर्स्थापित करें',
                    es: 'Restaurar compras',
                    fr: 'Restaurer les achats',
                    de: 'Käufe wiederherstellen',
                    ja: '購入を復元',
                    zh: '恢复购买',
                    it: 'Ripristina acquisti',
                  ),
                  kind: AppButtonKind.text,
                  loading: _isRestoring,
                  onPressed: _isRestoring
                      ? null
                      : () async {
                          setState(() => _isRestoring = true);
                          final access = await subService.restorePurchases();
                          if (context.mounted) {
                            setState(() => _isRestoring = false);
                            if (access.isPro) {
                              showToast(context, tr.proActive);
                              context.pop();
                            } else {
                              showToast(
                                context,
                                tr.t(
                                  'No active subscription found.',
                                  ne: 'कुनै सक्रिय सदस्यता फेला परेन।',
                                  hi: 'कोई सक्रिय सदस्यता नहीं मिली।',
                                  es: 'No se encontró ninguna suscripción activa.',
                                  fr: 'Aucun abonnement actif trouvé.',
                                  de: 'Kein aktives Abonnement gefunden.',
                                  ja: '有効なサブスクリプションが見つかりませんでした。',
                                  zh: '未找到有效的订阅。',
                                  it: 'Nessun abbonamento attivo trovato.',
                                ),
                              );
                            }
                          }
                        },
                ),
                const SizedBox(height: AppSpace.lg),
                Text(
                  tr.t(
                    'Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period in your ${isApplePlatform ? "Apple ID" : "Google Play"} account settings.',
                    ne: 'हालको अवधि सकिन कम्तीमा २४ घण्टा अघि रद्द नगरिएसम्म सदस्यता स्वतः नवीकरण हुन्छ।',
                    hi: 'वर्तमान अवधि समाप्त होने से कम से कम 24 घंटे पहले रद्द न किए जाने पर सदस्यता स्वतः नवीनीकृत हो जाएगी।',
                  ),
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpace.md,
                  children: [
                    TextButton(
                      onPressed: () => showAppTermsDialog(context),
                      child: Text(tr.termsOfService, style: text.labelSmall),
                    ),
                    TextButton(
                      onPressed: () => showAppPrivacyPolicyDialog(context),
                      child: Text(tr.privacyPolicy, style: text.labelSmall),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
