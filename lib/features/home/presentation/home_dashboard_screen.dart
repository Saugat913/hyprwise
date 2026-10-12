import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/accounts/data/account_repository.dart';
import 'package:finance_tracker/features/transactions/data/transaction_repository.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_categories.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_type.dart';
import 'package:finance_tracker/features/transfers/data/transfer_repository.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<List<Account>>(
        stream: getIt<AccountRepository>().watchAccounts(),
        builder: (context, accountSnapshot) {
          if (accountSnapshot.hasError) {
            return const _MessageState(message: 'Could not load accounts.');
          }
          if (!accountSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return StreamBuilder<List<Transaction>>(
            stream: getIt<TransactionRepository>().watchTransactions(),
            builder: (context, transactionSnapshot) {
              if (transactionSnapshot.hasError) {
                return const _MessageState(message: 'Could not load transactions.');
              }
              if (!transactionSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return StreamBuilder<List<Transfer>>(
                stream: getIt<TransferRepository>().watchTransfers(),
                builder: (context, transferSnapshot) {
                  if (transferSnapshot.hasError) {
                    return const _MessageState(message: 'Could not load transfers.');
                  }
                  if (!transferSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return _DashboardContent(
                    accounts: accountSnapshot.data!,
                    transactions: transactionSnapshot.data!,
                    transfers: transferSnapshot.data!,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.accounts,
    required this.transactions,
    required this.transfers,
  });

  final List<Account> accounts;
  final List<Transaction> transactions;
  final List<Transfer> transfers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeAccounts = accounts.where((a) => !a.isArchived).toList();
    final accountById = {for (final account in accounts) account.id: account};
    final movement = <int, int>{};

    for (final transaction in transactions) {
      final isIncome = transaction.type == TransactionType.income.value;
      final delta = isIncome ? transaction.amountMinor : -transaction.amountMinor;
      movement.update(transaction.accountId, (value) => value + delta,
          ifAbsent: () => delta);
    }
    for (final transfer in transfers) {
      movement.update(transfer.sourceAccountId,
          (value) => value - transfer.amountMinor,
          ifAbsent: () => -transfer.amountMinor);
      movement.update(transfer.destinationAccountId,
          (value) => value + transfer.amountMinor,
          ifAbsent: () => transfer.amountMinor);
    }

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);
    final monthly = transactions.where((transaction) {
      final date = DateTime.fromMillisecondsSinceEpoch(transaction.occurredAt);
      return !date.isBefore(monthStart) && date.isBefore(nextMonth);
    }).toList();
    final currencies = <String>{
      ...activeAccounts.map((account) => account.currencyCode),
      ...monthly.map((transaction) =>
          accountById[transaction.accountId]?.currencyCode ?? 'NPR'),
    }.toList()..sort();
    final recent = [...transactions]
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth > AppDimensions.pageMaxWidth
            ? (constraints.maxWidth - AppDimensions.pageMaxWidth) / 2
            : AppDimensions.screenPadding;
        return ListView(
          padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your finances', style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text(_monthLabel(now),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          )),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'All transactions',
                  onPressed: () => context.push('/transactions'),
                  icon: const Icon(Icons.receipt_long_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Current balance'),
            const SizedBox(height: 12),
            if (activeAccounts.isEmpty)
              _EmptyCard(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Start with an account',
                message: 'Add cash, bank, or savings accounts to see your financial position.',
                actionLabel: 'Create account',
                onAction: () => context.go('/money'),
              )
            else
              ...currencies.where((currency) => activeAccounts
                  .any((account) => account.currencyCode == currency)).map((currency) {
                final currencyAccounts = activeAccounts
                    .where((account) => account.currencyCode == currency);
                final total = currencyAccounts.fold<int>(
                  0,
                  (sum, account) =>
                      sum + account.openingBalanceMinor + (movement[account.id] ?? 0),
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _BalanceCard(
                    currency: currency,
                    amountMinor: total,
                    accountCount: currencyAccounts.length,
                    onTap: () => context.go('/money'),
                  ),
                );
              }),
            const SizedBox(height: 20),
            const _SectionTitle(title: 'This month'),
            const SizedBox(height: 12),
            if (currencies.isEmpty)
              const _EmptyCard(
                icon: Icons.insights_outlined,
                title: 'Your monthly overview',
                message: 'Add a transaction to start understanding your cash flow.',
              )
            else
              ...currencies.map((currency) {
                final rows = monthly.where((transaction) =>
                    (accountById[transaction.accountId]?.currencyCode ?? 'NPR') == currency);
                final income = rows.where((t) => t.type == TransactionType.income.value)
                    .fold<int>(0, (sum, t) => sum + t.amountMinor);
                final expenses = rows.where((t) => t.type == TransactionType.expense.value)
                    .fold<int>(0, (sum, t) => sum + t.amountMinor);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MonthlyCard(currency: currency, income: income, expenses: expenses),
                );
              }),
            const SizedBox(height: 20),
            const _SectionTitle(title: 'Quick actions'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _QuickAction(
                  icon: Icons.add_rounded,
                  label: 'Add transaction',
                  onTap: () => context.push('/transactions'),
                )),
                const SizedBox(width: 10),
                Expanded(child: _QuickAction(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Transfer',
                  onTap: () => context.push('/transfers'),
                )),
                const SizedBox(width: 10),
                Expanded(child: _QuickAction(
                  icon: Icons.wallet_outlined,
                  label: 'Accounts',
                  onTap: () => context.go('/money'),
                )),
              ],
            ),
            const SizedBox(height: 28),
            _SectionTitle(
              title: 'Recent activity',
              trailing: recent.isEmpty ? null : 'See all',
              onTap: recent.isEmpty ? null : () => context.push('/transactions'),
            ),
            const SizedBox(height: 8),
            if (recent.isEmpty)
              const _EmptyCard(
                icon: Icons.receipt_long_outlined,
                title: 'Nothing recorded yet',
                message: 'Your income and expenses will appear here once you add them.',
              )
            else
              ...recent.take(5).map((transaction) {
                final isIncome = transaction.type == TransactionType.income.value;
                final category = TransactionCategories.fromValue(
                  transaction.category,
                  TransactionType.fromValue(transaction.type),
                );
                final account = accountById[transaction.accountId];
                final date = DateTime.fromMillisecondsSinceEpoch(transaction.occurredAt);
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 3),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: (isIncome ? Colors.green : theme.colorScheme.error)
                          .withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
                      color: isIncome ? Colors.green.shade700 : theme.colorScheme.error,
                    ),
                  ),
                  title: Text(category.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${account?.name ?? 'Account'} · ${date.day}/${date.month}/${date.year}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    '${isIncome ? '+' : '−'}${_money(transaction.amountMinor, account?.currencyCode ?? 'NPR')}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: isIncome ? Colors.green.shade700 : theme.colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  static String _money(int minor, String currency) {
    final amount = minor.abs();
    return '$currency ${amount ~/ 100}.${(amount % 100).toString().padLeft(2, '0')}';
  }

  static String _monthLabel(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.currency,
    required this.amountMinor,
    required this.accountCount,
    required this.onTap,
  });

  final String currency;
  final int amountMinor;
  final int accountCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.cardPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.account_balance_wallet_outlined,
                    color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(currency, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      _formatMoney(amountMinor, currency),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$accountCount account${accountCount == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMoney(int minor, String currency) {
    final amount = minor.abs();
    final formatted = '$currency ${amount ~/ 100}.${(amount % 100).toString().padLeft(2, '0')}';
    return minor < 0 ? '-$formatted' : formatted;
  }
}

class _MonthlyCard extends StatelessWidget {
  const _MonthlyCard({
    required this.currency,
    required this.income,
    required this.expenses,
  });

  final String currency;
  final int income;
  final int expenses;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(currency, style: theme.textTheme.titleSmall),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _FlowValue(
                label: 'Income',
                value: _formatMoney(income, currency),
                color: Colors.green.shade700,
              )),
              const SizedBox(width: 12),
              Expanded(child: _FlowValue(
                label: 'Expenses',
                value: _formatMoney(expenses, currency),
                color: theme.colorScheme.error,
              )),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: theme.colorScheme.outlineVariant),
          Row(
            children: [
              const Expanded(child: Text('Net cash flow')),
              Text(
                _formatMoney(income - expenses, currency),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: income >= expenses ? Colors.green.shade700 : theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatMoney(int minor, String currency) {
    final amount = minor.abs();
    final formatted = '$currency ${amount ~/ 100}.${(amount % 100).toString().padLeft(2, '0')}';
    return minor < 0 ? '-$formatted' : formatted;
  }
}

class _FlowValue extends StatelessWidget {
  const _FlowValue({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        )),
        const SizedBox(height: 5),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        )),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing, this.onTap});

  final String title;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
        if (trailing != null)
          TextButton(onPressed: onTap, child: Text(trailing!)),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          child: Column(
            children: [
              Icon(icon, size: 23),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center, style: theme.textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 26, color: theme.colorScheme.primary),
          const SizedBox(height: 10),
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 5),
          Text(message, style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          )),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
            ),
          ],
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}
