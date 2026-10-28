import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import 'package:finance_tracker/app/di/injection.dart';
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
  String? _authError;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const brandGreen = Color(0xFF28A050);

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
                          color: brandGreen.withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: brandGreen.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Center(
                          child: AppIcon(
                            HugeIcons.strokeRoundedShieldUser,
                            size: 38,
                            color: brandGreen,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.xl),

                    Text(
                      'Sign In to Link Data & Purchase Pro',
                      textAlign: TextAlign.center,
                      style: text.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),

                    Text(
                      'Please sign in with Google or Apple to link your current transactions, shifts, and budgets to your account and activate your Hyprwise Pro subscription.',
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
                        color: isDark ? const Color(0xFF131A17) : const Color(0xFFF1F6F3),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: brandGreen.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 20,
                            color: brandGreen,
                          ),
                          const SizedBox(width: AppSpace.sm),
                          Expanded(
                            child: Text(
                              'All your current local shifts, accounts, and transactions will be safely preserved and stored in your user account.',
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
                          child: CircularProgressIndicator(color: brandGreen),
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        height: AppSize.button,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          icon: const AppIcon(
                            HugeIcons.strokeRoundedGoogle,
                            size: 20,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Continue with Google',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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
                            label: const Text(
                              'Continue with Apple',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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
          displayCloseButton: true,
          onDismiss: () {
            if (context.mounted) context.pop();
          },
          onPurchaseCompleted: (customerInfo, storeTransaction) async {
            await subService.checkEntitlement();
            if (context.mounted) {
              showToast(context, 'Welcome to Hyprwise Pro!');
              context.pop();
            }
          },
          onRestoreCompleted: (customerInfo) async {
            await subService.checkEntitlement();
            if (context.mounted) {
              showToast(context, 'Purchases restored successfully');
              context.pop();
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
                'Unlock unlimited AI budget intelligence, automated bill OCR scans, and seamless encrypted cloud sync.',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpace.xl),
              AppButton(
                'Launch RevenueCat Paywall',
                onPressed: () async {
                  final result = await subService.presentPaywall();
                  if (result == PaywallResult.purchased || result == PaywallResult.restored) {
                    if (context.mounted) context.pop();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
