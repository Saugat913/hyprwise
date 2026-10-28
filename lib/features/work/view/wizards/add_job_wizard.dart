import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';
import 'package:finance_tracker/features/work/viewmodels/work_view_model.dart';

class _JobSuggestionItem {
  const _JobSuggestionItem(this.label, this.icon);
  final String label;
  final IconGlyph icon;
}

class AddJobWizard extends StatefulWidget {
  const AddJobWizard({super.key});

  @override
  State<AddJobWizard> createState() => _AddJobWizardState();
}

class _AddJobWizardState extends State<AddJobWizard> {
  int _step = 0;
  final _nameController = TextEditingController();
  final _rateController = TextEditingController(text: '25.00');

  String _payType = 'hourly';
  final Set<int> _selectedDays = {1, 5}; // Monday and Friday default
  String? _nameError;
  String? _rateError;

  List<_JobSuggestionItem> _getJobSuggestions(AppStrings tr) => [
    _JobSuggestionItem(tr.jobCafe, HugeIcons.strokeRoundedCoffee01),
    _JobSuggestionItem(tr.jobWarehouse, HugeIcons.strokeRoundedPackage),
    _JobSuggestionItem(tr.jobTutoring, HugeIcons.strokeRoundedBook01),
    _JobSuggestionItem(tr.jobDelivery, HugeIcons.strokeRoundedDeliveryBox01),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _onNext() {
    final tr = context.strings;
    if (_step == 0) {
      if (_nameController.text.trim().isEmpty) {
        setState(() => _nameError = tr.enterJobNameError);
        showErrorToast(context, tr.enterJobNameError);
        return;
      }
      setState(() {
        _nameError = null;
        _step = 1;
      });
    } else if (_step == 1) {
      final rate = double.tryParse(_rateController.text.trim()) ?? 0;
      if (rate <= 0) {
        setState(() => _rateError = tr.enterValidRateError);
        showErrorToast(context, tr.enterValidRateError);
        return;
      }
      setState(() {
        _rateError = null;
        _step = 2;
      });
    } else {
      _save();
    }
  }

  Future<void> _save() async {
    final tr = context.strings;
    final viewModel = getIt<WorkViewModel>();
    final rateDouble = double.tryParse(_rateController.text.trim()) ?? 25.0;
    final rateMinor = (rateDouble * 100).round();

    await viewModel.addJob(
      name: _nameController.text.trim(),
      hourlyRateMinor: rateMinor,
    );

    if (mounted) {
      showToast(context, tr.jobSaved, actionLabel: tr.view);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tr = context.strings;
    final currency = getIt<WorkViewModel>().baseCurrency;
    final jobSuggestions = _getJobSuggestions(tr);

    return switch (_step) {
      0 => WizardScaffold(
          step: 0,
          steps: 3,
          title: tr.whatIsJobCalled,
          subtitle: tr.recogniseAtGlance,
          confirmClose: true,
          discardTitle: tr.discardThis,
          primaryLabel: tr.next,
          onPrimary: _nameController.text.trim().isNotEmpty ? _onNext : null,
          onClose: () => context.pop(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UnderlineField(
                label: tr.jobName,
                hint: tr.jobNameHint,
                controller: _nameController,
                autofocus: true,
                isRequired: true,
                errorText: _nameError,
                onChanged: (_) {
                  if (_nameError != null) setState(() => _nameError = null);
                  setState(() {});
                },
              ),
              const SizedBox(height: AppSpace.xl),
              Text(
                tr.suggestions,
                style: text.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpace.sm,
                  mainAxisSpacing: AppSpace.sm,
                  childAspectRatio: 2.2,
                ),
                itemCount: jobSuggestions.length,
                itemBuilder: (context, index) {
                  final s = jobSuggestions[index];
                  final isSelected = _nameController.text.trim().toLowerCase() == s.label.toLowerCase();
                  return _JobSuggestionCard(
                    label: s.label,
                    icon: s.icon,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _nameController.text = s.label;
                      });
                    },
                  );
                },
              ),
            ],
          ),
        ),
      1 => WizardScaffold(
          step: 1,
          steps: 3,
          title: tr.howDoYouGetPaid,
          subtitle: tr.keepsForecastsAccurate,
          onBack: () => setState(() => _step = 0),
          onClose: () => context.pop(),
          confirmClose: true,
          discardTitle: tr.discardThis,
          primaryLabel: tr.next,
          onPrimary: _rateController.text.trim().isEmpty ? null : _onNext,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OptionTile(
                title: tr.hourly,
                subtitle: tr.paidForHoursWorked,
                selected: _payType == 'hourly',
                onTap: () => setState(() => _payType = 'hourly'),
              ),
              const SizedBox(height: AppSpace.sm),
              OptionTile(
                title: tr.perShift,
                subtitle: tr.sameAmountEveryShift,
                selected: _payType == 'shift',
                onTap: () => setState(() => _payType = 'shift'),
              ),
              const SizedBox(height: AppSpace.sm),
              OptionTile(
                title: tr.salary,
                subtitle: tr.fixedAmountEachPayPeriod,
                selected: _payType == 'salary',
                onTap: () => setState(() => _payType = 'salary'),
              ),
              const SizedBox(height: AppSpace.xl),
              UnderlineField(
                label: tr.rate,
                hint: '$currency 25.00',
                controller: _rateController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                isRequired: true,
                errorText: _rateError,
                onChanged: (_) {
                  if (_rateError != null) setState(() => _rateError = null);
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      _ => WizardScaffold(
          step: 2,
          steps: 3,
          title: tr.whichDaysUsuallyWork,
          subtitle: tr.pickDaysTimesPerShift,
          onBack: () => setState(() => _step = 1),
          onClose: () => context.pop(),
          confirmClose: true,
          discardTitle: tr.discardThis,
          primaryLabel: tr.saveJob,
          onPrimary: _save,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: AppSpace.sm,
                  mainAxisSpacing: AppSpace.sm,
                  childAspectRatio: 1.5,
                ),
                itemCount: 7,
                itemBuilder: (context, i) {
                  // i: 0 -> Sun (7), 1 -> Mon (1), 2 -> Tue (2), etc.
                  final dayIndex = i == 0 ? 7 : i;
                  final dayLabel = tr.weekdayShort(dayIndex);
                  final isSelected = _selectedDays.contains(i);
                  return _WeekdayGridCard(
                    label: dayLabel,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        if (_selectedDays.contains(i)) {
                          _selectedDays.remove(i);
                        } else {
                          _selectedDays.add(i);
                        }
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: AppSpace.xl),
              Text(
                tr.t(
                  '${_selectedDays.length} ${_selectedDays.length == 1 ? "day" : "days"} selected per week',
                  ne: 'हप्तामा ${_selectedDays.length} दिन छानिएका छन्',
                  es: '${_selectedDays.length} días seleccionados por semana',
                  fr: '${_selectedDays.length} jours sélectionnés par semaine',
                  de: '${_selectedDays.length} Tage pro Woche ausgewählt',
                  ja: '週に ${_selectedDays.length} 日選択中',
                  zh: '每周已选择 ${_selectedDays.length} 天',
                  it: '${_selectedDays.length} giorni a settimana selezionati',
                ),
                style: text.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
    };
  }
}

class _JobSuggestionCard extends StatelessWidget {
  const _JobSuggestionCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconGlyph icon;
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
            color: isSelected ? scheme.primary.withValues(alpha: 0.1) : scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected ? scheme.primary : scheme.outlineVariant,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xs),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? scheme.primary : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                alignment: Alignment.center,
                child: AppIcon(
                  icon,
                  size: 18,
                  color: isSelected ? scheme.onPrimary : scheme.primary,
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? scheme.primary : scheme.onSurface,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, size: 16, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekdayGridCard extends StatelessWidget {
  const _WeekdayGridCard({
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
    final text = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isSelected ? scheme.primary : scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected ? scheme.primary : scheme.outlineVariant,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs, vertical: AppSpace.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: text.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isSelected ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? scheme.onPrimary : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
