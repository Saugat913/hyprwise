import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/analytics/data/analytics_tab_data.dart';
import 'package:finance_tracker/features/analytics/viewmodels/analytics_view_model.dart';
import 'package:finance_tracker/features/debts/data/model/debt.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/shared/data/categories.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

String _duration(AppStrings tr, int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return '${tr.formatNumber(h)}${tr.hourAbbr} ${tr.formatNumber(m)}${tr.minuteAbbr}';
}

const _tabPadding = EdgeInsets.fromLTRB(
  AppSpace.page,
  AppSpace.sm,
  AppSpace.page,
  AppSpace.xxl,
);

/// Income or Expenses tab: totals, trend, category breakdown, top items.
class AnalyticsTransactionsTab extends StatelessWidget {
  const AnalyticsTransactionsTab({
    super.key,
    required this.viewModel,
    required this.type,
  });

  final AnalyticsViewModel viewModel;
  final TransactionType type;

  @override
  Widget build(BuildContext context) {
    final tr = context.strings;
    final text = Theme.of(context).textTheme;
    final isExpense = type == TransactionType.expense;
    final data = viewModel.txTabData(type);
    final currency = viewModel.baseCurrency;

    if (data.count == 0) {
      return EmptyState(
        icon: HugeIcons.strokeRoundedChartHistogram,
        title: tr.noDataForThisFilter,
        message: tr.analyticsNoEntriesInPeriod,
      );
    }

    return ListView(
      padding: _tabPadding,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isExpense ? tr.totalSpending : tr.totalIncome,
                style: text.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              _AnimatedMoney(
                data.totalMinor,
                currency,
                style: text.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isExpense ? null : context.colors.income,
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Row(
                children: [
                  _Stat(tr.analyticsTransactionsCount, tr.formatNumber(data.count)),
                  _Stat(
                    tr.analyticsAverage,
                    MoneyFormatter.format(data.averageMinor, currency),
                  ),
                ],
              ),
            ],
          ),
        ),
        SectionHeader(tr.analyticsTrend),
        AppCard(child: AnimatedBarChart(trend: data.trend, currencyCode: currency)),
        if (data.categories.isNotEmpty) ...[
          SectionHeader(tr.analyticsByCategory),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < data.categories.length; i++) ...[
                  if (i > 0) const RowDivider(),
                  _ShareRow(
                    label: data.categories[i].label,
                    amountMinor: data.categories[i].amountMinor,
                    totalMinor: data.totalMinor,
                    currency: currency,
                  ),
                ],
              ],
            ),
          ),
        ],
        SectionHeader(tr.analyticsTopItems),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < data.top.take(5).length; i++) ...[
                if (i > 0) const RowDivider(),
                ListRow(
                  leading: LetterAvatar(data.top[i].name, size: 36),
                  title: data.top[i].name,
                  subtitle:
                      '${TransactionCategories.fromValue(data.top[i].category, type).label} · ${tr.formatNumber(data.top[i].count)}×',
                  trailing: MoneyText(
                    data.top[i].amountMinor,
                    currency,
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Lend or Borrow tab: totals, trend, per-person breakdown, largest entries.
class AnalyticsDebtTab extends StatelessWidget {
  const AnalyticsDebtTab({
    super.key,
    required this.viewModel,
    required this.type,
  });

  final AnalyticsViewModel viewModel;
  final DebtType type;

  @override
  Widget build(BuildContext context) {
    final tr = context.strings;
    final text = Theme.of(context).textTheme;
    final data = viewModel.debtTabData(type);
    final currency = viewModel.baseCurrency;
    final isLend = type == DebtType.lent;

    if (data.count == 0) {
      if (viewModel.selectedDebtParty != null) {
        return EmptyState(
          icon: HugeIcons.strokeRoundedUserSquare,
          title: tr.noDataForThisFilter,
          message: tr.t(
            'No records found for ${viewModel.selectedDebtParty} in this period.',
            ne: 'यस अवधिमा ${viewModel.selectedDebtParty} को कुनै रेकर्ड भेटिएन।',
            es: 'No se encontraron registros para ${viewModel.selectedDebtParty} en este período.',
            fr: 'Aucun enregistrement trouvé pour ${viewModel.selectedDebtParty} pour cette période.',
            de: 'Keine Einträge für ${viewModel.selectedDebtParty} in diesem Zeitraum gefunden.',
            ja: 'この期間の${viewModel.selectedDebtParty}の記録は見つかりませんでした。',
            zh: '此期间未找到 ${viewModel.selectedDebtParty} 的记录。',
            it: 'Nessun record trovato per ${viewModel.selectedDebtParty} in questo periodo.',
          ),
          actionLabel: tr.allParties,
          onAction: () => viewModel.selectDebtParty(null),
        );
      }
      return EmptyState(
        icon: HugeIcons.strokeRoundedChartHistogram,
        title: tr.noDataForThisFilter,
        message: tr.analyticsNoEntriesInPeriod,
      );
    }

    final allPartiesTotal = data.parties.fold<int>(0, (sum, p) => sum + p.amountMinor);

    return ListView(
      padding: _tabPadding,
      children: [
        if (viewModel.selectedDebtParty != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.md),
            child: Row(
              children: [
                InputChip(
                  avatar: LetterAvatar(viewModel.selectedDebtParty!, size: 20),
                  label: Text(
                    viewModel.selectedDebtParty!,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onDeleted: () => viewModel.selectDebtParty(null),
                  deleteIconColor: Theme.of(context).colorScheme.primary,
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  side: BorderSide(color: Theme.of(context).colorScheme.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
                const SizedBox(width: AppSpace.sm),
                TextButton(
                  onPressed: () => viewModel.selectDebtParty(null),
                  child: Text(tr.clearAction),
                ),
              ],
            ),
          ),
        ],
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isLend ? tr.lentToOthers : tr.borrowedFromOthers,
                style: text.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              _AnimatedMoney(
                data.totalMinor,
                currency,
                style: text.displaySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpace.lg),
              Row(
                children: [
                  _Stat(
                    tr.analyticsOutstanding,
                    MoneyFormatter.format(data.outstandingMinor, currency),
                  ),
                  _Stat(
                    tr.analyticsSettled,
                    MoneyFormatter.format(data.settledMinor, currency),
                    color: context.colors.income,
                  ),
                  _Stat(tr.analyticsEntriesCount, tr.formatNumber(data.count)),
                ],
              ),
            ],
          ),
        ),
        SectionHeader(tr.analyticsTrend),
        AppCard(child: AnimatedBarChart(trend: data.trend, currencyCode: currency)),
        SectionHeader(tr.analyticsByPerson),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < data.parties.length; i++) ...[
                if (i > 0) const RowDivider(),
                _ShareRow(
                  leading: LetterAvatar(data.parties[i].name, size: 28),
                  label: data.parties[i].name,
                  amountMinor: data.parties[i].amountMinor,
                  totalMinor: allPartiesTotal > 0 ? allPartiesTotal : data.totalMinor,
                  currency: currency,
                  isSelected:
                      viewModel.selectedDebtParty?.trim().toLowerCase() ==
                      data.parties[i].name.trim().toLowerCase(),
                  onTap: () => viewModel.selectDebtParty(data.parties[i].name),
                ),
              ],
            ],
          ),
        ),
        SectionHeader(tr.analyticsTopItems),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < data.top.take(5).length; i++) ...[
                if (i > 0) const RowDivider(),
                _DebtItemRow(debt: data.top[i], viewModel: viewModel),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DebtItemRow extends StatelessWidget {
  const _DebtItemRow({required this.debt, required this.viewModel});

  final Debt debt;
  final AnalyticsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final tr = context.strings;
    return ListRow(
      leading: LetterAvatar(debt.personName, size: 36),
      title: debt.personName,
      subtitle: AppDate.short(
        DateTime.fromMillisecondsSinceEpoch(debt.createdAt),
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          MoneyText(
            debt.amountMinor,
            debt.currencyCode,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (debt.isSettled)
            StatusChip(tr.analyticsSettled, tone: ChipTone.success),
        ],
      ),
    );
  }
}

/// Shifts & Work tab: hours, earnings, overtime, breaks, per-job and weekly.
class AnalyticsWorkTab extends StatefulWidget {
  const AnalyticsWorkTab({super.key, required this.viewModel});

  final AnalyticsViewModel viewModel;

  @override
  State<AnalyticsWorkTab> createState() => _AnalyticsWorkTabState();
}

class _AnalyticsWorkTabState extends State<AnalyticsWorkTab> {
  bool _showEarnings = false;

  static const _jobPalette = [
    Color(0xFFFF6500),
    Color(0xFF1565C0),
    Color(0xFF6A1B9A),
    Color(0xFFC2185B),
    Color(0xFFE65100),
    Color(0xFF455A64),
  ];

  @override
  Widget build(BuildContext context) {
    final tr = context.strings;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final data = widget.viewModel.workTabData();
    final currency = widget.viewModel.baseCurrency;

    if (data.shiftCount == 0) {
      return EmptyState(
        icon: HugeIcons.strokeRoundedChartHistogram,
        title: tr.noDataForThisFilter,
        message: tr.analyticsNoShiftsInPeriod,
      );
    }

    final weekValues = [
      for (final w in data.weeks)
        _showEarnings ? w.earningsMinor.toDouble() : w.minutes / 60,
    ];
    final weekLabels = [
      for (final w in data.weeks)
        '${DateFormatter.monthShort(w.start)} ${tr.formatNumber(w.start.day)}',
    ];

    return ListView(
      padding: _tabPadding,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr.analyticsEarnings,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              _AnimatedMoney(
                data.earningsMinor,
                currency,
                style: text.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colors.income,
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Row(
                children: [
                  _Stat(
                    tr.analyticsTotalHours,
                    _duration(tr, data.totalMinutes),
                  ),
                  _Stat(tr.analyticsShiftsCount, tr.formatNumber(data.shiftCount)),
                  _Stat(
                    tr.analyticsAvgShiftLength,
                    _duration(tr, data.averageShiftMinutes),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              Row(
                children: [
                  _Stat(
                    tr.analyticsOvertimeHours,
                    _duration(tr, data.overtimeMinutes),
                    color:
                        data.overtimeMinutes > 0 ? context.colors.brand : null,
                  ),
                  _Stat(
                    tr.analyticsBreakTime,
                    _duration(tr, data.breakMinutes),
                  ),
                ],
              ),
            ],
          ),
        ),
        SectionHeader(
          tr.t(
            'This Week (Mon – Sun)',
            ne: 'यो हप्ता (सोम – आइत)',
            es: 'Esta semana (Lun – Dom)',
            fr: 'Cette semaine (Lun – Dim)',
            de: 'Diese Woche (Mo – So)',
            ja: '今週 (月〜日)',
            zh: '本周 (周一至周日)',
            it: 'Questa settimana (Lun – Dom)',
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr.t(
                          'Current Week Worked',
                          ne: 'यस हप्ताको काम',
                          es: 'Trabajado esta semana',
                          fr: 'Travaillé cette semaine',
                          de: 'Diese Woche gearbeitet',
                          ja: '今週の労働',
                          zh: '本周工作',
                          it: 'Lavorato questa settimana',
                        ),
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _duration(tr, data.currentWeekTotalMinutes),
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontFamily: 'RedditMono',
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        tr.analyticsEarnings,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        MoneyFormatter.format(
                          data.currentWeekEarningsMinor,
                          currency,
                        ),
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontFamily: 'RedditMono',
                          color: context.colors.income,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              Row(
                children: [
                  for (final day in data.currentWeekDays)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: _CurrentWeekDayColumn(
                          day: day,
                          currency: currency,
                          maxMinutes: data.currentWeekDays.fold(
                            60,
                            (max, d) => d.minutes > max ? d.minutes : max,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        SectionHeader(tr.analyticsWeeklyBreakdown),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ToggleChip(
                    label: tr.analyticsHoursChip,
                    selected: !_showEarnings,
                    onTap: () => setState(() => _showEarnings = false),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  _ToggleChip(
                    label: tr.analyticsEarnings,
                    selected: _showEarnings,
                    onTap: () => setState(() => _showEarnings = true),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              AnimatedBarChart(
                trend: AnalyticsTrend(weekValues, weekLabels),
                currencyCode: _showEarnings ? currency : null,
                unitSuffix: _showEarnings ? null : 'h',
              ),
            ],
          ),
        ),
        SectionHeader(tr.analyticsEarningsByJob),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < data.jobs.length; i++) ...[
                if (i > 0) const RowDivider(),
                _JobRow(
                  job: data.jobs[i],
                  color:
                      _jobPalette[data.jobs[i].job.colorIndex %
                          _jobPalette.length],
                  totalMinor: data.earningsMinor,
                  currency: currency,
                  subtitle:
                      '${_duration(tr, data.jobs[i].minutes)} · ${tr.formatNumber(data.jobs[i].shifts)} ${tr.analyticsShiftsCount.toLowerCase()}',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({
    required this.job,
    required this.color,
    required this.totalMinor,
    required this.currency,
    required this.subtitle,
  });

  final AnalyticsJobEarnings job;
  final Color color;
  final int totalMinor;
  final String currency;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final share = totalMinor > 0 ? job.earningsMinor / totalMinor : 0.0;
    return Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.job.name,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(subtitle, style: text.bodySmall),
                  ],
                ),
              ),
              MoneyText(
                job.earningsMinor,
                currency,
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          _AnimatedProgress(share, color: color),
        ],
      ),
    );
  }
}

class _ShareRow extends StatelessWidget {
  const _ShareRow({
    required this.label,
    required this.amountMinor,
    required this.totalMinor,
    required this.currency,
    this.isSelected = false,
    this.onTap,
    this.leading,
  });

  final String label;
  final int amountMinor;
  final int totalMinor;
  final String currency;
  final bool isSelected;
  final VoidCallback? onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final share = totalMinor > 0 ? amountMinor / totalMinor : 0.0;
    final content = Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        children: [
          Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpace.md),
              ],
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall?.copyWith(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected ? Theme.of(context).colorScheme.primary : null,
                        ),
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: AppSpace.xs),
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ],
                ),
              ),
              Text('${context.strings.formatNumber((share * 100).round())}%', style: text.bodySmall),
              const SizedBox(width: AppSpace.md),
              MoneyText(
                amountMinor,
                currency,
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Theme.of(context).colorScheme.primary : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          _AnimatedProgress(
            share,
            color: isSelected ? Theme.of(context).colorScheme.primary : context.colors.brand,
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.06)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: content,
        ),
      );
    }

    return content;
  }
}

class _AnimatedProgress extends StatelessWidget {
  const _AnimatedProgress(this.value, {required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => ProgressLine(v, color: color),
    );
  }
}

class _AnimatedMoney extends StatelessWidget {
  const _AnimatedMoney(this.minor, this.currency, {this.style});

  final int minor;
  final String currency;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: minor.toDouble()),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder:
          (_, v, _) =>
              Text(MoneyFormatter.format(v.round(), currency), style: style),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 2,
            style: text.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: text.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? scheme.onSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? scheme.onSurface : scheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: selected ? scheme.surface : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// Bar chart in brand orange whose bars grow in whenever the data changes.
/// Displays clear numerical values and formatted summary metrics.
class AnimatedBarChart extends StatelessWidget {
  const AnimatedBarChart({
    super.key,
    required this.trend,
    this.height = 140,
    this.currencyCode,
    this.valueFormatter,
    this.unitSuffix,
  });

  final AnalyticsTrend trend;
  final double height;
  final String? currencyCode;
  final String Function(double)? valueFormatter;
  final String? unitSuffix;

  String _formatValue(BuildContext context, double val) {
    if (valueFormatter != null) return valueFormatter!(val);
    final tr = context.strings;
    if (currencyCode != null) {
      return MoneyFormatter.compact(val.round(), currencyCode!);
    }
    if (unitSuffix != null) {
      final formatted = tr.localizeDigits(
        val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1),
      );
      return '$formatted$unitSuffix';
    }
    if (val >= 1000) {
      return '${tr.localizeDigits((val / 1000).toStringAsFixed(1))}k';
    }
    return tr.localizeDigits(
      val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final tr = context.strings;
    final values = trend.values;
    final peak = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    final total = values.fold(0.0, (sum, v) => sum + v);
    final effectiveMax = _niceCeil(peak);
    final brand = context.colors.brand;
    final labelEvery = values.length > 16 ? 4 : (values.length > 8 ? 2 : 1);
    final showValueAboveBar = values.length <= 14;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (peak > 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${tr.t('Peak', ne: 'अधिकतम', es: 'Pico', fr: 'Pic', de: 'Spitze', ja: 'ピーク', zh: '峰值', it: 'Picco')}: ${_formatValue(context, peak)}',
                style: text.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontFamily: 'RedditMono',
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              if (total > 0)
                Text(
                  '${tr.t('Total', ne: 'जम्मा', es: 'Total', fr: 'Total', de: 'Gesamt', ja: '合計', zh: '总计', it: 'Totale')}: ${_formatValue(context, total)}',
                  style: text.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFamily: 'RedditMono',
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
        ],
        TweenAnimationBuilder<double>(
          key: ValueKey(Object.hashAll(values)),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutCubic,
          builder:
              (context, t, _) => SizedBox(
                height: height,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ChartGridPainter(
                          maxValue: effectiveMax,
                          labelBuilder: (v) => _formatValue(context, v),
                          lineColor: scheme.outlineVariant.withValues(alpha: 0.5),
                          textColor: scheme.onSurfaceVariant,
                          bottomInset: 20,
                          topInset: 18,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: _ChartGridPainter.gutter),
                      child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < values.length; i++)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                values.length > 16
                                    ? 1
                                    : (values.length > 8 ? 2 : 3),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        final maxBarH =
                                            constraints.maxHeight - 18;
                                        final barH = (values[i] /
                                                effectiveMax *
                                                maxBarH *
                                                t)
                                            .clamp(4.0, maxBarH);
                                        return Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            if (values[i] > 0 &&
                                                (showValueAboveBar ||
                                                    values[i] == peak))
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 2,
                                                ),
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(
                                                    _formatValue(
                                                      context,
                                                      values[i],
                                                    ),
                                                    style: text.labelSmall
                                                        ?.copyWith(
                                                          fontSize:
                                                              values.length > 8
                                                                  ? 8
                                                                  : 9.5,
                                                          fontFamily:
                                                              'RedditMono',
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color:
                                                              values[i] == peak
                                                                  ? brand
                                                                  : scheme
                                                                      .onSurfaceVariant,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            Container(
                                              height: barH,
                                              decoration: BoxDecoration(
                                                color:
                                                    values[i] > 0
                                                        ? (values[i] == peak
                                                            ? brand
                                                            : brand.withValues(
                                                              alpha: 0.85,
                                                            ))
                                                        : scheme.outlineVariant
                                                            .withValues(
                                                              alpha: 0.3,
                                                            ),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      AppRadius.sm,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                height: 14,
                                child:
                                    i % labelEvery == 0 &&
                                            i < trend.labels.length
                                        ? Text(
                                          trend.labels[i],
                                          softWrap: false,
                                          overflow: TextOverflow.visible,
                                          style: text.labelSmall?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                            fontSize: 10,
                                          ),
                                        )
                                        : null,
                              ),
                            ],
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
      ],
    );
  }
}

/// Nice rounded ceiling so gridline labels are clean (1, 2, 2.5, 5, 10 x 10^n).
double _niceCeil(double v) {
  if (v <= 0) return 1;
  final mag = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
  final n = v / mag;
  final step = n <= 1 ? 1 : n <= 2 ? 2 : n <= 2.5 ? 2.5 : n <= 5 ? 5 : 10;
  return step * mag;
}

/// Draws horizontal gridlines with y-axis value labels behind bar charts.
class _ChartGridPainter extends CustomPainter {
  _ChartGridPainter({
    required this.maxValue,
    required this.labelBuilder,
    required this.lineColor,
    required this.textColor,
    required this.bottomInset,
    required this.topInset,
  });

  static const double gutter = 40;

  final double maxValue;
  final String Function(double) labelBuilder;
  final Color lineColor;
  final Color textColor;
  final double bottomInset;
  final double topInset;

  @override
  void paint(Canvas canvas, Size size) {
    final plotH = size.height - bottomInset - topInset;
    if (plotH <= 0) return;
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    const steps = 4;
    for (var i = 0; i <= steps; i++) {
      final f = i / steps;
      final y = size.height - bottomInset - plotH * f;
      canvas.drawLine(Offset(gutter - 4, y), Offset(size.width, y), paint);
      final tp = TextPainter(
        text: TextSpan(
          text: labelBuilder(maxValue * f),
          style: TextStyle(
            color: textColor,
            fontSize: 9,
            fontFamily: 'RedditMono',
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: gutter - 6);
      tp.paint(canvas, Offset(gutter - 6 - tp.width, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_ChartGridPainter old) =>
      old.maxValue != maxValue ||
      old.lineColor != lineColor ||
      old.textColor != textColor;
}

class _CurrentWeekDayColumn extends StatelessWidget {
  const _CurrentWeekDayColumn({
    required this.day,
    required this.currency,
    required this.maxMinutes,
  });

  final AnalyticsWorkDay day;
  final String currency;
  final int maxMinutes;

  @override
  Widget build(BuildContext context) {
    final tr = context.strings;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final colors = context.colors;
    final isToday = AppDate.isSameDay(day.date, DateTime.now());
    final hasWork = day.minutes > 0;
    final hours = day.minutes / 60.0;
    final hoursStr =
        hasWork
            ? '${tr.localizeDigits(hours.toStringAsFixed(hours.truncateToDouble() == hours ? 0 : 1))}h'
            : '—';

    final effectiveMax = maxMinutes <= 0 ? 60 : maxMinutes;
    final ratio = (day.minutes / effectiveMax).clamp(0.08, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm, horizontal: 2),
      decoration: BoxDecoration(
        color:
            isToday
                ? scheme.primary.withValues(alpha: 0.08)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border:
            isToday
                ? Border.all(color: scheme.primary.withValues(alpha: 0.4))
                : null,
      ),
      child: Column(
        children: [
          Text(
            AppDate.weekday(day.date).substring(0, 3),
            style: text.labelSmall?.copyWith(
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
              color: isToday ? scheme.primary : scheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            tr.formatNumber(day.date.day),
            style: text.labelSmall?.copyWith(
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              fontSize: 10,
              color: isToday ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          // Vertical bar
          Container(
            height: 48,
            width: 14,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 48 * ratio,
              width: 14,
              decoration: BoxDecoration(
                color: hasWork ? colors.brand : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hoursStr,
            style: text.labelSmall?.copyWith(
              fontFamily: 'RedditMono',
              fontWeight: hasWork ? FontWeight.w700 : FontWeight.w500,
              fontSize: 9.5,
              color: hasWork ? scheme.onSurface : scheme.outlineVariant,
            ),
          ),
          if (day.earningsMinor > 0) ...[
            const SizedBox(height: 1),
            Text(
              MoneyFormatter.compact(day.earningsMinor, currency),
              style: text.labelSmall?.copyWith(
                fontFamily: 'RedditMono',
                fontWeight: FontWeight.w700,
                fontSize: 8.5,
                color: colors.income,
              ),
              maxLines: 1,
              overflow: TextOverflow.visible,
            ),
          ],
        ],
      ),
    );
  }
}

