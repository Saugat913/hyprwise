import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/auth/data/auth_service.dart';
import 'package:finance_tracker/features/shared/widgets/app_icon.dart';
import 'package:finance_tracker/features/subscription/data/subscription_service.dart';
import 'package:finance_tracker/features/subscription/view/subscription_auth_guard_sheet.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

/// Compact inline Crown badge to indicate a Pro feature without cluttering the screen.
class ProCrownBadge extends StatelessWidget {
  const ProCrownBadge({super.key, this.isCompact = false});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const goldColor = Color(0xFFF59E0B);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 5 : 7,
        vertical: isCompact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: goldColor.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: goldColor.withValues(alpha: isDark ? 0.45 : 0.35),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            size: isCompact ? 11 : 13,
            color: goldColor,
          ),
          const SizedBox(width: 3),
          Text(
            'PRO',
            style: TextStyle(
              fontSize: isCompact ? 9 : 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: goldColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Presents a refined, non-intrusive Pro upgrade bottom sheet when a limit is reached or locked feature tapped.
Future<void> showProUpgradeSheet(
  BuildContext context, {
  required String title,
  required String message,
  String? featureHighlight,
}) async {
  final text = Theme.of(context).textTheme;
  final scheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  const goldColor = Color(0xFFF59E0B);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: scheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.page,
            AppSpace.xs,
            AppSpace.page,
            AppSpace.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing Gold Crown Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: goldColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  border: Border.all(color: goldColor.withValues(alpha: 0.4), width: 1.5),
                ),
                child: const Center(
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    size: 32,
                    color: goldColor,
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),

              // Title & Message
              Text(
                title,
                textAlign: TextAlign.center,
                style: text.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpace.xl),

              // Pro Perks List
              Container(
                padding: const EdgeInsets.all(AppSpace.md),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
                ),
                child: Column(
                  children: [
                    _PerkRow(
                      icon: HugeIcons.strokeRoundedChatBot,
                      label: sheetContext.strings.proPerkAiAssistant,
                      isHighlight: featureHighlight == 'ai',
                    ),
                    const SizedBox(height: AppSpace.sm),
                    _PerkRow(
                      icon: HugeIcons.strokeRoundedCloud,
                      label: sheetContext.strings.proPerkMultiCurrency,
                      isHighlight: featureHighlight == 'backup',
                    ),
                    const SizedBox(height: AppSpace.sm),
                    _PerkRow(
                      icon: HugeIcons.strokeRoundedFile01,
                      label: sheetContext.strings.proPerkCloudBackup,
                      isHighlight: featureHighlight == 'export',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.xl),

              // Primary Action: View Plans / Upgrade
              SizedBox(
                width: double.infinity,
                height: AppSize.button,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: goldColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    if (getIt<AuthService>().isGuest) {
                      final ok = await promptLoginToUpgrade(context);
                      if (!ok) return;
                    }
                    final subService = getIt<SubscriptionService>();
                    if (subService.isConfigured) {
                      final result = await subService.presentPaywall();
                      if (result == PaywallResult.error && context.mounted) {
                        context.push(AppRoutes.paywall);
                      }
                    } else {
                      if (context.mounted) context.push(AppRoutes.paywall);
                    }
                  },
                  child: Text(
                    sheetContext.strings.exploreProPlans,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.sm),

              // Secondary Dismiss
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: Text(
                  sheetContext.strings.maybeLater,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _PerkRow extends StatelessWidget {
  const _PerkRow({
    required this.icon,
    required this.label,
    this.isHighlight = false,
  });

  final IconGlyph icon;
  final String label;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const goldColor = Color(0xFFF59E0B);

    return Row(
      children: [
        Icon(
          Icons.check_circle_rounded,
          size: 16,
          color: isHighlight ? goldColor : scheme.primary,
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
              color: isHighlight ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87) : scheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
