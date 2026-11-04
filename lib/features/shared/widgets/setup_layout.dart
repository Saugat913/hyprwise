import 'package:flutter/material.dart';

import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/shared/widgets/app_card.dart';
import 'package:finance_tracker/features/shared/widgets/brand_emblem.dart';

/// The one layout for every "setting things up / syncing" screen:
/// brand emblem, headline, subtitle, progress card with steps, privacy note.
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
  });

  final Animation<double> animation;
  final String title;
  final String subtitle;
  final double progress;
  final String? statusLabel;
  final bool done;
  final List<Widget> steps;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;
    final accent = done ? colors.income : scheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.page, vertical: AppSpace.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: BrandEmblem(animation: animation)),
                const SizedBox(height: AppSpace.xl),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
                ),
                const SizedBox(height: AppSpace.xl),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        tween: Tween<double>(begin: 0.1, end: progress.clamp(0.1, 1.0)),
                        builder: (context, value, _) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              child: LinearProgressIndicator(
                                value: value,
                                minHeight: 6,
                                backgroundColor: scheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation<Color>(accent),
                              ),
                            ),
                            const SizedBox(height: AppSpace.xs),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (statusLabel != null)
                                  Expanded(
                                    child: Text(
                                      statusLabel!,
                                      style: text.labelSmall?.copyWith(
                                        color: done ? colors.income : scheme.onSurfaceVariant,
                                        fontWeight: done ? FontWeight.w700 : FontWeight.w500,
                                      ),
                                    ),
                                  )
                                else
                                  const Spacer(),
                                Text(
                                  '${(value * 100).toInt()}%',
                                  style: text.labelSmall?.copyWith(
                                    color: accent,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'RedditMono',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpace.sm),
                      const Divider(height: 1),
                      const SizedBox(height: AppSpace.xs),
                      ...steps,
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_outlined, size: 14, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        context.strings.offlineSecurityBadge,
                        textAlign: TextAlign.center,
                        style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
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
