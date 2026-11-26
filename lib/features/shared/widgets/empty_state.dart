import 'package:flutter/material.dart';

import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/shared/widgets/app_button.dart';
import 'package:finance_tracker/features/shared/widgets/app_icon.dart';

/// Domain-specific architectural empty-state graphics tailored to Hyprwise's
/// 12px-radius minimal card geometry (zero floating circles).
enum EmptyIllustration {
  general,
  transactions,
  shifts,
  jobs,
  goals,
  debts,
  analytics,
  calendar,
  alerts,
  accounts,
  backup,
  search,
}

/// Centered empty state with crisp 12px architectural graphic, title,
/// contextual guidance, and interactive primary/secondary actions.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.outlineAction = false,
    this.illustration = EmptyIllustration.general,
    this.compact = false,
  });

  final IconGlyph icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final bool outlineAction;
  final EmptyIllustration illustration;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final content = Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpace.lg : AppSpace.xxl,
          vertical: compact ? AppSpace.lg : AppSpace.xxl,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _EmptyArchitecturalGraphic(
                icon: icon,
                illustration: illustration,
                compact: compact,
                scheme: scheme,
                colors: colors,
              ),
              SizedBox(height: compact ? AppSpace.md : AppSpace.lg),
              Text(
                title,
                style: (compact ? text.titleMedium : text.titleLarge)?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                message,
                style: text.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null || secondaryActionLabel != null) ...[
                SizedBox(height: compact ? AppSpace.md : AppSpace.xl),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    if (actionLabel != null)
                      AppButton(
                        actionLabel!,
                        onPressed: onAction,
                        compact: true,
                        kind:
                            outlineAction
                                ? AppButtonKind.outline
                                : AppButtonKind.primary,
                      ),
                    if (secondaryActionLabel != null)
                      AppButton(
                        secondaryActionLabel!,
                        onPressed: onSecondaryAction,
                        compact: true,
                        kind: AppButtonKind.outline,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (reduceMotion) return content;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 6),
          child: child,
        ),
      ),
      child: content,
    );
  }
}

/// Crisp editorial fintech spot illustrations tailored to Hyprwise's 12px-radius
/// flat architectural design system (custom domain micro-scenes + tinted AppIcon
/// badge, strictly zero floating circles).
class _EmptyArchitecturalGraphic extends StatelessWidget {
  const _EmptyArchitecturalGraphic({
    required this.icon,
    required this.illustration,
    required this.compact,
    required this.scheme,
    required this.colors,
  });

  final IconGlyph icon;
  final EmptyIllustration illustration;
  final bool compact;
  final ColorScheme scheme;
  final AppColors colors;

  Color get _accentColor => switch (illustration) {
        EmptyIllustration.transactions ||
        EmptyIllustration.accounts ||
        EmptyIllustration.goals ||
        EmptyIllustration.backup => colors.income,
        EmptyIllustration.shifts ||
        EmptyIllustration.jobs ||
        EmptyIllustration.analytics ||
        EmptyIllustration.alerts => colors.brandText,
        EmptyIllustration.debts => colors.warning,
        EmptyIllustration.calendar ||
        EmptyIllustration.search ||
        EmptyIllustration.general => scheme.onSurface,
      };

  Color get _tintBg => switch (illustration) {
        EmptyIllustration.transactions ||
        EmptyIllustration.accounts ||
        EmptyIllustration.goals ||
        EmptyIllustration.backup => colors.incomeBg,
        EmptyIllustration.shifts ||
        EmptyIllustration.jobs ||
        EmptyIllustration.analytics ||
        EmptyIllustration.alerts => colors.brandBg,
        EmptyIllustration.debts => colors.warningBg,
        EmptyIllustration.calendar ||
        EmptyIllustration.search ||
        EmptyIllustration.general => colors.fill,
      };

  @override
  Widget build(BuildContext context) {
    final width = compact ? 96.0 : 124.0;
    final height = compact ? 74.0 : 94.0;
    final badgeSize = compact ? 36.0 : 44.0;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Editorial domain spot illustration (12px rounded-rect geometry)
          Positioned.fill(
            child: CustomPaint(
              painter: _EditorialSpotPainter(
                illustration: illustration,
                surface: scheme.surface,
                fill: colors.fill,
                hairline: scheme.outlineVariant,
                muted: scheme.onSurfaceVariant,
                accent: _accentColor,
                tintBg: _tintBg,
              ),
            ),
          ),
          // Anchored domain AppIcon badge (strictly 12px radius, crisp hairline)
          Positioned(
            right: compact ? 2 : 4,
            bottom: 0,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: _tintBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: _accentColor.withValues(alpha: 0.30),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: AppIcon(
                icon,
                size: compact ? 18 : 22,
                color: _accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorialSpotPainter extends CustomPainter {
  const _EditorialSpotPainter({
    required this.illustration,
    required this.surface,
    required this.fill,
    required this.hairline,
    required this.muted,
    required this.accent,
    required this.tintBg,
  });

  final EmptyIllustration illustration;
  final Color surface;
  final Color fill;
  final Color hairline;
  final Color muted;
  final Color accent;
  final Color tintBg;

  void _drawCard(Canvas canvas, Rect rect, Color bg, Color border, {double r = 10}) {
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(r));
    canvas.drawRRect(rr, Paint()..color = bg);
    canvas.drawRRect(
      rr,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
  }

  void _drawBar(Canvas canvas, Rect rect, Color color, {double r = 3}) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(r)),
      Paint()..color = color,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Subtle back ghost sheet for architectural depth (strictly rectangular, 12px)
    final backRect = Rect.fromLTWH(w * 0.10, 2, w * 0.72, h * 0.74);
    _drawCard(canvas, backRect, fill.withValues(alpha: 0.85), hairline, r: 10);

    // Primary foreground sheet
    final card = Rect.fromLTWH(w * 0.04, h * 0.12, w * 0.78, h * 0.76);
    _drawCard(canvas, card, surface, hairline, r: 12);

    final innerL = card.left + 10;
    final innerR = card.right - 10;
    final innerW = innerR - innerL;
    final innerT = card.top + 10;
    final innerH = card.height - 20;
    final subtleLine = muted.withValues(alpha: 0.22);
    final softAccent = accent.withValues(alpha: 0.28);

    switch (illustration) {
      case EmptyIllustration.transactions:
        // 3 mini ledger rows with right-aligned tabular amount bars
        for (var i = 0; i < 3; i++) {
          final y = innerT + i * (innerH / 3.1);
          _drawBar(canvas, Rect.fromLTWH(innerL, y, 7, 7), i == 0 ? softAccent : fill, r: 2);
          _drawBar(
            canvas,
            Rect.fromLTWH(innerL + 11, y + 1.5, innerW * (i == 1 ? 0.42 : 0.34), 4),
            subtleLine,
          );
          _drawBar(
            canvas,
            Rect.fromLTWH(innerR - innerW * 0.22, y + 1.5, innerW * 0.22, 4),
            i == 0 ? softAccent : subtleLine,
          );
        }
      case EmptyIllustration.shifts:
        // Timecard header + horizontal shift timeline bar
        _drawBar(canvas, Rect.fromLTWH(innerL, innerT, innerW * 0.48, 5), subtleLine);
        final trackY = innerT + innerH * 0.38;
        _drawBar(canvas, Rect.fromLTWH(innerL, trackY, innerW, 8), fill, r: 4);
        _drawBar(canvas, Rect.fromLTWH(innerL + innerW * 0.14, trackY, innerW * 0.56, 8), softAccent, r: 4);
        _drawBar(canvas, Rect.fromLTWH(innerL, innerT + innerH * 0.78, innerW * 0.36, 4), subtleLine);
      case EmptyIllustration.jobs:
        // Workplace pass card with header strip and hourly rate slots
        _drawBar(canvas, Rect.fromLTWH(innerL, innerT, innerW * 0.34, 12), tintBg, r: 4);
        _drawBar(canvas, Rect.fromLTWH(innerL + innerW * 0.42, innerT + 2, innerW * 0.46, 4.5), subtleLine);
        _drawBar(canvas, Rect.fromLTWH(innerL + innerW * 0.42, innerT + 9, innerW * 0.30, 3.5), subtleLine);
        _drawBar(canvas, Rect.fromLTWH(innerL, innerT + innerH * 0.65, innerW * 0.65, 5), softAccent, r: 3);
      case EmptyIllustration.goals:
        // Goal target card with crisp progress bar
        _drawBar(canvas, Rect.fromLTWH(innerL, innerT, innerW * 0.52, 5), subtleLine);
        _drawBar(canvas, Rect.fromLTWH(innerL, innerT + 11, innerW * 0.32, 4), softAccent);
        final barY = innerT + innerH * 0.68;
        _drawBar(canvas, Rect.fromLTWH(innerL, barY, innerW, 7), fill, r: 3.5);
        _drawBar(canvas, Rect.fromLTWH(innerL, barY, innerW * 0.58, 7), accent.withValues(alpha: 0.45), r: 3.5);
      case EmptyIllustration.debts:
        // Two-column split balance sheet (Lent / Borrowed)
        final colW = (innerW - 8) / 2;
        _drawCard(canvas, Rect.fromLTWH(innerL, innerT, colW, innerH * 0.88), fill.withValues(alpha: 0.7), hairline, r: 6);
        _drawCard(canvas, Rect.fromLTWH(innerL + colW + 8, innerT, colW, innerH * 0.88), tintBg.withValues(alpha: 0.7), hairline, r: 6);
        _drawBar(canvas, Rect.fromLTWH(innerL + 6, innerT + 8, colW - 12, 4), subtleLine);
        _drawBar(canvas, Rect.fromLTWH(innerL + colW + 14, innerT + 8, colW - 12, 4), softAccent);
      case EmptyIllustration.analytics:
        // Mini 4-bar rising architectural chart
        const heights = [0.36, 0.62, 0.48, 0.86];
        final barW = (innerW - 15) / 4;
        for (var i = 0; i < 4; i++) {
          final bh = innerH * heights[i];
          _drawBar(
            canvas,
            Rect.fromLTWH(innerL + i * (barW + 5), innerT + innerH - bh, barW, bh),
            i == 3 ? accent.withValues(alpha: 0.50) : (i == 1 ? softAccent : fill),
            r: 3,
          );
        }
      case EmptyIllustration.calendar:
        // Crisp 3x2 calendar week grid with highlighted active day tile
        _drawBar(canvas, Rect.fromLTWH(innerL, innerT, innerW, 6), fill, r: 3);
        final cellW = (innerW - 10) / 3;
        final cellH = (innerH - 18) / 2;
        for (var r = 0; r < 2; r++) {
          for (var c = 0; c < 3; c++) {
            final isHi = r == 0 && c == 1;
            _drawBar(
              canvas,
              Rect.fromLTWH(innerL + c * (cellW + 5), innerT + 12 + r * (cellH + 5), cellW, cellH),
              isHi ? softAccent : fill,
              r: 4,
            );
          }
        }
      case EmptyIllustration.alerts:
        // Two crisp notification banner strips with accent left edge
        for (var i = 0; i < 2; i++) {
          final y = innerT + i * (innerH * 0.50);
          _drawBar(canvas, Rect.fromLTWH(innerL, y, 3, 14), i == 0 ? accent.withValues(alpha: 0.65) : subtleLine, r: 1.5);
          _drawBar(canvas, Rect.fromLTWH(innerL + 8, y + 1, innerW * (i == 0 ? 0.62 : 0.48), 4.5), subtleLine);
          _drawBar(canvas, Rect.fromLTWH(innerL + 8, y + 9, innerW * 0.40, 3.5), fill);
        }
      case EmptyIllustration.accounts:
        // Sleek wallet card layout with chip rectangle & account lines
        _drawBar(canvas, Rect.fromLTWH(innerL, innerT, 14, 10), softAccent, r: 3);
        _drawBar(canvas, Rect.fromLTWH(innerL, innerT + innerH * 0.52, innerW * 0.58, 5), subtleLine);
        _drawBar(canvas, Rect.fromLTWH(innerL, innerT + innerH * 0.78, innerW * 0.36, 4), fill);
      case EmptyIllustration.backup:
        // Encrypted vault sheet with synchronized bars
        _drawBar(canvas, Rect.fromLTWH(innerL, innerT, innerW * 0.68, 5), softAccent);
        _drawBar(canvas, Rect.fromLTWH(innerL, innerT + 12, innerW * 0.85, 4), subtleLine);
        _drawBar(canvas, Rect.fromLTWH(innerL, innerT + 22, innerW * 0.54, 4), fill);
      case EmptyIllustration.search:
      case EmptyIllustration.general:
        // Minimal search/filter query card lines
        _drawBar(canvas, Rect.fromLTWH(innerL, innerT, innerW * 0.72, 6), fill, r: 3);
        _drawBar(canvas, Rect.fromLTWH(innerL, innerT + 14, innerW * 0.55, 4), subtleLine);
        _drawBar(canvas, Rect.fromLTWH(innerL, innerT + 24, innerW * 0.40, 4), subtleLine);
    }
  }

  @override
  bool shouldRepaint(_EditorialSpotPainter oldDelegate) =>
      oldDelegate.illustration != illustration ||
      oldDelegate.surface != surface ||
      oldDelegate.fill != fill ||
      oldDelegate.hairline != hairline ||
      oldDelegate.accent != accent;
}
