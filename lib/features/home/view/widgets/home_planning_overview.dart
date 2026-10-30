import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/home/viewmodels/home_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/app_card.dart';
import 'package:finance_tracker/features/shared/widgets/app_icon.dart';
import 'package:finance_tracker/features/shared/widgets/section_header.dart';

/// Planning snapshots keep goals and the 30-day outlook visible without
/// duplicating the richer timeline and goal-management screens.
class HomePlanningOverview extends StatelessWidget {
  const HomePlanningOverview({super.key, required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final tr = context.strings;
    final forecast = viewModel.forecast;
    final goal =
        forecast.goalForecasts.isEmpty ? null : forecast.goalForecasts.first;
    final colors = context.colors;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final netChange = forecast.netChangeMinor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          tr.plan,
          padding: const EdgeInsets.fromLTRB(0, AppSpace.xl, 0, AppSpace.sm),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          onTap: () => context.push(AppRoutes.plan),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpace.lg),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.brandBg,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      alignment: Alignment.center,
                      child: AppIcon(
                        HugeIcons.strokeRoundedTarget02,
                        size: 18,
                        color: colors.brand,
                      ),
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal?.goal.name ?? tr.savingsGoal,
                            style: text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            goal == null
                                ? tr.t(
                                  'Set a target to track your progress',
                                  ne: 'प्रगति ट्र्याक गर्न लक्ष्य राख्नुहोस्',
                                  hi: 'प्रगति देखने के लिए लक्ष्य बनाएं',
                                  es: 'Crea una meta para ver tu progreso',
                                  fr:
                                      'Créez un objectif pour suivre votre progression',
                                  de:
                                      'Lege ein Ziel fest, um deinen Fortschritt zu verfolgen',
                                  ja: '進捗を追うために目標を設定',
                                  zh: '设置目标以跟踪进度',
                                  it:
                                      'Imposta un obiettivo per monitorare i progressi',
                                )
                                : '${(goal.progress.fraction.clamp(0.0, 1.0) * 100).round()}% ${tr.t('funded', ne: 'जम्मा भएको', hi: 'फंडेड', es: 'financiado', fr: 'financé', de: 'finanziert', ja: '達成', zh: '已筹集', it: 'finanziato')}',
                            style: text.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              if (goal != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.lg,
                    0,
                    AppSpace.lg,
                    AppSpace.lg,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: SizedBox(
                      height: 7,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ColoredBox(
                            color: colors.brand.withValues(alpha: 0.14),
                          ),
                          FractionallySizedBox(
                            alignment: AlignmentDirectional.centerStart,
                            widthFactor: goal.progress.fraction.clamp(0.0, 1.0),
                            child: ColoredBox(color: colors.brand),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        AppCard(
          onTap: () => context.go(AppRoutes.plan),
          child: Row(
            children: [
              AppIcon(
                HugeIcons.strokeRoundedChartLineData01,
                size: 20,
                color: colors.brand,
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr.outlook,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${forecast.horizonDays} ${tr.t('days', ne: 'दिन', hi: 'दिन', es: 'días', fr: 'jours', de: 'Tage', ja: '日間', zh: '天', it: 'giorni')} · ${forecast.events.length} ${tr.t('planned items', ne: 'योजनाबद्ध आइटम', hi: 'नियोजित आइटम', es: 'elementos planeados', fr: 'éléments planifiés', de: 'geplante Einträge', ja: '予定項目', zh: '计划项目', it: 'elementi pianificati')}',
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${netChange >= 0 ? '+' : ''}${MoneyFormatter.compact(netChange, viewModel.baseCurrency)}',
                style: text.labelLarge?.copyWith(
                  color: netChange < 0 ? colors.expense : colors.income,
                  fontFamily: 'RedditMono',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
