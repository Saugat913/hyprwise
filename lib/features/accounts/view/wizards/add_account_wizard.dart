import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/accounts/data/model/account_type.dart';
import 'package:finance_tracker/features/accounts/viewmodels/accounts_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class AddAccountWizard extends StatefulWidget {
  const AddAccountWizard({super.key});

  @override
  State<AddAccountWizard> createState() => _AddAccountWizardState();
}

class _AddAccountWizardState extends State<AddAccountWizard> {
  int _step = 0;
  AccountType _selectedType = AccountType.bank;
  late final TextEditingController _nameController;
  final _balanceController = TextEditingController(text: '0.00');
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  String _defaultNameFor(AccountType type, AppStrings tr) => type.localizedLabel(tr);

  void _onNext() {
    final tr = context.strings;
    if (_step == 0) {
      setState(() {
        _nameController.text = _defaultNameFor(_selectedType, tr);
        _step = 1;
      });
    } else {
      _save();
    }
  }

  Future<void> _save() async {
    final tr = context.strings;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = tr.pleaseEnterAccountName);
      showErrorToast(context, tr.pleaseEnterAccountName);
      return;
    }

    final viewModel = getIt<AccountsViewModel>();
    final balanceDouble = double.tryParse(_balanceController.text.trim()) ?? 0.0;
    final balanceMinor = (balanceDouble * 100).round();

    final id = await viewModel.addAccount(
      name: name,
      type: _selectedType,
      openingBalanceMinor: balanceMinor,
    );

    if (mounted) {
      showToast(
        context,
        tr.accountAdded,
        actionLabel: tr.undo,
        onAction: () async {
          await viewModel.deleteAccount(id);
        },
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = getIt<AccountsViewModel>().baseCurrency;
    final tr = context.strings;

    return switch (_step) {
      0 => WizardScaffold(
          step: 0,
          steps: 2,
          title: tr.whatKindOfAccount,
          subtitle: tr.startWithMostUsed,
          confirmClose: true,
          discardTitle: tr.discardThis,
          primaryLabel: tr.next,
          onPrimary: _onNext,
          onClose: () => context.pop(),
          child: HorizontalOptionSelector<AccountType>(
            height: 64,
            selectedValue: _selectedType,
            onChanged: (type) => setState(() => _selectedType = type),
            items: [
              HorizontalOptionItem(
                value: AccountType.cash,
                label: tr.cash,
                subtitle: tr.moneyInYourPocket,
                icon: HugeIcons.strokeRoundedCoins01,
              ),
              HorizontalOptionItem(
                value: AccountType.bank,
                label: tr.everydayAccount,
                subtitle: tr.everydaySpending,
                icon: HugeIcons.strokeRoundedBank,
              ),
              HorizontalOptionItem(
                value: AccountType.wallet,
                label: tr.digitalWallet,
                subtitle: tr.appsAndCards,
                icon: HugeIcons.strokeRoundedWallet01,
              ),
              HorizontalOptionItem(
                value: AccountType.savings,
                label: tr.savingsAccount,
                subtitle: tr.moneySetAside,
                icon: HugeIcons.strokeRoundedPiggyBank,
              ),
            ],
          ),
        ),
      _ => WizardScaffold(
          step: 1,
          steps: 2,
          title: tr.whatIsBalanceNow,
          subtitle: tr.roughlyIsFine,
          onBack: () => setState(() => _step = 0),
          onClose: () => context.pop(),
          confirmClose: true,
          discardTitle: tr.discardThis,
          primaryLabel: tr.saveAccount,
          onPrimary: _nameController.text.trim().isEmpty ? null : _save,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UnderlineField(
                label: tr.accountName,
                hint: _defaultNameFor(_selectedType, tr),
                controller: _nameController,
                autofocus: true,
                isRequired: true,
                errorText: _nameError,
                onChanged: (val) {
                  if (_nameError != null) setState(() => _nameError = null);
                  setState(() {});
                },
              ),
              const SizedBox(height: AppSpace.xl),
              UnderlineField(
                label: tr.openingBalance,
                hint: '$currency 0.00',
                controller: _balanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
    };
  }
}
