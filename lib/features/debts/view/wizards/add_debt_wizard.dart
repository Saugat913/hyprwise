import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/debts/data/model/debt.dart';
import 'package:finance_tracker/features/debts/viewmodels/debts_view_model.dart';
import 'package:finance_tracker/features/shared/data/currency.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';
import 'package:finance_tracker/features/subscription/data/subscription_service.dart';
import 'package:finance_tracker/core/network/api_client.dart';

class AddDebtWizard extends StatefulWidget {
  const AddDebtWizard({
    super.key,
    this.initialType = DebtType.lent,
  });

  final DebtType initialType;

  @override
  State<AddDebtWizard> createState() => _AddDebtWizardState();
}

class _AddDebtWizardState extends State<AddDebtWizard> {
  int _step = 0;
  late DebtType _type;
  final _amountController = TextEditingController();
  final _partyController = TextEditingController();
  final _interestController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime? _dueDate;
  bool _linkCashFlow = true;
  String? _conversionNote;
  bool _isSaving = false;

  String? _amountError;
  String? _partyError;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _partyController.dispose();
    _interestController.dispose();
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
    final partyName = _partyController.text.trim();
    if (partyName.isEmpty) {
      final msg = tr.t('Please enter a party name', ne: 'कृपया पार्टीको नाम प्रविष्ट गर्नुहोस्', es: 'Por favor ingrese un nombre', fr: 'Veuillez saisir un nom', de: 'Bitte Namen eingeben', ja: '相手の名前を入力してください', zh: '请输入对方姓名', it: 'Inserisci un nome');
      setState(() => _partyError = msg);
      showErrorToast(context, msg);
      return;
    }

    final amountDouble = double.tryParse(_amountController.text) ?? 0;
    final amountMinor = (amountDouble * 100).round();
    if (amountMinor <= 0) {
      setState(() => _amountError = tr.enterValidAmount);
      showErrorToast(context, tr.enterValidAmount);
      return;
    }

    setState(() {
      _partyError = null;
      _amountError = null;
      _isSaving = true;
    });

    try {
      final viewModel = getIt<DebtsViewModel>();
      if (_type == DebtType.lent && _linkCashFlow) {
        final everydayAcc = viewModel.financeStore.everydayAccount;
        if (everydayAcc != null) {
          final currentBalance = viewModel.financeStore.snapshot.balanceOf(everydayAcc.id);
          if (currentBalance < amountMinor) {
            final accCurrency = everydayAcc.currencyCode;
            final msg = tr.t(
              'Insufficient balance: Only ${MoneyFormatter.format(currentBalance, accCurrency)} available in Everyday account.',
              ne: 'अपर्याप्त ब्यालेन्स: सापटी दिन खातामा मात्र ${MoneyFormatter.format(currentBalance, accCurrency)} उपलब्ध छ।',
              es: 'Saldo insuficiente: Solo ${MoneyFormatter.format(currentBalance, accCurrency)} disponible.',
              fr: 'Solde insuffisant : Seulement ${MoneyFormatter.format(currentBalance, accCurrency)} disponible.',
              de: 'Unzureichender Saldo: Nur ${MoneyFormatter.format(currentBalance, accCurrency)} verfügbar.',
              ja: '残高不足: 日常口座には${MoneyFormatter.format(currentBalance, accCurrency)}しかありません。',
              zh: '余额不足：日常账户中仅有 ${MoneyFormatter.format(currentBalance, accCurrency)} 可用。',
              it: 'Saldo insufficiente: Solo ${MoneyFormatter.format(currentBalance, accCurrency)} disponibile.',
            );
            setState(() {
              _amountError = tr.insufficientBalance;
              _isSaving = false;
            });
            showErrorToast(context, msg);
            return;
          }
        }
      }

      final interest = double.tryParse(_interestController.text.trim());

      await viewModel.addDebt(
        personName: partyName,
        type: _type,
        amountMinor: amountMinor,
        currencyCode: viewModel.baseCurrency,
        dueDate: _dueDate,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        linkCashFlow: _linkCashFlow,
        interestRatePercent: interest,
      );

      if (mounted) {
        showToast(
          context,
          tr.t(
            _type == DebtType.lent ? 'Loan record saved' : 'Debt record saved',
            ne: _type == DebtType.lent ? 'सापटी रेकर्ड थपियो' : 'ऋण रेकर्ड थपियो',
            es: _type == DebtType.lent ? 'Préstamo guardado' : 'Deuda guardada',
            fr: _type == DebtType.lent ? 'Prêt enregistré' : 'Dette enregistrée',
            de: _type == DebtType.lent ? 'Krediteintrag gespeichert' : 'Schuldeneintrag gespeichert',
            ja: _type == DebtType.lent ? '貸出記録を保存しました' : '借入記録を保存しました',
            zh: _type == DebtType.lent ? '借出记录已保存' : '借入记录已保存',
            it: _type == DebtType.lent ? 'Prestito salvato' : 'Debito salvato',
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        showErrorToast(context, tr.couldNotSave(e.toString()));
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now.add(const Duration(days: 14)),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
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

    final viewModel = getIt<DebtsViewModel>();
    final baseCode = viewModel.baseCurrency;
    final rates = viewModel.financeStore.snapshot.rates;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _CurrencyConverterSheet(
        baseCurrency: baseCode,
        rates: rates,
        onApply: (convertedAmountMinor, foreignAmount, foreignCurrency, rate) {
          final formattedAmount = (convertedAmountMinor / 100.0).toStringAsFixed(2);
          setState(() {
            _amountController.text = formattedAmount;
            _conversionNote = '≈ $foreignCurrency ${foreignAmount.toStringAsFixed(2)} (@ $rate)';
            if (_noteController.text.trim().isEmpty) {
              _noteController.text = 'From $foreignCurrency ${foreignAmount.toStringAsFixed(2)}';
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<DebtsViewModel>();
    final tr = context.strings;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final currencySymbol = Currency.fromCode(viewModel.baseCurrency).symbol;

    final existingParties = viewModel.existingParties;

    return switch (_step) {
      0 => WizardScaffold(
          step: 0,
          steps: 2,
          title: tr.howMuchWasIt,
          subtitle: tr.t('Select whether you lent or borrowed this amount.', ne: 'तपाईंले सापटी दिनुभएको वा लिनुभएको छान्नुहोस्।', es: 'Selecciona si prestaste o tomaste prestado este importe.', fr: 'Indiquez si vous avez prêté ou emprunté cette somme.', de: 'Wählen Sie, ob Sie geliehen oder geborgt haben.', ja: '貸したのか借りたのかを選択してください。', zh: '请选择该笔款项为借出或借入。', it: 'Seleziona se hai prestato o preso in prestito.'),
          confirmClose: _amountController.text.trim().isNotEmpty,
          discardTitle: tr.discardThis,
          primaryLabel: tr.next,
          onPrimary: _amountController.text.trim().isEmpty ? null : _onNext,
          onClose: () => context.pop(),
          child: Column(
            children: [
              SegmentedTabs<DebtType>(
                options: {
                  DebtType.lent: tr.lentReceivable,
                  DebtType.borrowed: tr.borrowedPayable,
                },
                value: _type,
                onChanged: (type) => setState(() => _type = type),
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
          title: tr.t('Who and when?', ne: 'कसलाई र कहिले?', es: '¿A quién y cuándo?', fr: 'À qui et quand ?', de: 'Wer und wann?', ja: '相手と期日', zh: '往来对象与日期', it: 'A chi e quando?'),
          subtitle: tr.t('Enter the party name, due date, and account cash flow.', ne: 'पार्टीको नाम, फिर्ता मिति र खाता सिंक विवरण प्रविष्ट गर्नुहोस्।', es: 'Ingresa nombre de la parte, vencimiento y flujo.', fr: 'Saisissez le nom, l\'échéance et le flux.', de: 'Name, Fälligkeit und Geldfluss erfassen.', ja: '相手の名前、期日、口座連携を設定してください。', zh: '输入对方姓名、还款期日及账户出入账关联。', it: 'Inserisci nome, data di scadenza e flusso.'),
          confirmClose: true,
          discardTitle: tr.discardThis,
          primaryLabel: _isSaving
              ? tr.t('Saving...', ne: 'सुरक्षित गर्दै...', es: 'Guardando...', fr: 'Enregistrement...', de: 'Speichern...', ja: '保存中...', zh: '正在保存...', it: 'Salvataggio...')
              : tr.t('Save Record', ne: 'रेकर्ड सेभ गर्नुहोस्', es: 'Guardar registro', fr: 'Enregistrer', de: 'Eintrag speichern', ja: '記録を保存', zh: '保存记录', it: 'Salva record'),
          onPrimary: (_partyController.text.trim().isEmpty || _isSaving) ? null : _save,
          onClose: () => context.pop(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Party name
              UnderlineField(
                controller: _partyController,
                label: tr.partyNameLabel,
                hint: tr.partyNameHint,
                autofocus: true,
                isRequired: true,
                errorText: _partyError,
                onChanged: (val) {
                  if (_partyError != null) setState(() => _partyError = null);
                  setState(() {});
                },
              ),

              // Existing party suggestions
              if (existingParties.isNotEmpty) ...[
                const SizedBox(height: AppSpace.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final party in existingParties.take(6))
                      InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        onTap: () {
                          setState(() {
                            _partyController.text = party;
                            _partyError = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(color: scheme.outlineVariant),
                          ),
                          child: Text(
                            party,
                            style: text.bodySmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpace.xl),

              // Due Date row
              AppCard(
                padding: EdgeInsets.zero,
                child: ListRow(
                  leading: const IconTile(HugeIcons.strokeRoundedCalendar01),
                  title: tr.duePrefix,
                  subtitle: _dueDate == null
                      ? tr.noFixedDateOptional
                      : AppDate.short(_dueDate!),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_dueDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () => setState(() => _dueDate = null),
                        ),
                      const Chevron(),
                    ],
                  ),
                  onTap: _pickDueDate,
                ),
              ),
              const SizedBox(height: AppSpace.lg),

              // Optional Interest Rate (%)
              UnderlineField(
                controller: _interestController,
                label: tr.interestRateOptional,
                hint: 'e.g. 5.0 for 5% annual',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: AppSpace.lg),

              // Optional Note
              UnderlineField(
                controller: _noteController,
                label: tr.noteOrReasonOptional,
                hint: tr.noteReasonHint,
              ),
              const SizedBox(height: AppSpace.xl),

              // Cash Flow Switch
              AppCard(
                padding: EdgeInsets.zero,
                child: SwitchRow(
                  title: tr.recordInEverydayAccount,
                  subtitle: _type == DebtType.lent
                      ? tr.deductEverydayBalanceNow
                      : tr.addEverydayBalanceNow,
                  value: _linkCashFlow,
                  onChanged: (val) => setState(() => _linkCashFlow = val),
                ),
              ),
            ],
          ),
        ),
    };
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
  final void Function(int convertedAmountMinor, double foreignAmount, String foreignCurrency, double rate) onApply;

  @override
  State<_CurrencyConverterSheet> createState() => _CurrencyConverterSheetState();
}

class _CurrencyConverterSheetState extends State<_CurrencyConverterSheet> {
  late String _selectedForeignCurrency;
  final _foreignAmountController = TextEditingController(text: '25.00');
  final Map<String, double> _liveServerRates = {};

  static const _supportedCurrencies = ['AUD', 'NPR', 'USD', 'INR', 'EUR', 'GBP'];

  @override
  void initState() {
    super.initState();
    _selectedForeignCurrency = widget.baseCurrency == 'NPR' ? 'AUD' : (widget.baseCurrency == 'AUD' ? 'USD' : 'NPR');
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

  double _getEffectiveRate() {
    final directPair = '${_selectedForeignCurrency}_${widget.baseCurrency}';
    if (_liveServerRates.containsKey(directPair)) {
      return _liveServerRates[directPair]!;
    }
    final inversePair = '${widget.baseCurrency}_$_selectedForeignCurrency';
    if (_liveServerRates.containsKey(inversePair) && _liveServerRates[inversePair]! != 0) {
      return 1.0 / _liveServerRates[inversePair]!;
    }

    for (final r in widget.rates) {
      if (r.baseCode == _selectedForeignCurrency && r.quoteCode == widget.baseCurrency) {
        return r.rate;
      }
      if (r.baseCode == widget.baseCurrency && r.quoteCode == _selectedForeignCurrency && r.rate > 0) {
        return 1.0 / r.rate;
      }
    }
    if (_selectedForeignCurrency == 'AUD' && widget.baseCurrency == 'NPR') return 93.42;
    if (_selectedForeignCurrency == 'USD' && widget.baseCurrency == 'NPR') return 142.60;
    if (_selectedForeignCurrency == 'INR' && widget.baseCurrency == 'NPR') return 1.60;
    if (_selectedForeignCurrency == 'USD' && widget.baseCurrency == 'AUD') return 1.52;
    if (_selectedForeignCurrency == 'EUR' && widget.baseCurrency == 'AUD') return 1.65;
    if (_selectedForeignCurrency == 'NPR' && widget.baseCurrency == 'AUD') return 1.0 / 93.42;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final tr = context.strings;
    final rate = _getEffectiveRate();

    final foreignAmount = double.tryParse(_foreignAmountController.text) ?? 0.0;
    final convertedAmount = foreignAmount * rate;
    final convertedMinor = (convertedAmount * 100).round();

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpace.lg,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: SafeArea(
        child: Padding(
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
                        Text(tr.currencyAssistant, style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          tr.t(
                            'Convert foreign amount directly into ${widget.baseCurrency}',
                            ne: 'विदेशी रकमलाई सिधै ${widget.baseCurrency} मा रूपान्तरण गर्नुहोस्',
                            es: 'Convierte divisas directamente a ${widget.baseCurrency}',
                            fr: 'Convertir le montant étranger directement en ${widget.baseCurrency}',
                            de: 'Fremdwährungsbetrag direkt in ${widget.baseCurrency} umrechnen',
                            ja: '外貨を直接${widget.baseCurrency}に換算',
                            zh: '直接将外币金额换算为 ${widget.baseCurrency}',
                            it: 'Converti valuta estera in ${widget.baseCurrency}',
                          ),
                          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
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
                          if (selected) setState(() => _selectedForeignCurrency = code);
                        },
                      ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              TextField(
                controller: _foreignAmountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: text.headlineSmall,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: tr.amountInCurrency(_selectedForeignCurrency),
                  prefixText: '${Currency.fromCode(_selectedForeignCurrency).symbol} ',
                  border: const OutlineInputBorder(),
                  hintText: tr.localizeDigits('25.00'),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Container(
                padding: const EdgeInsets.all(AppSpace.md),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(tr.rateLabel, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                        Text(
                          tr.localizeDigits('1 $_selectedForeignCurrency = ${rate.toStringAsFixed(2)} ${widget.baseCurrency}'),
                          style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(tr.convertedInBase(widget.baseCurrency), style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
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
              AppButton(
                tr.t(
                  'Apply ${Currency.fromCode(widget.baseCurrency).symbol} ${convertedAmount.toStringAsFixed(2)}',
                  ne: '${Currency.fromCode(widget.baseCurrency).symbol} ${tr.localizeDigits(convertedAmount.toStringAsFixed(2))} लागू गर्नुहोस्',
                  es: 'Aplicar ${Currency.fromCode(widget.baseCurrency).symbol} ${convertedAmount.toStringAsFixed(2)}',
                  fr: 'Appliquer ${Currency.fromCode(widget.baseCurrency).symbol} ${convertedAmount.toStringAsFixed(2)}',
                  de: '${Currency.fromCode(widget.baseCurrency).symbol} ${convertedAmount.toStringAsFixed(2)} übernehmen',
                  ja: '${Currency.fromCode(widget.baseCurrency).symbol} ${convertedAmount.toStringAsFixed(2)} を適用',
                  zh: '应用 ${Currency.fromCode(widget.baseCurrency).symbol} ${convertedAmount.toStringAsFixed(2)}',
                  it: 'Applica ${Currency.fromCode(widget.baseCurrency).symbol} ${convertedAmount.toStringAsFixed(2)}',
                ),
                onPressed: foreignAmount <= 0
                    ? null
                    : () {
                        widget.onApply(convertedMinor, foreignAmount, _selectedForeignCurrency, rate);
                        Navigator.of(context).pop();
                      },
              ),
              const SizedBox(height: AppSpace.sm),
            ],
          ),
        ),
      ),
    );
  }
}
