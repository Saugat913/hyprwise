import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/auth/data/auth_service.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

/// Intercepts anonymous/guest users attempting to purchase or view Hyprwise Pro.
/// Explains that signing in links their current data to their account and protects their subscription.
Future<bool> promptLoginToUpgrade(BuildContext context) async {
  final authService = getIt<AuthService>();
  if (!authService.isGuest) return true;

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (sheetContext) => const SubscriptionAuthGuardSheet(),
  );

  return result ?? false;
}

class SubscriptionAuthGuardSheet extends StatefulWidget {
  const SubscriptionAuthGuardSheet({super.key});

  @override
  State<SubscriptionAuthGuardSheet> createState() => _SubscriptionAuthGuardSheetState();
}

class _SubscriptionAuthGuardSheetState extends State<SubscriptionAuthGuardSheet> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = getIt<AuthService>();
      final user = await authService.linkGuestWithGoogle();
      if (user != null && mounted) {
        showToast(context, 'Account connected! Current data safely saved.');
        Navigator.of(context).pop(true);
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Sign in failed: ${e.toString().split(']').last.trim()}';
        });
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = getIt<AuthService>();
      final user = await authService.linkGuestWithApple();
      if (user != null && mounted) {
        showToast(context, 'Account connected! Current data safely saved.');
        Navigator.of(context).pop(true);
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Apple sign in failed: ${e.toString().split(']').last.trim()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    const brandOrange = Color(0xFFFF6500);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpace.xl,
          AppSpace.md,
          AppSpace.xl,
          AppSpace.xl + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pull handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.xl),

              // Icon Header with Green Shield & Pro Crown
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: brandOrange.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: brandOrange.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: AppIcon(
                      HugeIcons.strokeRoundedShieldUser,
                      size: 32,
                      color: brandOrange,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),

              // Title
              Text(
                'Sign In to Link Data & Purchase Pro',
                textAlign: TextAlign.center,
                style: text.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: AppSpace.sm),

              // Explanation Message
              Text(
                'Please sign in with Google or Apple to link your current transactions, shifts, and budgets to your account and activate your Hyprwise Pro subscription.',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpace.md),

              // Data Preservation Highlight Card
              Container(
                padding: const EdgeInsets.all(AppSpace.md),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131A17) : const Color(0xFFFFF0E6),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: brandOrange.withValues(alpha: 0.2),
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
                        'All your existing on-device financial records will be automatically saved to your user account.',
                        style: text.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFD6E3DC) : const Color(0xFF1F2726),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpace.md),
                Container(
                  padding: const EdgeInsets.all(AppSpace.sm),
                  decoration: BoxDecoration(
                    color: scheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(color: scheme.error),
                  ),
                ),
              ],

              const SizedBox(height: AppSpace.xl),

              if (_isLoading) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpace.md),
                    child: CircularProgressIndicator(color: brandOrange),
                  ),
                ),
              ] else ...[
                // Google Sign In Button
                SizedBox(
                  height: AppSize.button,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandOrange,
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

                // Apple Sign In Button (iOS or web)
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

                const SizedBox(height: AppSpace.sm),

                // Dismiss / Cancel Button
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
