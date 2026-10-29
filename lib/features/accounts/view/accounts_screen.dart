import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/accounts/data/model/account_type.dart';
import 'package:finance_tracker/features/accounts/viewmodels/accounts_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';
import 'package:finance_tracker/features/transfers/presentation/transfers_screen.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<AccountsViewModel>();
    final tr = context.strings;

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final text = Theme.of(context).textTheme;
        final scheme = Theme.of(context).colorScheme;
        final colors = context.colors;
        final accounts = viewModel.accounts;

        return Scaffold(
          appBar: AppTopBar(
            title: tr.accounts,
            actions: [
              if (accounts.length >= 2)
                TopBarAction(
                  HugeIcons.strokeRoundedExchange01,
                  tooltip: tr.t(
                    'Transfer',
                    ne: 'रकम सार्नुहोस्',
                    es: 'Transferir',
                    fr: 'Transférer',
                    de: 'Überweisen',
                    ja: '振替',
                    zh: '转账',
                    it: 'Trasferisci',
                  ),
                  onPressed: () => showTransferFormModal(context),
                ),
              TopBarAction(
                HugeIcons.strokeRoundedPlusSign,
                tooltip: tr.addAccount,
                onPressed: () => context.push(AppRoutes.addAccount),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.page, vertical: AppSpace.md),
              children: [
                if (accounts.isEmpty)
                  SizedBox(
                    height: 400,
                    child: EmptyState(
                      icon: HugeIcons.strokeRoundedBank,
                      title: tr.noAccountsYet,
                      message: tr.addAccountNetPositionReal,
                      actionLabel: tr.addAccount,
                      onAction: () => context.push(AppRoutes.addAccount),
                    ),
                  )
                else ...[
                  // Hero total card
                  HeroCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr.totalAcrossAccounts,
                          style: text.bodyMedium?.copyWith(color: colors.onHeroSecondary),
                        ),
                        const SizedBox(height: AppSpace.md),
                        Text(
                          MoneyFormatter.format(viewModel.totalBalanceMinor, viewModel.baseCurrency),
                          style: text.displaySmall?.copyWith(
                            color: colors.onHero,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),

                  // Accounts list
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < accounts.length; i++) ...[
                          if (i > 0) const RowDivider(),
                          InkWell(
                            onTap: () => context.push(AppRoutes.account(accounts[i].id)),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpace.lg),
                              child: Row(
                                children: [
                                  IconTile(
                                    _iconForType(AccountType.fromValue(accounts[i].type)),
                                    size: 36,
                                  ),
                                  const SizedBox(width: AppSpace.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(tr.accountDisplayName(accounts[i].name), style: text.titleSmall),
                                        Text(
                                          '${AccountType.fromValue(accounts[i].type).localizedLabel(tr)} · ${accounts[i].currencyCode}',
                                          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                                  MoneyText(
                                    viewModel.balanceOf(accounts[i].id),
                                    accounts[i].currencyCode,
                                    style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(width: AppSpace.sm),
                                  const Chevron(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),

                  Center(
                    child: Text(
                      tr.netPositionTotalExplanation,
                      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  IconGlyph _iconForType(AccountType type) => switch (type) {
        AccountType.cash => HugeIcons.strokeRoundedCoins01,
        AccountType.bank => HugeIcons.strokeRoundedBank,
        AccountType.wallet => HugeIcons.strokeRoundedWallet01,
        AccountType.savings => HugeIcons.strokeRoundedPiggyBank,
      };
}
