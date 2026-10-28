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
        AppCard(child: AnimatedBarChart(trend: data.trend)),
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
        AppCard(child: AnimatedBarChart(trend: data.trend)),
        SectionHeader(tr.analyticsByPerson),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < data.parties.length; i++) ...[
                if (i > 0) const RowDivider(),
                _ShareRow(
                  label: data.parties[i].name,
                  amountMinor: data.parties[i].amountMinor,
                  totalMinor: data.totalMinor,
                  currency: currency,
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
    final weekLabels = [for (final w in data.weeks) tr.formatNumber(w.start.day)];

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
                  const Expanded(child: SizedBox()),
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
              AnimatedBarChart(trend: AnalyticsTrend(weekValues, weekLabels)),
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
  });

  final String label;
  final int amountMinor;
  final int totalMinor;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final share = totalMinor > 0 ? amountMinor / totalMinor : 0.0;
    return Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text('${context.strings.formatNumber((share * 100).round())}%', style: text.bodySmall),
              const SizedBox(width: AppSpace.md),
              MoneyText(
                amountMinor,
                currency,
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          _AnimatedProgress(share, color: context.colors.brand),
        ],
      ),
    );
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
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? scheme.onSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
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
class AnimatedBarChart extends StatelessWidget {
  const AnimatedBarChart({super.key, required this.trend, this.height = 120});

  final AnalyticsTrend trend;
  final double height;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final values = trend.values;
    final peak = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    final effectiveMax = peak <= 0 ? 1.0 : peak;
    final brand = context.colors.brand;
    // Skip some labels on dense charts so none are truncated.
    final labelEvery = values.length > 16 ? 4 : (values.length > 8 ? 2 : 1);

    return TweenAnimationBuilder<double>(
      key: ValueKey(Object.hashAll(values)),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder:
          (context, t, _) => SizedBox(
            height: height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < values.length; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: values.length > 16 ? 1 : 3,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height: (values[i] /
                                        effectiveMax *
                                        (height - 40) *
                                        t)
                                    .clamp(4.0, height - 40),
                                decoration: BoxDecoration(
                                  color:
                                      values[i] > 0
                                          ? brand
                                          : scheme.outlineVariant.withValues(
                                            alpha: 0.3,
                                          ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.sm,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 14,
                            child:
                                i % labelEvery == 0 && i < trend.labels.length
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
    );
  }
}
