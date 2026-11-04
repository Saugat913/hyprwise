import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/money/view/widgets/transaction_item_row.dart';
import 'package:finance_tracker/features/money/viewmodels/money_view_model.dart';
import 'package:finance_tracker/features/shared/data/categories.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class MoneyScreen extends StatefulWidget {
  const MoneyScreen({super.key});

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<MoneyViewModel>();

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final text = Theme.of(context).textTheme;
        final scheme = Theme.of(context).colorScheme;
        final tr = context.strings;
        final txs = viewModel.transactions;
        final categories = viewModel.availableCategories;
        final hasActiveFilter = viewModel.selectedCategory != null ||
            viewModel.selectedAccountId != null ||
            viewModel.searchQuery.isNotEmpty;

        return Scaffold(
          appBar: AppTopBar(
            title: tr.money,
            actions: [
              TopBarAction(
                HugeIcons.strokeRoundedAnalytics01,
                tooltip: tr.analytics,
                onPressed: () => context.push(AppRoutes.analytics),
              ),
              TopBarAction(
                HugeIcons.strokeRoundedPlusSign,
                tooltip: tr.addTransaction,
                onPressed: () => context.push(AppRoutes.addTransaction),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.page, vertical: AppSpace.md),
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: tr.searchTransactionsHint,
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              viewModel.setSearchQuery('');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: AppSpace.sm, horizontal: AppSpace.md),
                    filled: true,
                    fillColor: scheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: scheme.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: scheme.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: scheme.primary, width: 1.5),
                    ),
                  ),
                  onChanged: viewModel.setSearchQuery,
                ),
                const SizedBox(height: AppSpace.md),

                // Type Tabs
                SegmentedTabs<MoneyFilterTab>(
                  options: {
                    MoneyFilterTab.all: tr.allEvents,
                    MoneyFilterTab.income: tr.income,
                    MoneyFilterTab.expenses: tr.expenses,
                    MoneyFilterTab.lending: tr.lent,
                    MoneyFilterTab.borrowing: tr.borrowed,
                  },
                  value: viewModel.tab,
                  onChanged: viewModel.setTab,
                ),
                const SizedBox(height: AppSpace.md),

                // Category Filter Pills
                if (categories.isNotEmpty) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: tr.allCategoriesTitle,
                          isSelected: viewModel.selectedCategory == null,
                          onTap: () => viewModel.selectCategory(null),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        for (final cat in categories) ...[
                          _FilterChip(
                            label: TransactionCategories.fromValue(cat, TransactionType.expense).label,
                            isSelected: viewModel.selectedCategory == cat,
                            onTap: () => viewModel.selectCategory(cat),
                          ),
                          const SizedBox(width: AppSpace.sm),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),
                ],

                // Active Filter Indicator
                if (hasActiveFilter)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.sm),
                    child: Row(
                      children: [
                        Text(
                          tr.transactionsFoundCount(txs.length),
                          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            _searchController.clear();
                            viewModel.setSearchQuery('');
                            viewModel.selectCategory(null);
                            viewModel.selectAccount(null);
                          },
                          child: Text(
                            tr.clearFilters,
                            style: text.bodySmall?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),


                if (txs.isEmpty)
                  SizedBox(
                    height: 340,
                    child: EmptyState(
                      icon: HugeIcons.strokeRoundedCoins01,
                      title: hasActiveFilter ? tr.noMatchingTransactions : tr.noTransactionsYet,
                      message: hasActiveFilter
                          ? tr.tryAdjustingSearchOrFilters
                          : tr.tapAddToRecordFirstTransaction,
                      actionLabel: hasActiveFilter ? tr.clearFilters : tr.addTransaction,
                      onAction: hasActiveFilter
                          ? () {
                              _searchController.clear();
                              viewModel.setSearchQuery('');
                              viewModel.selectCategory(null);
                              viewModel.selectAccount(null);
                            }
                          : () => context.push(AppRoutes.addTransaction),
                    ),
                  )
                else ...[
                  for (final group in _groupTransactions(txs)) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppDate.weekdayDay(group.date),
                              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Builder(builder: (context) {
                            final net = group.transactions.fold<int>(
                              0,
                              (a, t) => a + (t.type == 'income' ? t.amountMinor : -t.amountMinor),
                            );
                            return Text(
                              '${net >= 0 ? '+' : '−'}${MoneyFormatter.format(net.abs(), viewModel.baseCurrency)}',
                              style: text.labelMedium?.copyWith(
                                fontFamily: 'RedditMono',
                                fontWeight: FontWeight.w600,
                                color: net >= 0 ? context.colors.income : context.colors.expense,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (var i = 0; i < group.transactions.length; i++) ...[
                            if (i > 0) const RowDivider(),
                            TransactionItemRow(
                              transaction: group.transactions[i],
                              currency: viewModel.baseCurrency,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.md),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  List<_DayGroup> _groupTransactions(List<Transaction> list) {
    final groups = <DateTime, List<Transaction>>{};
    for (final t in list) {
      final date = AppDate.dateOnly(DateTime.fromMillisecondsSinceEpoch(t.occurredAt));
      groups.putIfAbsent(date, () => []).add(t);
    }
    return groups.entries.map((e) => _DayGroup(date: e.key, transactions: e.value)).toList();
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? scheme.primary : scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? scheme.onPrimary : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _DayGroup {
  _DayGroup({required this.date, required this.transactions});
  final DateTime date;
  final List<Transaction> transactions;
}
