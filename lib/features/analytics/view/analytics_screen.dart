import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/export/analytics_pdf_service.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/analytics/data/insights_engine.dart';
import 'package:finance_tracker/features/analytics/view/analytics_tabs.dart';
import 'package:finance_tracker/features/analytics/viewmodels/analytics_view_model.dart';
import 'package:finance_tracker/features/debts/data/model/debt.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/shared/data/categories.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 6, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<AnalyticsViewModel>();

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final text = Theme.of(context).textTheme;
        final scheme = Theme.of(context).colorScheme;
        final dualChartData = viewModel.dualChartData;
        final topMerchants = viewModel.topMerchants;
        final categories = viewModel.availableCategories;

        final isFiltered =
            viewModel.selectedCategory != null ||
            viewModel.selectedAccountId != null ||
            viewModel.dateFilter == AnalyticsDateFilter.custom;

        final isExpense = viewModel.activeType == TransactionType.expense;
        final colors = context.colors;
        final tr = context.strings;

        return Scaffold(
          appBar: AppBar(
            title: Text(tr.analytics),
            bottom: TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: scheme.onSurface,
              unselectedLabelColor: scheme.onSurfaceVariant,
              indicatorColor: colors.brand,
              dividerColor: scheme.outlineVariant,
              tabs: [
                Tab(text: tr.analyticsTabOverview),
                Tab(text: tr.income),
                Tab(text: tr.analyticsTabExpenses),
                Tab(text: tr.analyticsTabLend),
                Tab(text: tr.analyticsTabBorrow),
                Tab(text: tr.analyticsTabShiftsWork),
              ],
            ),
            actions: [
              if (isFiltered)
                IconButton(
                  tooltip: tr.resetFilters,
                  icon: const AppIcon(
                    HugeIcons.strokeRoundedFilterRemove,
                    size: 20,
                  ),
                  onPressed: viewModel.clearFilters,
                ),
              Padding(
                padding: const EdgeInsets.only(right: AppSpace.page),
                child: Center(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.onSurface,
                      foregroundColor: scheme.surface,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
                      minimumSize: const Size(0, 32),
                      shape: const StadiumBorder(),
                    ),
                    icon: AppIcon(
                      HugeIcons.strokeRoundedFileExport,
                      size: 14,
                      color: scheme.surface,
                    ),
                    label: Text(
                      tr.t(
                        'Export',
                        ne: 'निर्यात',
                        es: 'Exportar',
                        fr: 'Exporter',
                        de: 'Export',
                        ja: 'エクスポート',
                        zh: '导出',
                        it: 'Esporta',
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: scheme.surface,
                        fontSize: 12,
                      ),
                    ),
                    onPressed:
                        () => AnalyticsPdfService.showPdfExportSheet(
                          context,
                          viewModel,
                        ),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.page,
                    AppSpace.sm,
                    AppSpace.page,
                    AppSpace.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _DateRangeFilterButton(viewModel: viewModel),
                      ),
                      // Category filter only applies to the Overview tab.
                      ListenableBuilder(
                        listenable: _tabs,
                        builder:
                            (context, _) =>
                                _tabs.index == 0
                                    ? Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          left: AppSpace.sm,
                                        ),
                                        child: _CategoryFilterButton(
                                          viewModel: viewModel,
                                          categories: categories,
                                        ),
                                      ),
                                    )
                                    : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpace.page,
                          AppSpace.sm,
                          AppSpace.page,
                          AppSpace.xxl,
                        ),
                        children: [
                          if (!viewModel.hasData)
                            EmptyState(
                              icon: HugeIcons.strokeRoundedChartHistogram,
                              title: tr.noDataForThisFilter,
                              message:
                                  isFiltered
                                      ? tr.noDataFilterAdvice
                                      : (isExpense
                                          ? tr.addExpensesForSpendingAdvice
                                          : tr.addIncomeForEarningsAdvice),
                              actionLabel:
                                  isFiltered
                                      ? tr.resetFilters
                                      : tr.addTransaction,
                              onAction:
                                  isFiltered
                                      ? viewModel.clearFilters
                                      : () => context.push(
                                        AppRoutes.addTransaction,
                                      ),
                            )
                          else ...[
                            // Cash flow overview & daily dual bar chart (Income + Expense per day)
                            AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        viewModel.selectedCategory != null
                                            ? (isExpense
                                                ? tr.categorySpendingLabel(
                                                  TransactionCategories.fromValue(
                                                    viewModel.selectedCategory!,
                                                    viewModel.activeType,
                                                  ).label,
                                                )
                                                : tr.categoryIncomeLabel(
                                                  TransactionCategories.fromValue(
                                                    viewModel.selectedCategory!,
                                                    viewModel.activeType,
                                                  ).label,
                                                ))
                                            : tr.analyticsTabOverview,
                                        style: text.bodyMedium?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (viewModel.selectedCategory != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: scheme.primary.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              AppRadius.pill,
                                            ),
                                          ),
                                          child: Text(
                                            tr.filteredLabel,
                                            style: text.labelSmall?.copyWith(
                                              color: scheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpace.sm),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        MoneyFormatter.format(
                                          viewModel.netMinor,
                                          viewModel.baseCurrency,
                                          signed: true,
                                        ),
                                        style: text.displaySmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: viewModel.netMinor >= 0
                                              ? colors.income
                                              : colors.expense,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpace.xs),
                                      Text(
                                        tr.netSavings,
                                        style: text.labelMedium?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpace.xs),
                                  Text(
                                    tr.transactionsRecordedCount(
                                      viewModel.filteredTransactions.length,
                                    ),
                                    style: text.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (dualChartData.labels.isNotEmpty) ...[
                                    const SizedBox(height: AppSpace.lg),
                                    _DualBarChart(
                                      incomeValues: dualChartData.incomeValues,
                                      expenseValues: dualChartData.expenseValues,
                                      labels: dualChartData.labels,
                                      currency: viewModel.baseCurrency,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpace.lg),

                            // Companion comparison card (Income vs Expense + Net)
                            AppCard(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tr.income,
                                          style: text.bodySmall?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          MoneyFormatter.format(
                                            viewModel.incomeMinor,
                                            viewModel.baseCurrency,
                                          ),
                                          style: text.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: colors.income,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tr.expense,
                                          style: text.bodySmall?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          MoneyFormatter.format(
                                            viewModel.expenseMinor,
                                            viewModel.baseCurrency,
                                          ),
                                          style: text.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: colors.expense,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tr.netSavings,
                                          style: text.bodySmall?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        MoneyText(
                                          viewModel.netMinor,
                                          viewModel.baseCurrency,
                                          signed: true,
                                          style: text.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Category breakdown (when 'All' is selected)
                            if (viewModel.selectedCategory == null &&
                                viewModel.categoryBreakdown.isNotEmpty) ...[
                              const SizedBox(height: AppSpace.xxl),
                              SectionHeader(
                                isExpense ? tr.whereItWent : tr.incomeSources,
                              ),
                              AppCard(
                                padding: EdgeInsets.zero,
                                child: Column(
                                  children: [
                                    for (
                                      var i = 0;
                                      i < viewModel.categoryBreakdown.length;
                                      i++
                                    ) ...[
                                      if (i > 0) const RowDivider(),
                                      InkWell(
                                        onTap:
                                            () => viewModel.selectCategory(
                                              viewModel
                                                  .categoryBreakdown[i]
                                                  .categoryKey,
                                            ),
                                        child: _CategorySpendRow(
                                          spend: viewModel.categoryBreakdown[i],
                                          totalMinor:
                                              viewModel.activeTotalMinor,
                                          currency: viewModel.baseCurrency,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],

                            // Top merchants / payers section
                            if (topMerchants.isNotEmpty) ...[
                              const SizedBox(height: AppSpace.xxl),
                              SectionHeader(
                                viewModel.selectedCategory != null
                                    ? tr.topSourcesForCategory
                                    : (isExpense
                                        ? tr.topMerchants
                                        : tr.topIncomeSources),
                              ),
                              AppCard(
                                padding: EdgeInsets.zero,
                                child: Column(
                                  children: [
                                    for (
                                      var i = 0;
                                      i < topMerchants.take(5).length;
                                      i++
                                    ) ...[
                                      if (i > 0) const RowDivider(),
                                      _MerchantRow(
                                        merchant: topMerchants[i],
                                        currency: viewModel.baseCurrency,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],

                            // Projected month-end card
                            const SizedBox(height: AppSpace.xl),
                            AppCard(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tr.projectedMonthEndText(
                                            MoneyFormatter.format(
                                              viewModel.projectedMonthEndMinor,
                                              viewModel.baseCurrency,
                                            ),
                                          ),
                                          style: text.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          tr.basedOnShiftsAndRecurring,
                                          style: text.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  StatusChip(
                                    tr.onTrack,
                                    tone: ChipTone.success,
                                  ),
                                ],
                              ),
                            ),

                            // Lending & Borrowing (IOUs) Analytics
                            if (viewModel.activeDebts.isNotEmpty ||
                                viewModel.debts.isNotEmpty) ...[
                              const SizedBox(height: AppSpace.xxl),
                              SectionHeader(
                                context.strings.lendingBorrowingIous,
                                actionLabel: context.strings.manage,
                                onAction: () => context.push(AppRoutes.debts),
                              ),
                              AppCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          context.strings.netDebtPositionHeader,
                                          style: text.labelSmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: scheme.onSurfaceVariant,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                        StatusChip(
                                          viewModel.netDebtMinor >= 0
                                              ? context.strings.netReceivable
                                              : context.strings.netPayable,
                                          tone:
                                              viewModel.netDebtMinor >= 0
                                                  ? ChipTone.success
                                                  : ChipTone.danger,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpace.sm),
                                    Text(
                                      '${viewModel.netDebtMinor >= 0 ? '+' : '−'}${MoneyFormatter.format(viewModel.netDebtMinor.abs(), viewModel.baseCurrency)}',
                                      style: text.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color:
                                            viewModel.netDebtMinor >= 0
                                                ? colors.income
                                                : colors.expense,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpace.md),
                                    const RowDivider(),
                                    const SizedBox(height: AppSpace.md),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  AppIcon(
                                                    HugeIcons
                                                        .strokeRoundedArrowUpRight01,
                                                    size: 14,
                                                    color: colors.income,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      context
                                                          .strings
                                                          .lentToOthers,
                                                      style: text.bodySmall
                                                          ?.copyWith(
                                                            color:
                                                                scheme
                                                                    .onSurfaceVariant,
                                                          ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                MoneyFormatter.format(
                                                  viewModel.totalLentMinor,
                                                  viewModel.baseCurrency,
                                                ),
                                                style: text.titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: colors.income,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 1,
                                          height: 28,
                                          color: scheme.outlineVariant,
                                        ),
                                        const SizedBox(width: AppSpace.md),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  AppIcon(
                                                    HugeIcons
                                                        .strokeRoundedArrowDownLeft01,
                                                    size: 14,
                                                    color: colors.expense,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      context
                                                          .strings
                                                          .borrowedFromOthers,
                                                      style: text.bodySmall
                                                          ?.copyWith(
                                                            color:
                                                                scheme
                                                                    .onSurfaceVariant,
                                                          ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                MoneyFormatter.format(
                                                  viewModel.totalBorrowedMinor,
                                                  viewModel.baseCurrency,
                                                ),
                                                style: text.titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: colors.expense,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (viewModel.topDebtParties.isNotEmpty) ...[
                                const SizedBox(height: AppSpace.md),
                                AppCard(
                                  padding: EdgeInsets.zero,
                                  child: Column(
                                    children: [
                                      for (
                                        var i = 0;
                                        i <
                                            viewModel.topDebtParties
                                                .take(4)
                                                .length;
                                        i++
                                      ) ...[
                                        if (i > 0) const RowDivider(),
                                        _DebtPartyRow(
                                          party: viewModel.topDebtParties[i],
                                          currency: viewModel.baseCurrency,
                                          onTap:
                                              () =>
                                                  context.push(AppRoutes.debts),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ],
                      ),
                      AnalyticsTransactionsTab(
                        viewModel: viewModel,
                        type: TransactionType.income,
                      ),
                      AnalyticsTransactionsTab(
                        viewModel: viewModel,
                        type: TransactionType.expense,
                      ),
                      AnalyticsDebtTab(
                        viewModel: viewModel,
                        type: DebtType.lent,
                      ),
                      AnalyticsDebtTab(
                        viewModel: viewModel,
                        type: DebtType.borrowed,
                      ),
                      AnalyticsWorkTab(viewModel: viewModel),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DateRangeFilterButton extends StatelessWidget {
  const _DateRangeFilterButton({required this.viewModel});

  final AnalyticsViewModel viewModel;

  String get _currentLabel {
    if (viewModel.dateFilter == AnalyticsDateFilter.custom &&
        viewModel.customRange != null) {
      return '${AppDate.short(viewModel.customRange!.start)}–${AppDate.short(viewModel.customRange!.end)}';
    }
    return viewModel.dateFilter.label;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCustom = viewModel.dateFilter != AnalyticsDateFilter.thisMonth;

    return PopupMenuButton<AnalyticsDateFilter>(
      initialValue: viewModel.dateFilter,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      onSelected: (df) async {
        if (df == AnalyticsDateFilter.custom) {
          final range = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            initialDateRange:
                viewModel.customRange ??
                DateTimeRange(
                  start: DateTime.now().subtract(const Duration(days: 30)),
                  end: DateTime.now(),
                ),
          );
          if (range != null) {
            viewModel.setDateFilter(df, customRange: range);
          }
        } else {
          viewModel.setDateFilter(df);
        }
      },
      itemBuilder:
          (ctx) => [
            for (final df in AnalyticsDateFilter.values)
              PopupMenuItem(
                value: df,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        df.label,
                        style: TextStyle(
                          fontWeight:
                              viewModel.dateFilter == df
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (viewModel.dateFilter == df)
                      Icon(
                        Icons.check,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                  ],
                ),
              ),
          ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color:
              isCustom
                  ? theme.colorScheme.primary.withValues(alpha: 0.08)
                  : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color:
                isCustom
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color:
                  isCustom
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(
                _currentLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color:
                      isCustom
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color:
                  isCustom
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilterButton extends StatelessWidget {
  const _CategoryFilterButton({
    required this.viewModel,
    required this.categories,
  });

  final AnalyticsViewModel viewModel;
  final List<String> categories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = context.strings;
    final hasCategory = viewModel.selectedCategory != null;
    final label =
        hasCategory
            ? TransactionCategories.fromValue(
              viewModel.selectedCategory!,
              TransactionType.expense,
            ).label
            : tr.allCategoriesTitle;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () => _showCategorySheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color:
              hasCategory
                  ? theme.colorScheme.primary.withValues(alpha: 0.08)
                  : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color:
                hasCategory
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.filter_list,
              size: 16,
              color:
                  hasCategory
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color:
                      hasCategory
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color:
                  hasCategory
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  void _showCategorySheet(BuildContext context) {
    final theme = Theme.of(context);
    final tr = context.strings;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpace.lg,
              left: AppSpace.page,
              right: AppSpace.page,
              top: AppSpace.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr.filterByCategoryTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (viewModel.selectedCategory != null)
                      TextButton(
                        onPressed: () {
                          viewModel.selectCategory(null);
                          Navigator.pop(ctx);
                        },
                        child: Text(tr.clearAction),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: AppSpace.sm,
                    mainAxisSpacing: AppSpace.sm,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: categories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = viewModel.selectedCategory == null;
                      return _AnalyticsCategoryGridCard(
                        label: tr.allCategoriesTitle,
                        icon: HugeIcons.strokeRoundedGridView,
                        color: theme.colorScheme.primary,
                        isSelected: isSelected,
                        onTap: () {
                          viewModel.selectCategory(null);
                          Navigator.pop(ctx);
                        },
                      );
                    }
                    final cat = categories[index - 1];
                    final catObj = TransactionCategories.fromValue(
                      cat,
                      viewModel.activeType,
                    );
                    final isSelected = viewModel.selectedCategory == cat;
                    return _AnalyticsCategoryGridCard(
                      label: catObj.label,
                      icon: _categoryGlyph(cat, viewModel.activeType),
                      color: _categoryColor(cat, context, viewModel.activeType),
                      isSelected: isSelected,
                      onTap: () {
                        viewModel.selectCategory(cat);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

IconGlyph _categoryGlyph(String key, TransactionType type) {
  switch (key) {
    case 'groceries':
      return HugeIcons.strokeRoundedShoppingBag01;
    case 'eating_out':
      return HugeIcons.strokeRoundedRestaurant01;
    case 'entertainment':
      return HugeIcons.strokeRoundedPlay;
    case 'transport':
      return HugeIcons.strokeRoundedCar01;
    case 'bills':
      return HugeIcons.strokeRoundedReceipt;
    case 'salary':
      return HugeIcons.strokeRoundedCoins01;
    case 'shift_pay':
      return HugeIcons.strokeRoundedClock01;
    case 'business':
      return HugeIcons.strokeRoundedBriefcase01;
    case 'interest':
      return HugeIcons.strokeRoundedChartHistogram;
    case 'gift_received':
      return HugeIcons.strokeRoundedWallet01;
    default:
      return type == TransactionType.income
          ? HugeIcons.strokeRoundedMoneyReceive02
          : HugeIcons.strokeRoundedMoneySend02;
  }
}

Color _categoryColor(String key, BuildContext context, TransactionType type) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  switch (key) {
    case 'groceries':
      return isDark ? const Color(0xFF225B40) : const Color(0xFF164A33);
    case 'eating_out':
      return isDark ? const Color(0xFF7A3E16) : const Color(0xFF5A2D0C);
    case 'entertainment':
      return isDark ? const Color(0xFF563077) : const Color(0xFF3E1F58);
    case 'transport':
      return isDark ? const Color(0xFF1E3A8A) : const Color(0xFF1E40AF);
    case 'bills':
      return isDark ? const Color(0xFF831843) : const Color(0xFF9D174D);
    case 'salary':
      return const Color(0xFF1F7A45);
    case 'shift_pay':
      return const Color(0xFF0D9488);
    case 'business':
      return const Color(0xFF4338CA);
    default:
      return type == TransactionType.income
          ? const Color(0xFF1F7A45)
          : Theme.of(context).colorScheme.primary;
  }
}

class _AnalyticsCategoryGridCard extends StatelessWidget {
  const _AnalyticsCategoryGridCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final dynamic icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected ? color : scheme.outlineVariant.withValues(alpha: 0.7),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.xs,
            vertical: AppSpace.sm,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: icon is IconGlyph
                      ? AppIcon(
                          icon,
                          size: 16,
                          color: isSelected ? Colors.white : color,
                        )
                      : Icon(
                          icon as IconData,
                          size: 16,
                          color: isSelected ? Colors.white : color,
                        ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: text.labelSmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? color : scheme.onSurface,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DualBarChart extends StatelessWidget {
  const _DualBarChart({
    required this.incomeValues,
    required this.expenseValues,
    required this.labels,
    required this.currency,
  });

  final List<double> incomeValues;
  final List<double> expenseValues;
  final List<String> labels;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;
    final tr = context.strings;

    final maxIncome =
        incomeValues.isEmpty ? 0.0 : incomeValues.reduce(math.max);
    final maxExpense =
        expenseValues.isEmpty ? 0.0 : expenseValues.reduce(math.max);
    final globalMax = math.max(maxIncome, maxExpense);
    final effectiveMax = globalMax <= 0 ? 1.0 : globalMax;

    // Adaptive bar width based on count of day columns
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = labels.length;
        if (count == 0) return const SizedBox.shrink();

        // A comfortable day column needs at least 26px (two 7px bars + gap + margins)
        const minColWidth = 26.0;
        final availableWidth = constraints.maxWidth;
        final fitWidth = availableWidth / count;
        final needsScroll = fitWidth < minColWidth;

        final barWidth = needsScroll ? 7.0 : (fitWidth > 40 ? 9.0 : 7.0);
        final barSpacing = needsScroll ? 2.5 : 3.0;

        Widget buildDayColumnContent(int i) {
          final income = i < incomeValues.length ? incomeValues[i] : 0.0;
          final expense = i < expenseValues.length ? expenseValues[i] : 0.0;
          final label = labels[i];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Income Bar (Green)
                        _DayBarItem(
                          value: income,
                          effectiveMax: effectiveMax,
                          color: colors.income,
                          width: barWidth,
                          tooltip:
                              '$label · ${tr.income}: ${MoneyFormatter.format(income.round(), currency)}',
                        ),
                        SizedBox(width: barSpacing),
                        // Expense Bar (Red)
                        _DayBarItem(
                          value: expense,
                          effectiveMax: effectiveMax,
                          color: colors.expense,
                          width: barWidth,
                          tooltip:
                              '$label · ${tr.expense}: ${MoneyFormatter.format(expense.round(), currency)}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: text.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 10,
                    fontFamily: 'RedditMono',
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }

        final columnsRow = Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < count; i++)
              if (needsScroll)
                SizedBox(
                  width: minColWidth,
                  child: buildDayColumnContent(i),
                )
              else
                Expanded(
                  child: buildDayColumnContent(i),
                ),
          ],
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ChartLegendBadge(
                  color: colors.income,
                  label: tr.income,
                ),
                const SizedBox(width: AppSpace.md),
                _ChartLegendBadge(
                  color: colors.expense,
                  label: tr.expense,
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            SizedBox(
              height: 124,
              child: needsScroll
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      child: columnsRow,
                    )
                  : columnsRow,
            ),
          ],
        );
      },
    );
  }
}

class _ChartLegendBadge extends StatelessWidget {
  const _ChartLegendBadge({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: text.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _DayBarItem extends StatelessWidget {
  const _DayBarItem({
    required this.value,
    required this.effectiveMax,
    required this.color,
    required this.width,
    required this.tooltip,
  });

  final double value;
  final double effectiveMax;
  final Color color;
  final double width;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const barHeight = 82.0;
    final factor =
        value > 0 ? (value / effectiveMax).clamp(0.08, 1.0) : 0.0;

    return Tooltip(
      message: tooltip,
      child: Container(
        width: width,
        height: barHeight,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        alignment: Alignment.bottomCenter,
        child:
            factor > 0
                ? FractionallySizedBox(
                  heightFactor: factor,
                  child: Container(
                    width: width,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                )
                : const SizedBox.shrink(),
      ),
    );
  }
}

class _CategorySpendRow extends StatelessWidget {
  const _CategorySpendRow({
    required this.spend,
    required this.totalMinor,
    required this.currency,
  });

  final CategorySpend spend;
  final int totalMinor;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final percent =
        totalMinor > 0 ? (spend.amountMinor / totalMinor * 100).round() : 0;

    return Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  spend.label,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text('${context.strings.formatNumber(percent)}%', style: text.bodySmall),
              const SizedBox(width: AppSpace.md),
              MoneyText(
                spend.amountMinor,
                currency,
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: AppSpace.xs),
              const Icon(Icons.chevron_right, size: 16),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          ProgressLine(totalMinor > 0 ? spend.amountMinor / totalMinor : 0),
        ],
      ),
    );
  }
}

class _MerchantRow extends StatelessWidget {
  const _MerchantRow({required this.merchant, required this.currency});

  final AnalyticsMerchantSpend merchant;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Row(
        children: [
          LetterAvatar(merchant.name),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  merchant.name,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${TransactionCategories.fromValue(merchant.category, TransactionType.expense).label} · ${context.strings.txCountShort(merchant.count)}',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          MoneyText(
            merchant.amountMinor,
            currency,
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _DebtPartyRow extends StatelessWidget {
  const _DebtPartyRow({
    required this.party,
    required this.currency,
    required this.onTap,
  });

  final AnalyticsDebtParty party;
  final String currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    final tr = context.strings;
    final isPositive = party.netMinor >= 0;

    return ListRow(
      leading: LetterAvatar(party.name, size: 36),
      title: party.name,
      subtitle: isPositive ? tr.owesYou : tr.youOweThem,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${isPositive ? '+' : '−'}${MoneyFormatter.format(party.netMinor.abs(), currency)}',
            style: text.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: isPositive ? colors.income : colors.expense,
            ),
          ),
          const SizedBox(width: AppSpace.xs),
          const Chevron(),
        ],
      ),
      onTap: onTap,
    );
  }
}
