import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/debts/data/model/debt.dart';
import 'package:finance_tracker/features/debts/viewmodels/debts_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

enum _DebtFilter { active, lent, borrowed, settled }

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  final DebtsViewModel _viewModel = getIt<DebtsViewModel>();
  _DebtFilter _filter = _DebtFilter.active;
  String? _selectedParty;

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  List<Debt> get _filteredDebts {
    List<Debt> baseList;
    switch (_filter) {
      case _DebtFilter.active:
        baseList = _viewModel.activeDebts;
        break;
      case _DebtFilter.lent:
        baseList = _viewModel.activeDebts
            .where((d) => d.type == DebtType.lent.value)
            .toList();
        break;
      case _DebtFilter.borrowed:
        baseList = _viewModel.activeDebts
            .where((d) => d.type == DebtType.borrowed.value)
            .toList();
        break;
      case _DebtFilter.settled:
        baseList = _viewModel.settledDebts;
        break;
    }

    if (_selectedParty != null) {
      baseList = baseList
          .where((d) => d.personName.trim().toLowerCase() == _selectedParty!.trim().toLowerCase())
          .toList();
    }
    return baseList;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tr = context.strings;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final isFiltered = _filter != _DebtFilter.active || _selectedParty != null;

    return Scaffold(
      appBar: AppTopBar(
        title: tr.debts,
        actions: [
          if (isFiltered)
            TopBarAction(
              HugeIcons.strokeRoundedFilterRemove,
              tooltip: tr.resetFilters,
              onPressed: () => setState(() {
                _filter = _DebtFilter.active;
                _selectedParty = null;
              }),
            ),
          TopBarAction(
            HugeIcons.strokeRoundedPlusSign,
            tooltip: tr.addRecord,
            onPressed: () => context.push(AppRoutes.addDebt),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.lg),
        children: [
          // Net Debt Overview Card
          _buildOverviewCard(colors, scheme, text, tr),
          const SizedBox(height: AppSpace.lg),

          // Two-button Filter Bar (Status Popup + Counterparty Bottom Sheet)
          Row(
            children: [
              Expanded(
                child: _DebtStatusFilterButton(
                  currentFilter: _filter,
                  onChanged: (f) => setState(() => _filter = f),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: _DebtPartyFilterButton(
                  selectedParty: _selectedParty,
                  existingParties: _viewModel.existingParties,
                  baseCurrency: _viewModel.baseCurrency,
                  netForParty: _viewModel.netForParty,
                  onChanged: (p) => setState(() => _selectedParty = p),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),

          // Debts List
          if (_filteredDebts.isEmpty)
            EmptyState(
              icon: HugeIcons.strokeRoundedMoney01,
              title: isFiltered ? tr.noMatchingRecords : tr.noDebtRecordsFound,
              message: isFiltered
                  ? tr.t('No records match the current filter criteria.', ne: 'तपाईंले छान्नुभएको फिल्टर अनुसार कुनै रेकर्ड छैन।', es: 'No hay registros que coincidan con el filtro actual.', fr: 'Aucun enregistrement ne correspond aux critères actuels.', de: 'Keine Einträge für diese Filterkriterien gefunden.', ja: '選択した条件に一致する記録はありません。', zh: '暂无符合所选筛选条件的记录。', it: 'Nessun record corrisponde ai criteri attuali.')
                  : tr.t('Track money lent to friends or borrowed with due dates and repayments.', ne: 'साथीभाइलाई दिएको वा लिएको सापटी, फिर्ता मिति र किस्ता ट्र्याक गर्नुहोस्।', es: 'Controla el dinero prestado o tomado con vencimientos y pagos.', fr: 'Suivez l\'argent prêté ou emprunté avec dates d\'échéance et remboursements.', de: 'Verfolgen Sie geliehenes Geld mit Fälligkeitsdaten und Raten.', ja: '貸し借りや返済期日、一部返済を管理できます。', zh: '轻松追踪借给他人或向人借入的款项、到期日与分期还款进度。', it: 'Tieni traccia di prestiti e debiti con scadenze e rimborsi.'),
              actionLabel: isFiltered ? tr.resetFilters : tr.addLoanOrDebt,
              onAction: isFiltered
                  ? () => setState(() {
                      _filter = _DebtFilter.active;
                      _selectedParty = null;
                    })
                  : () => context.push(AppRoutes.addDebt),
            )
          else
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < _filteredDebts.length; i++) ...[
                    if (i > 0) const RowDivider(),
                    _buildDebtRow(_filteredDebts[i], colors, scheme, text, tr),
                  ],
                ],
              ),
            ),
          const SizedBox(height: AppSpace.xxl),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(
    AppColors colors,
    ColorScheme scheme,
    TextTheme text,
    AppStrings tr,
  ) {
    final net = _viewModel.netBalanceMinor;
    final isPositive = net >= 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr.netDebtBalance,
                style: text.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 1.1,
                ),
              ),
              StatusChip(
                isPositive ? tr.netReceivable : tr.netPayable,
                tone: isPositive ? ChipTone.success : ChipTone.danger,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            '${isPositive ? '+' : '−'}${MoneyFormatter.format(net.abs(), _viewModel.baseCurrency)}',
            style: text.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: isPositive ? colors.income : colors.expense,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          const RowDivider(),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppIcon(HugeIcons.strokeRoundedArrowUpRight01, size: 14, color: colors.income),
                        const SizedBox(width: 4),
                        Text(
                          tr.lentToOthers,
                          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      MoneyFormatter.format(_viewModel.totalLentMinor, _viewModel.baseCurrency),
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.income,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: scheme.outlineVariant),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppIcon(HugeIcons.strokeRoundedArrowDownLeft01, size: 14, color: colors.expense),
                        const SizedBox(width: 4),
                        Text(
                          tr.borrowedFromOthers,
                          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      MoneyFormatter.format(_viewModel.totalBorrowedMinor, _viewModel.baseCurrency),
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
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
    );
  }


  Widget _buildDebtRow(
    Debt debt,
    AppColors colors,
    ColorScheme scheme,
    TextTheme text,
    AppStrings tr,
  ) {
    final isLent = debt.type == DebtType.lent.value;
    final isSettled = debt.isSettled;
    final dateStr = debt.dueDate != null
        ? AppDate.short(DateTime.fromMillisecondsSinceEpoch(debt.dueDate!))
        : null;

    final subtext = <String>[];
    if (isLent) {
      subtext.add(tr.theyOweYou);
    } else {
      subtext.add(tr.youOweThem);
    }
    if (dateStr != null) {
      subtext.add('${tr.duePrefix} $dateStr');
    }
    if (debt.note != null && debt.note!.isNotEmpty) {
      subtext.add(debt.note!);
    }

    return ListRow(
      leading: LetterAvatar(debt.personName, size: 40),
      title: debt.personName,
      subtitle: subtext.join(' · '),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${isLent ? '+' : '−'}${MoneyFormatter.format(debt.amountMinor, debt.currencyCode)}',
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isSettled
                      ? scheme.onSurfaceVariant
                      : (isLent ? colors.income : colors.expense),
                  decoration: isSettled ? TextDecoration.lineThrough : null,
                ),
              ),
              if (isSettled)
                Text(
                  tr.settled,
                  style: text.bodySmall?.copyWith(
                    color: colors.income,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpace.xs),
          const Chevron(),
        ],
      ),
      onTap: () => _showDebtDetailsSheet(context, debt),
    );
  }

  void _showDebtDetailsSheet(BuildContext context, Debt debt) {
    final isLent = debt.type == DebtType.lent.value;
    final isSettled = debt.isSettled;
    final colors = context.colors;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final tr = context.strings;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  LetterAvatar(debt.personName, size: 44),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debt.personName,
                          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isLent ? tr.lentReceivable : tr.borrowedPayable,
                          style: text.bodySmall?.copyWith(
                            color: isLent ? colors.income : colors.expense,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(
                    isSettled ? tr.settled : tr.active,
                    tone: isSettled ? ChipTone.success : ChipTone.warning,
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),

              // Amount Card
              AppCard(
                child: Column(
                  children: [
                    Text(
                      tr.currentBalance,
                      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      MoneyFormatter.format(debt.amountMinor, debt.currencyCode),
                      style: text.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isSettled
                            ? scheme.onSurfaceVariant
                            : (isLent ? colors.income : colors.expense),
                      ),
                    ),
                    if (debt.dueDate != null) ...[
                      const SizedBox(height: AppSpace.sm),
                      Text(
                        '${tr.dueDateLabel} ${AppDate.short(DateTime.fromMillisecondsSinceEpoch(debt.dueDate!))}',
                        style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                    if (debt.note != null && debt.note!.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        debt.note!,
                        style: text.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.lg),

              // Action buttons
              if (!isSettled) ...[
                AppButton(
                  tr.recordRepayment,
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _showRecordPaymentSheet(context, debt);
                  },
                ),
                const SizedBox(height: AppSpace.sm),
                AppButton(
                  tr.quickSettle,
                  kind: AppButtonKind.secondary,
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    await _viewModel.settleDebt(debt.id);
                    if (context.mounted) {
                      showToast(context, tr.markedAsSettled);
                    }
                  },
                ),
              ] else ...[
                AppButton(
                  tr.markAsUnsettled,
                  kind: AppButtonKind.secondary,
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    await _viewModel.unsettleDebt(debt.id);
                    if (context.mounted) {
                      showToast(context, tr.markedAsUnsettled);
                    }
                  },
                ),
              ],
              const SizedBox(height: AppSpace.sm),
              AppButton(
                tr.deleteRecordTitle,
                kind: AppButtonKind.danger,
                onPressed: () async {
                  final confirmed = await showConfirmDialog(
                    context,
                    title: tr.deleteRecordQuestion,
                    message: tr.t('Are you sure you want to permanently delete this debt record?', ne: 'के तपाईं निश्चित हुनुहुन्छ? यो रेकर्ड स्थायी रूपमा मेटिनेछ।', es: '¿Estás seguro de que deseas eliminar permanentemente este registro?', fr: 'Êtes-vous sûr de vouloir supprimer définitivement cet enregistrement ?', de: 'Möchten Sie diesen Schuldeneintrag wirklich dauerhaft löschen?', ja: 'この記録を完全に削除してもよろしいですか？', zh: '确定要永久删除此条借贷记录吗？', it: 'Sei sicuro di voler eliminare definitivamente questo record?'),
                    confirmLabel: tr.delete,
                    cancelLabel: tr.cancel,
                  );
                  if (confirmed && context.mounted) {
                    Navigator.of(sheetContext).pop();
                    await _viewModel.deleteDebt(debt.id);
                    if (context.mounted) {
                      showToast(context, tr.recordDeleted);
                    }
                  }
                },
              ),
              const SizedBox(height: AppSpace.sm),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecordPaymentSheet(BuildContext context, Debt debt) {
    final tr = context.strings;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isLent = debt.type == DebtType.lent.value;

    final amountController = TextEditingController(
      text: (debt.amountMinor / 100.0).toStringAsFixed(2),
    );
    bool linkCashFlow = true;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (dlgContext) {
        String? paymentError;
        return StatefulBuilder(
          builder: (context, setDlgState) => Padding(
            padding: EdgeInsets.only(
              left: AppSpace.xl,
              right: AppSpace.xl,
              top: AppSpace.xl,
              bottom: MediaQuery.of(context).viewInsets.bottom + AppSpace.xl,
            ),
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
                            tr.recordRepayment,
                            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${debt.personName} · ${tr.remainingLabel} ${MoneyFormatter.format(debt.amountMinor, debt.currencyCode)}',
                            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(dlgContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.lg),

                // Repayment Amount
                UnderlineField(
                  controller: amountController,
                  label: '${tr.paymentAmount} (${debt.currencyCode})',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  isRequired: true,
                  errorText: paymentError,
                  onChanged: (val) {
                    if (paymentError != null) {
                      setDlgState(() => paymentError = null);
                    } else {
                      setDlgState(() {});
                    }
                  },
                ),
                const SizedBox(height: AppSpace.lg),

                // Cash Flow Switch
                AppCard(
                  padding: EdgeInsets.zero,
                  child: SwitchRow(
                    title: tr.recordInEverydayAccount,
                    subtitle: isLent ? tr.inflowEverydayBalance : tr.outflowEverydayBalance,
                    value: linkCashFlow,
                    onChanged: (val) => setDlgState(() => linkCashFlow = val),
                  ),
                ),
                const SizedBox(height: AppSpace.xl),

                AppButton(
                  tr.savePayment,
                  onPressed: amountController.text.trim().isEmpty
                      ? null
                      : () async {
                          final parsed = double.tryParse(amountController.text.trim());
                          if (parsed == null || parsed <= 0) {
                            setDlgState(() => paymentError = tr.enterValidAmount);
                            showErrorToast(
                              context,
                              tr.enterValidAmount,
                            );
                            return;
                          }

                          final minor = (parsed * 100).round();
                          await _viewModel.recordPayment(
                            debt: debt,
                            paymentMinor: minor,
                            linkCashFlow: linkCashFlow,
                          );
                          if (dlgContext.mounted) {
                            Navigator.of(dlgContext).pop();
                          }
                          if (context.mounted) {
                            showToast(
                              context,
                              tr.paymentRecordedSuccess,
                            );
                          }
                        },
                ),
                const SizedBox(height: AppSpace.sm),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DebtStatusFilterButton extends StatelessWidget {
  const _DebtStatusFilterButton({
    required this.currentFilter,
    required this.onChanged,
  });

  final _DebtFilter currentFilter;
  final ValueChanged<_DebtFilter> onChanged;

  String _getLabel(BuildContext context, _DebtFilter filter) {
    final tr = context.strings;
    switch (filter) {
      case _DebtFilter.active:
        return tr.active;
      case _DebtFilter.lent:
        return tr.lentReceivable;
      case _DebtFilter.borrowed:
        return tr.borrowedPayable;
      case _DebtFilter.settled:
        return tr.settled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCustom = currentFilter != _DebtFilter.active;
    final label = _getLabel(context, currentFilter);

    return PopupMenuButton<_DebtFilter>(
      initialValue: currentFilter,
      onSelected: onChanged,
      itemBuilder: (ctx) => [
        for (final f in _DebtFilter.values)
          PopupMenuItem(
            value: f,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _getLabel(ctx, f),
                    style: TextStyle(
                      fontWeight: currentFilter == f ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
                if (currentFilter == f)
                  Icon(Icons.check, size: 16, color: theme.colorScheme.primary),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 10),
        decoration: BoxDecoration(
          color: isCustom ? theme.colorScheme.primary.withValues(alpha: 0.08) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isCustom ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.tune_rounded,
              size: 16,
              color: isCustom ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isCustom ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: isCustom ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _DebtPartyFilterButton extends StatelessWidget {
  const _DebtPartyFilterButton({
    required this.selectedParty,
    required this.existingParties,
    required this.baseCurrency,
    required this.netForParty,
    required this.onChanged,
  });

  final String? selectedParty;
  final List<String> existingParties;
  final String baseCurrency;
  final int Function(String party) netForParty;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = context.strings;
    final hasParty = selectedParty != null;
    final label = hasParty ? selectedParty! : tr.allParties;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () => _showPartySheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 10),
        decoration: BoxDecoration(
          color: hasParty ? theme.colorScheme.primary.withValues(alpha: 0.08) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: hasParty ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 16,
              color: hasParty ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: hasParty ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: hasParty ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  void _showPartySheet(BuildContext context) {
    final theme = Theme.of(context);
    final tr = context.strings;
    final colors = context.colors;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr.filterByCounterparty,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (selectedParty != null)
                      TextButton(
                        onPressed: () {
                          onChanged(null);
                          Navigator.pop(ctx);
                        },
                        child: Text(tr.clearAction),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.people_alt_rounded),
                title: Text(tr.allParties),
                trailing: selectedParty == null
                    ? Icon(Icons.check, color: theme.colorScheme.primary)
                    : null,
                onTap: () {
                  onChanged(null);
                  Navigator.pop(ctx);
                },
              ),
              if (existingParties.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpace.xl),
                  child: Center(
                    child: Text(
                      tr.noCounterpartiesYet,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: existingParties.length,
                    separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 56),
                    itemBuilder: (ctx, index) {
                      final party = existingParties[index];
                      final net = netForParty(party);
                      final isSelected = selectedParty == party;
                      final isPositive = net >= 0;

                      return ListTile(
                        leading: LetterAvatar(party, size: 36),
                        title: Text(
                          party,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          isPositive
                              ? (tr.isNepali
                                  ? 'उनीहरूले तिर्नुपर्ने: +${MoneyFormatter.format(net.abs(), baseCurrency)}'
                                  : 'Owes you: +${MoneyFormatter.format(net.abs(), baseCurrency)}')
                              : (tr.isNepali
                                  ? 'तपाईंले तिर्नुपर्ने: −${MoneyFormatter.format(net.abs(), baseCurrency)}'
                                  : 'You owe: −${MoneyFormatter.format(net.abs(), baseCurrency)}'),
                          style: TextStyle(
                            color: isPositive ? colors.income : colors.expense,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check, color: theme.colorScheme.primary)
                            : null,
                        onTap: () {
                          onChanged(party);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
