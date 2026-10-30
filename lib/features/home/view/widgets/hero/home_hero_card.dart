import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/home/viewmodels/home_view_model.dart';
import 'package:finance_tracker/features/home/view/widgets/hero/account_stack_bar.dart';
import 'package:finance_tracker/features/home/view/widgets/hero/hero_empty_state.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

/// A concise financial snapshot: position, short-term direction, and the
/// three money buckets a person can act on. Detailed reporting lives in its
/// dedicated tabs, keeping the dashboard calm and useful.
class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({super.key, required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (!viewModel.hasAccounts) return HeroEmptyState(viewModel: viewModel);

    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final tr = context.strings;
    final net = viewModel.netPositionMinor;
    final monthNet = viewModel.monthIncome - viewModel.monthExpense;
    final gain = monthNet > 0;
    final deltaColor =
        monthNet < 0
            ? colors.expense
            : (gain ? colors.income : colors.onHeroSecondary);
    final netColor = net < 0 ? colors.expense : colors.onHero;

    return HeroCard(
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: -86,
            right: -88,
            child: IgnorePointer(
              child: Container(
                width: 248,
                height: 248,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.brand.withValues(alpha: 0.10),
                  border: Border.all(
                    color: colors.brand.withValues(alpha: 0.12),
                    width: 30,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 68,
            right: 0,
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  size: const Size(92, 48),
                  painter: _HeroSparklinePainter(
                    points: viewModel.balanceSeries(14),
                    color: net < 0 ? colors.expense : colors.brand,
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tr.netPosition,
                      style: text.bodySmall?.copyWith(
                        color: colors.onHeroSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (viewModel.usableRatio > 0)
                    _LiquidityPill(
                      ratio: viewModel.usableRatio,
                      colors: colors,
                      tr: tr,
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              Padding(
                padding: const EdgeInsets.only(right: 58),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    MoneyFormatter.format(net, viewModel.baseCurrency),
                    style: text.displaySmall?.copyWith(
                      color: netColor,
                      fontFamily: 'RedditMono',
                      fontSize: 35,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.7,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text:
                          '${gain ? '+' : ''}${MoneyFormatter.format(monthNet, viewModel.baseCurrency)}',
                      style: text.bodySmall?.copyWith(
                        color: deltaColor,
                        fontFamily: 'RedditMono',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: ' ${tr.thisMonth}',
                      style: text.bodySmall?.copyWith(
                        color: colors.onHeroSecondary,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpace.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tr.t(
                        'Money allocation',
                        ne: 'रकमको बाँडफाँड',
                        hi: 'धन आवंटन',
                        es: 'Distribución del dinero',
                        fr: 'Répartition de l’argent',
                        de: 'Geldaufteilung',
                        ja: '資金配分',
                        zh: '资金分配',
                        it: 'Allocazione del denaro',
                      ),
                      style: text.labelSmall?.copyWith(
                        color: colors.onHeroSecondary,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Flexible(
                    child: Text(
                      tr.t(
                        'Spendable · Reserved',
                        ne: 'खर्चयोग्य · बचत',
                        hi: 'खर्च योग्य · आरक्षित',
                        es: 'Disponible · Reservado',
                        fr: 'Disponible · Réservé',
                        de: 'Verfügbar · Reserviert',
                        ja: '使える · 予約済み',
                        zh: '可用 · 已预留',
                        it: 'Disponibile · Riservato',
                      ),
                      style: text.labelSmall?.copyWith(
                        color: colors.onHeroSecondary,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.xs),
              AccountStackBar(
                slices: viewModel.accountSlices,
                selectedAccountId: null,
                onSelectAccount: (_) {},
                totalNetMinor: net,
              ),
              const SizedBox(height: AppSpace.md),
              Divider(height: 1, color: colors.onHero.withValues(alpha: 0.12)),
              const SizedBox(height: AppSpace.md),
              _LiquidityBuckets(viewModel: viewModel, colors: colors, tr: tr),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiquidityPill extends StatelessWidget {
  const _LiquidityPill({
    required this.ratio,
    required this.colors,
    required this.tr,
  });

  final double ratio;
  final AppColors colors;
  final AppStrings tr;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 4),
    decoration: BoxDecoration(
      color: colors.liquid.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border: Border.all(color: colors.liquid.withValues(alpha: 0.28)),
    ),
    child: Text(
      '${tr.formatNumber((ratio * 100).round())}% ${tr.spendable}',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: colors.liquid,
        fontFamily: 'RedditMono',
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _LiquidityBuckets extends StatelessWidget {
  const _LiquidityBuckets({
    required this.viewModel,
    required this.colors,
    required this.tr,
  });

  final HomeViewModel viewModel;
  final AppColors colors;
  final AppStrings tr;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: _HeroBucket(
          icon: HugeIcons.strokeRoundedArrowUpRight01,
          color: colors.liquid,
          title: tr.spendable,
          amount: viewModel.usableBalanceMinor,
          subtitle: tr.everydayAndCash,
          currency: viewModel.baseCurrency,
          percentage:
              '${tr.formatNumber((viewModel.usableRatio * 100).round())}%',
          onTap: () => context.push(AppRoutes.accounts),
        ),
      ),
      const SizedBox(width: AppSpace.sm),
      Expanded(
        child: _HeroBucket(
          icon: HugeIcons.strokeRoundedTarget02,
          color: colors.brand,
          title: tr.reserved,
          amount: viewModel.nonUsableBalanceMinor,
          subtitle: tr.savingsAndGoals,
          currency: viewModel.baseCurrency,
          percentage:
              '${tr.formatNumber((viewModel.nonUsableRatio * 100).round())}%',
          onTap: () => context.push(AppRoutes.plan),
        ),
      ),
    ],
  );
}

class _HeroBucket extends StatelessWidget {
  const _HeroBucket({
    required this.icon,
    required this.color,
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.currency,
    required this.onTap,
    required this.percentage,
  });

  final IconGlyph icon;
  final Color color;
  final String title;
  final int amount;
  final String subtitle;
  final String currency;
  final String percentage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              AppIcon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: text.labelSmall?.copyWith(
                    color: colors.onHeroSecondary,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                percentage,
                style: text.labelSmall?.copyWith(
                  color: colors.onHeroSecondary,
                  fontFamily: 'RedditMono',
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              MoneyFormatter.format(amount, currency),
              style: text.labelSmall?.copyWith(
                color: colors.onHero,
                fontFamily: 'RedditMono',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: text.labelSmall?.copyWith(
              color: colors.onHeroSecondary,
              fontSize: 9.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _HeroSparklinePainter extends CustomPainter {
  const _HeroSparklinePainter({required this.points, required this.color});

  final List<BalancePoint> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final values = points.map((point) => point.minor.toDouble()).toList();
    if (values.length < 2) return;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final span = (max - min).abs() < 1 ? 1.0 : max - min;
    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final x = size.width * index / (values.length - 1);
      final y =
          size.height - 5 - ((values[index] - min) / span) * (size.height - 10);
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _HeroSparklinePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}
