import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/settings/viewmodels/settings_view_model.dart';
import 'package:finance_tracker/features/shared/data/currency.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class CurrencySettingsScreen extends StatefulWidget {
  const CurrencySettingsScreen({super.key});

  @override
  State<CurrencySettingsScreen> createState() => _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState extends State<CurrencySettingsScreen> {
  bool _isSwitching = false;

  Future<void> _handleCurrencySelect(
    SettingsViewModel viewModel,
    Currency cur,
  ) async {
    if (_isSwitching) return;
    if (viewModel.baseCurrency == cur.code) {
      context.pop();
      return;
    }

    final tr = context.strings;
    setState(() => _isSwitching = true);

    final error = await viewModel.switchBaseCurrencyWithConversion(cur.code);
    if (!mounted) return;
    setState(() => _isSwitching = false);

    if (error == 'NO_INTERNET') {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          insetPadding: const EdgeInsets.all(AppSpace.xl),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const IconTile(HugeIcons.strokeRoundedWifi01, size: 40),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Text(
                        tr.internetRequired,
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                Text(
                  tr.internetRequiredDesc,
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppSpace.xl),
                AppButton(
                  tr.gotIt,
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (error != null) {
      if (!mounted) return;
      showToast(context, error);
    } else {
      if (!mounted) return;
      showToast(
        context,
        '${cur.name} (${cur.code})',
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<SettingsViewModel>();
    final text = Theme.of(context).textTheme;
    final tr = context.strings;

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppTopBar(
            title: tr.currency,
            subtitle: tr.chooseDefaultCurrency,
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.page,
                vertical: AppSpace.md,
              ),
              children: [
                Text(
                  tr.baseCurrency,
                  style: text.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                if (_isSwitching)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpace.md),
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  ),
                HorizontalOptionSelector<String>(
                  height: 64,
                  selectedValue: viewModel.baseCurrency,
                  onChanged: (code) {
                    final selectedCur = Currency.supported.firstWhere((c) => c.code == code);
                    _handleCurrencySelect(viewModel, selectedCur);
                  },
                  items: [
                    for (final cur in Currency.supported)
                      HorizontalOptionItem<String>(
                        value: cur.code,
                        label: '${cur.symbolForLocale(viewModel.localeCode)} · ${cur.code}',
                        subtitle: cur.name,
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
