import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/shared/widgets/app_button.dart';
import 'package:finance_tracker/features/shared/widgets/app_card.dart';
import 'package:finance_tracker/features/shared/widgets/app_icon.dart';
import 'package:finance_tracker/features/shared/widgets/brand_emblem.dart';
import 'package:finance_tracker/features/shared/widgets/row_divider.dart';
import 'package:finance_tracker/features/shared/widgets/status_chip.dart';

/// Unified design-system layout for initial app loading, cloud backup checking,
/// and workspace setup screens: framed Hyprwise mark, status chip, progress card
/// with step rows, privacy note, and optional error / timeout recovery action.
class SetupLayout extends StatelessWidget {
  const SetupLayout({
    super.key,
    required this.animation,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.steps,
    this.statusLabel,
    this.done = false,
    this.errorMessage,
    this.actionLabel,
    this.onAction,
  });

  final Animation<double> animation;
  final String title;
  final String subtitle;
  final double progress;
  final String? statusLabel;
  final bool done;
  final List<Widget> steps;
  final String? errorMessage;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;
    final hasError = errorMessage != null && errorMessage!.isNotEmpty;
    final accent = hasError
        ? colors.expense
        : (done ? colors.income : colors.brandText);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.page,
              vertical: AppSpace.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Framed Hyprwise brand emblem matching the app's 12px surface geometry
                  Center(
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: hasError
                              ? colors.expense.withValues(alpha: 0.45)
                              : done
                                  ? colors.income.withValues(alpha: 0.45)
                                  : scheme.outlineVariant,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: BrandEmblem(
                        animation: reduceMotion ? null : animation,
                        size: 52,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),

                  if (statusLabel != null) ...[
                    Center(
                      child: StatusChip(
                        statusLabel!,
                        tone: hasError
                            ? ChipTone.danger
                            : done
                                ? ChipTone.success
                                : ChipTone.neutral,
                      ),
                    ),
                    const SizedBox(height: AppSpace.md),
                  ],

                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),

                  // Progress & checklist card
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpace.lg,
                            AppSpace.lg,
                            AppSpace.lg,
                            AppSpace.md,
                          ),
                          child: TweenAnimationBuilder<double>(
                            duration: reduceMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 360),
                            curve: Curves.easeOutCubic,
                            tween: Tween<double>(
                              begin: 0.08,
                              end: progress.clamp(0.08, 1.0),
                            ),
                            builder: (context, value, _) => Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        hasError
                                            ? errorMessage!
                                            : (statusLabel ?? title),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: text.labelMedium?.copyWith(
                                          color: hasError
                                              ? colors.expense
                                              : (done ? colors.income : scheme.onSurface),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpace.sm),
                                    Text(
                                      '${(value * 100).round()}%',
                                      style: text.labelMedium?.copyWith(
                                        color: accent,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'RedditMono',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpace.sm),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(AppRadius.xs),
                                  child: LinearProgressIndicator(
                                    value: value,
                                    minHeight: 6,
                                    backgroundColor: colors.fill,
                                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const RowDivider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.lg,
                            vertical: AppSpace.sm,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: steps,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: AppSpace.lg),
                    AppButton(
                      actionLabel!,
                      onPressed: onAction,
                    ),
                  ],

                  const SizedBox(height: AppSpace.xl),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.md,
                      vertical: AppSpace.sm,
                    ),
                    decoration: BoxDecoration(
                      color: colors.fill.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIcon(
                          HugeIcons.strokeRoundedSecurityCheck,
                          size: 16,
                          color: colors.income,
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Flexible(
                          child: Text(
                            context.strings.offlineSecurityBadge,
                            textAlign: TextAlign.center,
                            style: text.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
