import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/money/viewmodels/money_view_model.dart';
import 'package:finance_tracker/features/shared/data/categories.dart';
import 'package:finance_tracker/features/shared/data/category_repository.dart';
import 'package:finance_tracker/features/shared/data/currency.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';
import 'package:finance_tracker/features/subscription/data/subscription_service.dart';
import 'package:finance_tracker/core/network/api_client.dart';

class AddTransactionWizard extends StatefulWidget {
  const AddTransactionWizard({
    super.key,
    this.initialType = TransactionType.expense,
  });

  final TransactionType initialType;

  @override
  State<AddTransactionWizard> createState() => _AddTransactionWizardState();
}

class _AddTransactionWizardState extends State<AddTransactionWizard> {
  int _step = 0;
  late TransactionType _type;
  final _amountController = TextEditingController();
  late String _categoryKey;
  String? _merchant;
  final _customMerchantController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();
  String? _conversionNote;

  bool _isSaving = false;
  int? _selectedAccountId;
  String? _amountError;
  String? _merchantError;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _categoryKey =
        _type == TransactionType.expense ? 'eating_out' : 'shift_pay';
    final newMerchants = TransactionCategories.merchantsFor(_categoryKey);
    _merchant = newMerchants.isNotEmpty ? newMerchants.first : null;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _customMerchantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onNext() {
    final tr = context.strings;
    if (_step == 0) {
      final amount = double.tryParse(_amountController.text) ?? 0;
      if (amount <= 0) {
        setState(() => _amountError = tr.enterValidAmount);
        showErrorToast(context, tr.enterValidAmount);
        return;
      }
      if (_type == TransactionType.expense) {
        final viewModel = getIt<MoneyViewModel>();
        if (viewModel.accounts.isNotEmpty) {
          final targetAccId = _selectedAccountId ?? viewModel.accounts.first.id;
          final currentBalance = viewModel.snapshot.balanceOf(targetAccId);
          final amountMinor = (amount * 100).round();
          if (currentBalance < amountMinor) {
            final accCurrency = viewModel.snapshot.currencyOf(targetAccId);
            final msg =
                '${tr.insufficientBalance}: ${MoneyFormatter.format(currentBalance, accCurrency)}.';
            setState(() => _amountError = tr.insufficientBalance);
            showErrorToast(context, msg);
            return;
          }
        }
      }
      setState(() {
        _amountError = null;
        _step = 1;
      });
    } else {
      _save();
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final tr = context.strings;
    final amountDouble = double.tryParse(_amountController.text) ?? 0;
    final amountMinor = (amountDouble * 100).round();
    if (amountMinor <= 0) {
      setState(() => _amountError = tr.enterValidAmount);
      showErrorToast(context, tr.enterValidAmount);
      return;
    }

    if (_merchant == 'Other' && _customMerchantController.text.trim().isEmpty) {
      setState(() => _merchantError = tr.enterMerchantName);
      showErrorToast(context, tr.enterMerchantName);
      return;
    }

    setState(() {
      _amountError = null;
      _merchantError = null;
      _isSaving = true;
    });

    try {
      final viewModel = getIt<MoneyViewModel>();

      int accountId;
      if (viewModel.accounts.isNotEmpty) {
        accountId = _selectedAccountId ?? viewModel.accounts.first.id;
      } else {
        accountId = await viewModel.ensureDefaultAccount();
      }

      if (_type == TransactionType.expense) {
        final currentBalance = viewModel.snapshot.balanceOf(accountId);
        if (currentBalance < amountMinor) {
          final accountCurrency = viewModel.snapshot.currencyOf(accountId);
          final msg = tr.insufficientBalanceMessage(
            MoneyFormatter.format(currentBalance, accountCurrency),
          );
          setState(() {
            _amountError = tr.insufficientBalance;
            _isSaving = false;
          });
          if (mounted) showErrorToast(context, msg);
          return;
        }
      }

      final category = TransactionCategories.fromValue(_categoryKey, _type);
      final effectiveMerchant =
          _merchant == 'Other'
              ? _customMerchantController.text.trim()
              : _merchant;

      final id = await viewModel.addTransaction(
        accountId: accountId,
        amountMinor: amountMinor,
        type: _type,
        category: category.label,
        merchant:
            effectiveMerchant?.isNotEmpty == true ? effectiveMerchant : null,
        note:
            _noteController.text.trim().isNotEmpty
                ? _noteController.text.trim()
                : null,
        occurredAt: _date,
      );

      if (effectiveMerchant != null &&
          effectiveMerchant.isNotEmpty &&
          effectiveMerchant != 'Other') {
        await getIt<CategoryRepository>().addMerchant(
          categoryKey: _categoryKey,
          merchant: effectiveMerchant,
        );
      }

      if (mounted) {
        showToast(
          context,
          _type == TransactionType.expense ? tr.expenseAdded : tr.incomeAdded,
          actionLabel: tr.undo,
          onAction: () async {
            await viewModel.deleteTransaction(id);
          },
        );
        _safeClose();
      }
    } catch (e) {
      if (mounted) {
        showErrorToast(context, '${tr.save}: $e');
        setState(() => _isSaving = false);
      }
    }
  }

  void _openCurrencyConverter(BuildContext context) {
    final subService = getIt<SubscriptionService>();
    final tr = context.strings;
    if (!subService.isPro) {
      showProUpgradeSheet(
        context,
        title: tr.multiCurrencyProTitle,
        message: tr.multiCurrencyProMessage,
      );
      return;
    }

    final viewModel = getIt<MoneyViewModel>();
    final baseCode = viewModel.baseCurrency;
    final rates = viewModel.snapshot.rates;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder:
          (sheetContext) => _CurrencyConverterSheet(
            baseCurrency: baseCode,
            rates: rates,
            onApply: (
              convertedAmountMinor,
              foreignAmount,
              foreignCurrency,
              rate,
            ) {
              final formattedAmount = (convertedAmountMinor / 100.0)
                  .toStringAsFixed(2);
              setState(() {
                _amountController.text = formattedAmount;
                _conversionNote =
                    '≈ $foreignCurrency ${foreignAmount.toStringAsFixed(2)} (@ $rate)';
                if (_noteController.text.trim().isEmpty) {
                  _noteController.text =
                      'From $foreignCurrency ${foreignAmount.toStringAsFixed(2)}';
                }
              });
            },
          ),
    );
  }

  void _safeClose() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<MoneyViewModel>();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final tr = context.strings;
    final currencySymbol = Currency.fromCode(viewModel.baseCurrency).symbol;

    final categories = TransactionCategories.forType(_type);

    final merchants = TransactionCategories.merchantsFor(_categoryKey);

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go(AppRoutes.home);
      },
      child: switch (_step) {
        0 => WizardScaffold(
          step: 0,
          steps: 2,
          title: tr.howMuchWasIt,
          subtitle: tr.t(
            'Type the amount. Your keyboard will do the rest.',
            ne: 'रकम प्रविष्ट गर्नुहोस्। किबोर्डले बाँकी काम गर्नेछ।',
            es: 'Escribe la cantidad. El teclado hará el resto.',
            fr: 'Saisissez le montant. Le clavier fera le reste.',
            de: 'Betrag eingeben. Die Tastatur erledigt den Rest.',
            ja: '金額を入力してください。',
            zh: '输入金额，键盘将自动适配。',
            it: 'Inserisci l\'importo. La tastiera farà il resto.',
          ),
          confirmClose: _amountController.text.trim().isNotEmpty,
          discardTitle:
              _type == TransactionType.expense
                  ? tr.discardExpense
                  : tr.discardIncome,
          primaryLabel: tr.next,
          onPrimary: _amountController.text.trim().isEmpty ? null : _onNext,
          onClose: _safeClose,
          child: Column(
            children: [
              SegmentedTabs<TransactionType>(
                options: {
                  TransactionType.expense: tr.expense,
                  TransactionType.income: tr.income,
                },
                value: _type,
                onChanged: (type) {
                  setState(() {
                    _type = type;
                    _categoryKey =
                        _type == TransactionType.expense
                            ? 'eating_out'
                            : 'shift_pay';
                    final newMerchants = TransactionCategories.merchantsFor(
                      _categoryKey,
                    );
                    _merchant =
                        newMerchants.isNotEmpty ? newMerchants.first : null;
                  });
                },
              ),
              const SizedBox(height: AppSpace.xxl),
              BigAmountField(
                currencySymbol: currencySymbol,
                controller: _amountController,
                subtitle: _conversionNote,
                onCurrencyTap: () => _openCurrencyConverter(context),
                autofocus: true,
                isRequired: true,
                errorText: _amountError,
                onChanged: (val) {
                  if (_amountError != null) setState(() => _amountError = null);
                  setState(() {});
                },
              ),
            ],
          ),
        ),
        _ => WizardScaffold(
          step: 1,
          steps: 2,
          title: tr.whatWasItFor,
          subtitle: tr.pickCategoryAndSpent,
          onBack: () => setState(() => _step = 0),
          onClose: _safeClose,
        primaryLabel:
            _isSaving
                ? tr.saving
                : (_type == TransactionType.expense
                    ? tr.saveExpense
                    : tr.saveIncome),
        onPrimary: _isSaving ? null : _save,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Grid View (3 columns)
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
                if (index == categories.length) {
                  return _NewCategoryCard(
                    onTap: () => _promptNewCategory(context),
                  );
                }
                final cat = categories[index];
                final isSelected = _categoryKey == cat.value;
                return _CategoryGridCard(
                  category: cat,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _categoryKey = cat.value;
                      final mList = TransactionCategories.merchantsFor(
                        _categoryKey,
                      );
                      _merchant = mList.isNotEmpty ? mList.first : null;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: AppSpace.xl),

            // "Where?" merchant card grid (PDF pages 33-34)
            if (merchants.isNotEmpty) ...[
              Text(
                tr.whereQuestion,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth =
                      (constraints.maxWidth - 3 * AppSpace.sm) / 4;
                  return Wrap(
                    spacing: AppSpace.sm,
                    runSpacing: AppSpace.sm,
                    children: [
                      for (final m in merchants)
                        SizedBox(
                          width: itemWidth,
                          child: _MerchantCard(
                            name: m,
                            selected: _merchant == m,
                            onTap: () {
                              setState(() {
                                _merchant = _merchant == m ? null : m;
                              });
                            },
                          ),
                        ),
                      SizedBox(
                        width: itemWidth,
                        child: _MerchantCard(
                          name: tr.otherOption,
                          isOther: true,
                          selected: _merchant == 'Other',
                          onTap: () {
                            setState(() {
                              _merchant = _merchant == 'Other' ? null : 'Other';
                            });
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (_merchant == 'Other') ...[
                const SizedBox(height: AppSpace.md),
                UnderlineField(
                  label: tr.merchantName,
                  hint: tr.merchantHint,
                  controller: _customMerchantController,
                  isRequired: true,
                  errorText: _merchantError,
                  onChanged: (val) {
                    if (_merchantError != null) {
                      setState(() => _merchantError = null);
                    }
                    setState(() {});
                  },
                ),
              ],
              const SizedBox(height: AppSpace.xl),
            ],

            // Multi-account picker (if multiple accounts exist)
            if (viewModel.accounts.length > 1) ...[
              Text(
                tr.t(
                  'Account',
                  ne: 'खाता',
                  es: 'Cuenta',
                  fr: 'Compte',
                  de: 'Konto',
                  ja: '口座',
                  zh: '账户',
                  it: 'Conto',
                ),
                style: text.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: viewModel.accounts.length,
                  separatorBuilder:
                      (context, index) => const SizedBox(width: AppSpace.sm),
                  itemBuilder: (context, index) {
                    final acc = viewModel.accounts[index];
                    final isSelected =
                        (_selectedAccountId ?? viewModel.accounts.first.id) ==
                        acc.id;
                    final balance = viewModel.snapshot.balanceOf(acc.id);
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap:
                            () => setState(() => _selectedAccountId = acc.id),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.md,
                            vertical: AppSpace.sm,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? scheme.primary.withValues(alpha: 0.08)
                                    : scheme.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? scheme.primary
                                      : scheme.outlineVariant,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? scheme.primary
                                          : scheme.surfaceContainerHighest
                                              .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.sm,
                                  ),
                                ),
                                child: Center(
                                  child: AppIcon(
                                    HugeIcons.strokeRoundedSafe,
                                    size: 18,
                                    color:
                                        isSelected
                                            ? scheme.onPrimary
                                            : scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpace.sm),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr.accountDisplayName(acc.name),
                                    style: text.labelMedium?.copyWith(
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                      color:
                                          isSelected
                                              ? scheme.primary
                                              : scheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    MoneyFormatter.format(
                                      balance,
                                      acc.currencyCode,
                                    ),
                                    style: text.bodySmall?.copyWith(
                                      fontFamily: 'RedditMono',
                                      fontSize: 11,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpace.xl),
            ],

            // Date and Note Card (PDF pages 33-34)
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.lg,
                        vertical: AppSpace.lg,
                      ),
                      child: Row(
                        children: [
                          Text(
                            tr.date,
                            style: text.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            AppDate.dateOnly(_date) ==
                                    AppDate.dateOnly(DateTime.now())
                                ? tr.today
                                : AppDate.short(_date),
                            style: text.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const RowDivider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.lg,
                      vertical: AppSpace.sm,
                    ),
                    child: Row(
                      children: [
                        Text(
                          tr.note,
                          style: text.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: TextField(
                            controller: _noteController,
                            textAlign: TextAlign.right,
                            style: text.bodyMedium?.copyWith(
                              color: scheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: tr.optional,
                              hintStyle: text.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: AppSpace.sm,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    },
  );
}

  void _promptNewCategory(BuildContext context) {
    final ctrl = TextEditingController();
    final tr = context.strings;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpace.page,
              AppSpace.lg,
              AppSpace.page,
              MediaQuery.of(ctx).viewInsets.bottom + AppSpace.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _type == TransactionType.expense
                      ? tr.addCustomExpenseCategory
                      : tr.addCustomIncomeCategory,
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpace.md),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: tr.categoryNameLabel,
                    hintText: tr.categoryNameHint,
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                AppButton(
                  tr.addCategoryButton,
                  onPressed: () async {
                    final name = ctrl.text.trim();
                    if (name.isEmpty) return;
                    Navigator.of(ctx).pop();
                    final cat = await getIt<CategoryRepository>().addCategory(
                      label: name,
                      type: _type,
                    );
                    setState(() {
                      _categoryKey = cat.value;
                      _merchant = null;
                    });
                  },
                ),
              ],
            ),
          ),
    );
  }
}

class _MerchantCard extends StatelessWidget {
  const _MerchantCard({
    required this.name,
    required this.selected,
    required this.onTap,
    this.isOther = false,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;
  final bool isOther;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? scheme.onSurface : scheme.outlineVariant,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpace.md,
          horizontal: AppSpace.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isOther)
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F1F2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.add, size: 20, color: scheme.onSurface),
              )
            else
              LetterAvatar(name, size: 40, isCircle: true),
            const SizedBox(height: AppSpace.sm),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: text.labelSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconGlyph _iconForCategory(String key, TransactionType type) {
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

Color _colorForCategory(
  String key,
  BuildContext context,
  TransactionType type,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  switch (key) {
    case 'groceries':
      return isDark
          ? const Color(0xFF225B40)
          : const Color(0xFF164A33); // Dark forest pine
    case 'eating_out':
      return isDark
          ? const Color(0xFF7A3E16)
          : const Color(0xFF5A2D0C); // Burnt dark umber
    case 'entertainment':
      return isDark
          ? const Color(0xFF563077)
          : const Color(0xFF3E1F58); // Deep rich plum
    case 'transport':
      return isDark
          ? const Color(0xFF234763)
          : const Color(0xFF1A334A); // Midnight slate navy
    case 'bills':
      return isDark
          ? const Color(0xFF75242E)
          : const Color(0xFF581820); // Deep bordeaux crimson
    case 'salary':
      return isDark
          ? const Color(0xFF1B5536)
          : const Color(0xFF0F3D24); // Deep forest jade
    case 'shift_pay':
      return isDark
          ? const Color(0xFF1B5250)
          : const Color(0xFF113C3B); // Dark spruce oceanic
    case 'business':
      return isDark
          ? const Color(0xFF38326D)
          : const Color(0xFF282352); // Deep midnight indigo
    case 'interest':
      return isDark
          ? const Color(0xFF16535D)
          : const Color(0xFF0E3F47); // Dark petrol cyan
    case 'gift_received':
      return isDark
          ? const Color(0xFF752852)
          : const Color(0xFF5C1D3F); // Blackberry wine
    default:
      return isDark
          ? const Color(0xFF3E434D)
          : const Color(0xFF2D3139); // Deep dark slate
  }
}

class _CategoryGridCard extends StatelessWidget {
  const _CategoryGridCard({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final TransactionCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final icon = _iconForCategory(category.value, category.type);
    final color = _colorForCategory(category.value, context, category.type);

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
              color:
                  isSelected
                      ? color
                      : scheme.outlineVariant.withValues(alpha: 0.7),
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: AppIcon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                category.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: text.labelSmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 11,
                  color: isSelected ? color : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewCategoryCard extends StatelessWidget {
  const _NewCategoryCard({required this.onTap});

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
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: scheme.outlineVariant,
              style: BorderStyle.solid,
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: AppIcon(
                  HugeIcons.strokeRoundedPlusSign,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '+ ${context.strings.newLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: text.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrencyConverterSheet extends StatefulWidget {
  const _CurrencyConverterSheet({
    required this.baseCurrency,
    required this.rates,
    required this.onApply,
  });

  final String baseCurrency;
  final List<ExchangeRateQuote> rates;
  final void Function(
    int convertedAmountMinor,
    double foreignAmount,
    String foreignCurrency,
    double rate,
  )
  onApply;

  @override
  State<_CurrencyConverterSheet> createState() =>
      _CurrencyConverterSheetState();
}

class _CurrencyConverterSheetState extends State<_CurrencyConverterSheet> {
  late String _selectedForeignCurrency;
  final _foreignAmountController = TextEditingController();
  final Map<String, double> _liveServerRates = {};
  bool _isUsingServerRate = false;

  static const _supportedCurrencies = [
    'AUD',
    'USD',
    'EUR',
    'GBP',
    'INR',
    'NPR',
    'CAD',
    'JPY',
  ];

  @override
  void initState() {
    super.initState();
    _selectedForeignCurrency = widget.baseCurrency == 'NPR' ? 'AUD' : 'USD';
    _fetchServerRates();
  }

  Future<void> _fetchServerRates() async {
    try {
      final remoteRates = await ApiClient.instance.getForexRates();
      if (remoteRates != null && mounted) {
        for (final r in remoteRates) {
          final pair = '${r['baseCode']}_${r['quoteCode']}';
          _liveServerRates[pair] = (r['rate'] as num).toDouble();
        }
        setState(() {});
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _foreignAmountController.dispose();
    super.dispose();
  }

  double _getRate(String from, String to) {
    if (from == to) return 1.0;

    // 1. Check live institutional server rates first
    final directPair = '${from}_$to';
    if (_liveServerRates.containsKey(directPair)) {
      _isUsingServerRate = true;
      return _liveServerRates[directPair]!;
    }
    final inversePair = '${to}_$from';
    if (_liveServerRates.containsKey(inversePair) &&
        _liveServerRates[inversePair]! != 0) {
      _isUsingServerRate = true;
      return 1.0 / _liveServerRates[inversePair]!;
    }

    _isUsingServerRate = false;

    // 2. Check local database quotes
    for (final q in widget.rates) {
      if (q.baseCode == from && q.quoteCode == to) return q.rate;
      if (q.baseCode == to && q.quoteCode == from && q.rate != 0) {
        return 1.0 / q.rate;
      }
    }
    const defaultNprRates = {
      'AUD': 93.42,
      'USD': 142.60,
      'INR': 1.60,
      'EUR': 148.0,
      'GBP': 175.0,
      'CAD': 98.0,
      'JPY': 0.90,
    };
    if (to == 'NPR' && defaultNprRates.containsKey(from)) {
      return defaultNprRates[from]!;
    }
    if (from == 'NPR' && defaultNprRates.containsKey(to)) {
      return 1.0 / defaultNprRates[to]!;
    }
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final tr = context.strings;

    final foreignAmount =
        double.tryParse(_foreignAmountController.text.trim()) ?? 0.0;
    final rate = _getRate(_selectedForeignCurrency, widget.baseCurrency);
    final convertedAmount = foreignAmount * rate;
    final convertedMinor = (convertedAmount * 100).round();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr.currencyConverter,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tr.convertForeignAmountIntoBase(widget.baseCurrency),
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (_isUsingServerRate) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.circle,
                              size: 7,
                              color: Color(0xFF16A34A),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              tr.liveInstitutionalRates,
                              style: text.bodySmall?.copyWith(
                                color: const Color(0xFF16A34A),
                                fontWeight: FontWeight.w700,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            // Currency selector chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final code in _supportedCurrencies)
                  if (code != widget.baseCurrency)
                    ChoiceChip(
                      label: Text(code),
                      selected: _selectedForeignCurrency == code,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedForeignCurrency = code);
                        }
                      },
                    ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            // Foreign Amount text field
            TextField(
              controller: _foreignAmountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: text.headlineSmall,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: tr.t(
                  'Amount in $_selectedForeignCurrency',
                  ne: '$_selectedForeignCurrency मा रकम',
                  es: 'Monto en $_selectedForeignCurrency',
                  fr: 'Montant en $_selectedForeignCurrency',
                  de: 'Betrag in $_selectedForeignCurrency',
                  ja: '$_selectedForeignCurrency での金額',
                  zh: '以 $_selectedForeignCurrency 计金额',
                  it: 'Importo in $_selectedForeignCurrency',
                ),
                prefixText:
                    '${Currency.fromCode(_selectedForeignCurrency).symbol} ',
                border: const OutlineInputBorder(),
                hintText: tr.localizeDigits('25.00'),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            // Rate info card
            Container(
              padding: const EdgeInsets.all(AppSpace.md),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tr.exchangeRate,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        tr.localizeDigits(
                          '1 $_selectedForeignCurrency = ${rate.toStringAsFixed(2)} ${widget.baseCurrency}',
                        ),
                        style: text.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tr.convertedIn(widget.baseCurrency),
                        style: text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${Currency.fromCode(widget.baseCurrency).symbol} ${tr.localizeDigits(convertedAmount.toStringAsFixed(2))}',
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            FilledButton.icon(
              onPressed:
                  foreignAmount <= 0
                      ? null
                      : () {
                        widget.onApply(
                          convertedMinor,
                          foreignAmount,
                          _selectedForeignCurrency,
                          rate,
                        );
                        Navigator.of(context).pop();
                      },
              icon: const Icon(Icons.check),
              label: Text(
                tr.t(
                  'Apply ${Currency.fromCode(widget.baseCurrency).symbol} ${convertedAmount.toStringAsFixed(2)}',
                  ne:
                      '${Currency.fromCode(widget.baseCurrency).symbol} ${tr.localizeDigits(convertedAmount.toStringAsFixed(2))} लागू गर्नुहोस्',
                  es:
                      'Aplicar ${Currency.fromCode(widget.baseCurrency).symbol} ${convertedAmount.toStringAsFixed(2)}',
                  fr:
                      'Appliquer ${Currency.fromCode(widget.baseCurrency).symbol} ${convertedAmount.toStringAsFixed(2)}',
                  de:
                      '${Currency.fromCode(widget.baseCurrency).symbol} ${convertedAmount.toStringAsFixed(2)} übernehmen',
                  ja:
                      '${Currency.fromCode(widget.baseCurrency).symbol} ${convertedAmount.toStringAsFixed(2)} を適用',
                  zh:
                      '应用 ${Currency.fromCode(widget.baseCurrency).symbol} ${convertedAmount.toStringAsFixed(2)}',
                  it:
                      'Applica ${Currency.fromCode(widget.baseCurrency).symbol} ${convertedAmount.toStringAsFixed(2)}',
                ),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
          ],
        ),
      ),
    );
  }
}
