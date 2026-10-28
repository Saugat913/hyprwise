import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/auth/data/auth_service.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';
import 'package:finance_tracker/features/subscription/data/subscription_service.dart';

/// Unified RevenueCat Paywall screen with anonymous user conversion guard.
/// Ensures guest users link their local data to an authenticated account before purchasing.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isLoadingAuth = false;
  bool _isRestoring = false;
  String? _authError;

  @override
  void initState() {
    super.initState();
    final subService = getIt<SubscriptionService>();
    if (subService.isConfigured) {
      subService.loadPlans();
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoadingAuth = true;
      _authError = null;
    });

    try {
      final authService = getIt<AuthService>();
      final user = await authService.linkGuestWithGoogle();
      if (user != null && mounted) {
        showToast(context, 'Account connected! Current data safely saved.');
        setState(() {
          _isLoadingAuth = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoadingAuth = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAuth = false;
          _authError = 'Google sign-in failed: ${e.toString().split(']').last.trim()}';
        });
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isLoadingAuth = true;
      _authError = null;
    });

    try {
      final authService = getIt<AuthService>();
      final user = await authService.linkGuestWithApple();
      if (user != null && mounted) {
        showToast(context, 'Account connected! Current data safely saved.');
        setState(() {
          _isLoadingAuth = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoadingAuth = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAuth = false;
          _authError = 'Apple sign-in failed: ${e.toString().split(']').last.trim()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subService = getIt<SubscriptionService>();
    final authService = getIt<AuthService>();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final tr = context.strings;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const brandOrange = Color(0xFFFF6500);

    // 1. Guard for Anonymous / Guest users: prompt login to protect and link local data
    if (authService.isGuest) {
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
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: brandOrange.withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: brandOrange.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Center(
                          child: AppIcon(
                            HugeIcons.strokeRoundedShieldUser,
                            size: 38,
                            color: brandOrange,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.xl),

                    Text(
                      tr.signInToLinkProTitle,
                      textAlign: TextAlign.center,
                      style: text.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),

                    Text(
                      tr.signInToLinkProDesc,
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: AppSpace.lg),

                    Container(
                      padding: const EdgeInsets.all(AppSpace.md),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2E1303) : const Color(0xFFFFF0E6),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: brandOrange.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 20,
                            color: brandOrange,
                          ),
                          const SizedBox(width: AppSpace.sm),
                          Expanded(
                            child: Text(
                              tr.t(
                                'All your current local shifts, accounts, and transactions will be safely preserved and stored in your user account.',
                                ne: 'तपाईंका हालका सबै सिफ्ट, खाता र कारोबारहरू सुरक्षित रूपमा तपाईंको खातामा राखिनेछन्।',
                                es: 'Todos tus turnos, cuentas y transacciones locales se conservarán de forma segura.',
                                fr: 'Tous vos quarts, comptes et transactions locaux seront conservés en toute sécurité.',
                                de: 'Alle Ihre lokalen Schichten, Konten und Transaktionen bleiben sicher erhalten.',
                                ja: '現在のシフト、口座、取引データはすべて安全にアカウントに保存されます。',
                                zh: '您当前的所有本地班次、账户和交易记录都将安全地保存在您的账户中。',
                                it: 'Tutti i tuoi turni, conti e transazioni locali saranno conservati in sicurezza.',
                              ),
                              style: text.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFFD6E3DC) : const Color(0xFF1F2726),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_authError != null) ...[
                      const SizedBox(height: AppSpace.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpace.sm),
                        decoration: BoxDecoration(
                          color: scheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          _authError!,
                          textAlign: TextAlign.center,
                          style: text.bodySmall?.copyWith(color: scheme.error),
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpace.xl),

                    if (_isLoadingAuth) ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpace.md),
                          child: CircularProgressIndicator(color: brandOrange),
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        height: AppSize.button,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white : const Color(0xFF0F0F11),
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          icon: AppIcon(
                            HugeIcons.strokeRoundedGoogle,
                            size: 20,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                          label: Text(
                            tr.continueWithGoogle,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          onPressed: _handleGoogleSignIn,
                        ),
                      ),

                      if (!kIsWeb && Platform.isIOS) ...[
                        const SizedBox(height: AppSpace.sm),
                        SizedBox(
                          height: AppSize.button,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? Colors.white : Colors.black,
                              foregroundColor: isDark ? Colors.black : Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                            ),
                            icon: AppIcon(
                              HugeIcons.strokeRoundedApple,
                              size: 20,
                              color: isDark ? Colors.black : Colors.white,
                            ),
                            label: Text(
                              tr.continueWithApple,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            onPressed: _handleAppleSignIn,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // 2. User is authenticated: Render RevenueCat UI Paywall
    if (subService.isConfigured) {
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
      body: Center(
        child: Padding(
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
                      showToast(
                        context,
                        tr.t(
                          'Subscriptions are being activated on the Play Store. Please check back shortly.',
                          ne: 'प्ले स्टोरमा सदस्यता सक्रिय गरिँदैछ। कृपया केही समयपछि पुन: प्रयास गर्नुहोस्।',
                          es: 'Las suscripciones se están activando en Play Store. Vuelve a consultar en breve.',
                          fr: 'Les abonnements sont en cours d\'activation sur le Play Store. Veuillez réessayer sous peu.',
                          de: 'Abonnements werden im Play Store aktiviert. Bitte versuchen Sie es in Kürze erneut.',
                          ja: 'Playストアでサブスクリプションが有効化されています。しばらくしてからもう一度お試しください。',
                          zh: 'Play 商店正在激活订阅。请稍后重试。',
                          it: 'Gli abbonamenti sono in fase di attivazione su Play Store. Riprova a breve.',
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: AppSpace.sm),
              TextButton(
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
                child: Text(
                  tr.t(
                    'Restore Purchases',
                    ne: 'खरिदहरू पुनर्स्थापना गर्नुहोस्',
                    es: 'Restaurar compras',
                    fr: 'Restaurer les achats',
                    de: 'Käufe wiederherstellen',
                    ja: '購入を復元',
                    zh: '恢复购买',
                    it: 'Ripristina acquisti',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
