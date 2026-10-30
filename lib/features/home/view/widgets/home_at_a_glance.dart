import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/home/viewmodels/home_view_model.dart';
import 'package:finance_tracker/features/plan/data/forecast_engine.dart';
import 'package:finance_tracker/features/shared/widgets/app_card.dart';
import 'package:finance_tracker/features/shared/widgets/app_icon.dart';
import 'package:finance_tracker/features/shared/widgets/row_divider.dart';
import 'package:finance_tracker/features/shared/widgets/section_header.dart';

/// The information that is useful between visits but does not belong in the
/// balance hero: spending concentration, open lending/borrowing, and work.
class HomeAtAGlance extends StatelessWidget {
  const HomeAtAGlance({super.key, required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final tr = context.strings;
    final shiftEvents =
        viewModel.upcomingEvents
            .where((event) => event.kind == ForecastEventKind.shift)
            .toList();
    final nextShift = shiftEvents.isEmpty ? null : shiftEvents.first;
    final hasDebts =
        viewModel.totalLentMinor > 0 || viewModel.totalBorrowedMinor > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          tr.t(
            'At a glance',
            ne: 'एक नजरमा',
            hi: 'एक नज़र में',
            es: 'De un vistazo',
            fr: 'En un coup d’œil',
            de: 'Auf einen Blick',
            ja: 'ひと目で確認',
            zh: '一目了然',
            it: 'A colpo d’occhio',
          ),
          padding: const EdgeInsets.fromLTRB(0, AppSpace.xl, 0, AppSpace.sm),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _GlanceRow(
                icon: HugeIcons.strokeRoundedExchange02,
                iconColor:
                    hasDebts
                        ? context.colors.warning
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                title: tr.debts,
                detail:
                    hasDebts
                        ? '${tr.lentLabel}: ${MoneyFormatter.format(viewModel.totalLentMinor, viewModel.baseCurrency)} · ${tr.borrowedLabel}: ${MoneyFormatter.format(viewModel.totalBorrowedMinor, viewModel.baseCurrency)}'
                        : tr.t(
                          'No open lending or borrowing',
                          ne: 'खुला लेनदेन छैन',
                          hi: 'कोई खुला उधार नहीं',
                          es: 'Sin préstamos abiertos',
                          fr: 'Aucun prêt en cours',
                          de: 'Keine offenen Darlehen',
                          ja: '未精算の貸し借りはありません',
                          zh: '暂无未结借贷',
                          it: 'Nessun prestito aperto',
                        ),
                onTap: () => context.push(AppRoutes.debts),
              ),
              const RowDivider(),
              _GlanceRow(
                icon: HugeIcons.strokeRoundedClock01,
                iconColor: context.colors.income,
                title: tr.work,
                detail:
                    viewModel.completedShiftCountThisMonth > 0
                        ? tr.t(
                          '${viewModel.completedShiftCountThisMonth} completed shifts · ${(viewModel.workedMinutesThisMonth / 60).toStringAsFixed(1)}h',
                          ne:
                              '${viewModel.completedShiftCountThisMonth} सम्पन्न सिफ्ट · ${(viewModel.workedMinutesThisMonth / 60).toStringAsFixed(1)} घण्टा',
                          hi:
                              '${viewModel.completedShiftCountThisMonth} पूरी शिफ्ट · ${(viewModel.workedMinutesThisMonth / 60).toStringAsFixed(1)} घंटे',
                          es:
                              '${viewModel.completedShiftCountThisMonth} turnos completados · ${(viewModel.workedMinutesThisMonth / 60).toStringAsFixed(1)} h',
                          fr:
                              '${viewModel.completedShiftCountThisMonth} quarts terminés · ${(viewModel.workedMinutesThisMonth / 60).toStringAsFixed(1)} h',
                          de:
                              '${viewModel.completedShiftCountThisMonth} erledigte Schichten · ${(viewModel.workedMinutesThisMonth / 60).toStringAsFixed(1)} Std.',
                          ja:
                              '${viewModel.completedShiftCountThisMonth}件完了 · ${(viewModel.workedMinutesThisMonth / 60).toStringAsFixed(1)}時間',
                          zh:
                              '${viewModel.completedShiftCountThisMonth} 个已完成班次 · ${(viewModel.workedMinutesThisMonth / 60).toStringAsFixed(1)} 小时',
                          it:
                              '${viewModel.completedShiftCountThisMonth} turni completati · ${(viewModel.workedMinutesThisMonth / 60).toStringAsFixed(1)} h',
                        )
                        : nextShift == null
                        ? tr.t(
                          'No shift scheduled',
                          ne: 'सिफ्ट तय छैन',
                          hi: 'कोई शिफ्ट निर्धारित नहीं',
                          es: 'Sin turnos programados',
                          fr: 'Aucun quart prévu',
                          de: 'Keine Schicht geplant',
                          ja: '予定されたシフトはありません',
                          zh: '暂无排班',
                          it: 'Nessun turno programmato',
                        )
                        : '${nextShift.label} · ${AppDate.weekdayDay(nextShift.date)}',
                trailing:
                    viewModel.completedShiftCountThisMonth > 0
                        ? MoneyFormatter.format(
                          viewModel.shiftEarningsThisMonth,
                          viewModel.baseCurrency,
                        )
                        : nextShift?.rateFormatted,
                onTap: () => context.push(AppRoutes.work),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlanceRow extends StatelessWidget {
  const _GlanceRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.detail,
    required this.onTap,
    this.trailing,
  });

  final IconGlyph icon;
  final Color iconColor;
  final String title;
  final String detail;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.md,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              alignment: Alignment.center,
              child: AppIcon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    detail,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpace.sm),
              SizedBox(
                width: 76,
                child: Text(
                  trailing!,
                  style: text.labelSmall?.copyWith(
                    fontFamily: 'RedditMono',
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
            const SizedBox(width: AppSpace.sm),
            SizedBox(
              width: 18,
              height: 36,
              child: Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
