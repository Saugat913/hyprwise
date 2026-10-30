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
        final (chartValues, chartLabels) = viewModel.chartData;
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
                            // Active summary card (Spent or Income)
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
                                            : (isExpense
                                                ? tr.totalSpending
                                                : tr.totalIncome),
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
                                  Text(
                                    MoneyFormatter.format(
                                      viewModel.activeTotalMinor,
                                      viewModel.baseCurrency,
                                    ),
                                    style: text.displaySmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color:
                                          isExpense
                                              ? scheme.onSurface
                                              : colors.income,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpace.sm),
                                  Text(
                                    tr.transactionsRecordedCount(
                                      viewModel.filteredTransactions
                                          .where(
                                            (t) =>
                                                t.type ==
                                                viewModel.activeType.value,
                                          )
                                          .length,
                                    ),
                                    style: text.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (chartValues.isNotEmpty) ...[
                                    const SizedBox(height: AppSpace.xl),
                                    _SpendingBarChart(
                                      values: chartValues,
                                      labels: chartLabels,
                                      color:
                                          isExpense
                                              ? scheme.onSurface
                                              : colors.income,
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
                                          isExpense ? tr.income : tr.expense,
                                          style: text.bodySmall?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          MoneyFormatter.format(
                                            isExpense
                                                ? viewModel.incomeMinor
                                                : viewModel.expenseMinor,
                                            viewModel.baseCurrency,
                                          ),
                                          style: text.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
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

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        final tr = ctx.strings;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.lg,
                  vertical: AppSpace.md,
                ),
                child: Row(
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
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.apps_rounded),
                title: Text(tr.allCategoriesTitle),
                trailing:
                    viewModel.selectedCategory == null
                        ? Icon(Icons.check, color: theme.colorScheme.primary)
                        : null,
                onTap: () {
                  viewModel.selectCategory(null);
                  Navigator.pop(ctx);
                },
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final catObj = TransactionCategories.fromValue(
                      cat,
                      TransactionType.expense,
                    );
                    final isSelected = viewModel.selectedCategory == cat;

                    return ListTile(
                      title: Text(catObj.label),
                      trailing:
                          isSelected
                              ? Icon(
                                Icons.check,
                                color: theme.colorScheme.primary,
                              )
                              : null,
                      onTap: () {
                        viewModel.selectCategory(cat);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpace.md),
            ],
          ),
        );
      },
    );
  }
}

class _SpendingBarChart extends StatelessWidget {
  const _SpendingBarChart({
    required this.values,
    required this.labels,
    required this.color,
  });

  final List<double> values;
  final List<String> labels;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final max = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    final effectiveMax = max <= 0 ? 1.0 : max;

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: (values[i] / effectiveMax * 80).clamp(
                            4.0,
                            80.0,
                          ),
                          decoration: BoxDecoration(
                            color:
                                values[i] > 0
                                    ? color
                                    : scheme.outlineVariant.withValues(
                                      alpha: 0.3,
                                    ),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      i < labels.length ? labels[i] : '',
                      style: text.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
        ],
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
