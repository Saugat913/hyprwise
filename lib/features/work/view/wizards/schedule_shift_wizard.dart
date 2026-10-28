import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';
import 'package:finance_tracker/features/work/view/widgets/shift_rate_slider_protocol.dart';
import 'package:finance_tracker/features/work/viewmodels/work_view_model.dart';

enum _ScheduleMode { recurring, specificDates }

class ScheduleShiftWizard extends StatefulWidget {
  const ScheduleShiftWizard({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  State<ScheduleShiftWizard> createState() => _ScheduleShiftWizardState();
}

class _ScheduleShiftWizardState extends State<ScheduleShiftWizard> {
  int _step = 0;
  int? _jobId;
  _ScheduleMode _mode = _ScheduleMode.recurring;

  // Recurring schedule state
  final Set<int> _selectedWeekdays = {1, 3, 5}; // Mon, Wed, Fri
  int _repeatWeeks = 12; // 3 months default

  // Specific dates state
  final Set<DateTime> _selectedDates = {AppDate.dateOnly(DateTime.now())};

  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  bool _fixedEnd = true;
  int _breakMinutes = 30;
  bool _useCustomBreak = false;
  int _longShiftAlertMinutes = 360;
  bool _useCustomAlertHours = false;
  final _customBreakController = TextEditingController();
  final _customAlertHoursController = TextEditingController();
  ShiftRateConfig? _rateConfig;

  static const _horizonOptions = {
    2: '2 weeks',
    4: '4 weeks (1 mo)',
    8: '8 weeks (2 mo)',
    12: '12 weeks (3 mo)',
    26: '26 weeks (6 mo)',
    52: '52 weeks (1 yr)',
  };

  @override
  void initState() {
    super.initState();
    final vm = getIt<WorkViewModel>();
    if (vm.jobs.isNotEmpty) {
      final first = vm.jobs.first;
      _jobId = first.id;
      _breakMinutes = first.defaultBreakMinutes;
      _longShiftAlertMinutes = first.longShiftAlertMinutes;
    }
    if (widget.initialDate != null) {
      _mode = _ScheduleMode.specificDates;
      _selectedDates.clear();
      _selectedDates.add(AppDate.dateOnly(widget.initialDate!));
    }
  }

  @override
  void dispose() {
    _customBreakController.dispose();
    _customAlertHoursController.dispose();
    super.dispose();
  }

  void _toggleWeekday(int day) {
    setState(() {
      if (_selectedWeekdays.contains(day)) {
        if (_selectedWeekdays.length > 1) {
          _selectedWeekdays.remove(day);
        }
      } else {
        _selectedWeekdays.add(day);
      }
    });
  }

  void _toggleDate(DateTime day) {
    final d = AppDate.dateOnly(day);
    setState(() {
      if (_selectedDates.contains(d)) {
        if (_selectedDates.length > 1) {
          _selectedDates.remove(d);
        }
      } else {
        _selectedDates.add(d);
      }
    });
  }

  void _selectPreset(String preset) {
    final today = AppDate.dateOnly(DateTime.now());
    setState(() {
      _selectedDates.clear();
      switch (preset) {
        case 'today':
          _selectedDates.add(today);
          break;
        case 'tomorrow':
          _selectedDates.add(today.add(const Duration(days: 1)));
          break;
        case 'weekdays':
          for (var i = 0; i < 7; i++) {
            final day = today.add(Duration(days: i));
            if (day.weekday <= 5) _selectedDates.add(day);
          }
          break;
        case 'next7':
          for (var i = 0; i < 7; i++) {
            _selectedDates.add(today.add(Duration(days: i)));
          }
          break;
      }
    });
  }

  int get _calculatedRecurringCount {
    var count = 0;
    final now = DateTime.now();
    final totalDays = _repeatWeeks * 7;
    for (var i = 0; i < totalDays; i++) {
      final date = now.add(Duration(days: i));
      if (_selectedWeekdays.contains(date.weekday)) count++;
    }
    return count;
  }

  int get _totalShiftCount => _mode == _ScheduleMode.recurring
      ? _calculatedRecurringCount
      : _selectedDates.length;

  double get _hoursPerShift {
    if (!_fixedEnd) return 4.0;
    final startMin = _startTime.hour * 60 + _startTime.minute;
    var endMin = _endTime.hour * 60 + _endTime.minute;
    if (endMin <= startMin) endMin += 24 * 60; // overnight
    final workedMin = (endMin - startMin) - _breakMinutes;
    return workedMin > 0 ? workedMin / 60.0 : 0.0;
  }

  void _onNext() {
    if (_step == 0) {
      if (_jobId == null) return;
      setState(() => _step = 1);
    } else if (_step == 1) {
      if (_mode == _ScheduleMode.recurring && _selectedWeekdays.isEmpty) return;
      if (_mode == _ScheduleMode.specificDates && _selectedDates.isEmpty) return;
      setState(() => _step = 2);
    } else {
      _save();
    }
  }

  Future<void> _save() async {
    if (_jobId == null) return;
    final viewModel = getIt<WorkViewModel>();
    final selectedJob = viewModel.jobsById[_jobId];

    final effectiveRateMinor = (_rateConfig != null && selectedJob != null)
        ? _rateConfig!.getRateOverrideMinor(
            baseHourlyRateMinor: selectedJob.hourlyRateMinor,
            durationHours: _hoursPerShift,
          )
        : null;
    final otThresholdMin = _rateConfig?.overtimeThresholdMinutes;
    final otRateMinor = _rateConfig?.overtimeRateMinor;

    List<int> createdIds = [];

    if (_mode == _ScheduleMode.recurring) {
      createdIds = await viewModel.scheduleRecurringShifts(
        jobId: _jobId!,
        weekdays: _selectedWeekdays,
        startTime: _startTime,
        endTime: _endTime,
        weeksCount: _repeatWeeks,
        breakMinutes: _breakMinutes,
        rateOverrideMinor: effectiveRateMinor,
        overtimeThresholdMinutes: otThresholdMin,
        overtimeRateMinor: otRateMinor,
        longShiftAlertMinutes: _longShiftAlertMinutes,
      );
    } else {
      for (final date in _selectedDates) {
        final startAt = DateTime(
          date.year,
          date.month,
          date.day,
          _startTime.hour,
          _startTime.minute,
        );

        DateTime? endAt;
        if (_fixedEnd) {
          final isNextDay = (_endTime.hour < _startTime.hour) ||
              (_endTime.hour == _startTime.hour && _endTime.minute <= _startTime.minute);
          final endBaseDate = isNextDay ? date.add(const Duration(days: 1)) : date;
          endAt = DateTime(
            endBaseDate.year,
            endBaseDate.month,
            endBaseDate.day,
            _endTime.hour,
            _endTime.minute,
          );
        }

        final id = await viewModel.scheduleShift(
          jobId: _jobId!,
          startAt: startAt,
          endAt: endAt,
          breakMinutes: _breakMinutes,
          rateOverrideMinor: effectiveRateMinor,
          overtimeThresholdMinutes: otThresholdMin,
          overtimeRateMinor: otRateMinor,
          longShiftAlertMinutes: _longShiftAlertMinutes,
        );
        createdIds.add(id);
      }
    }

    if (mounted) {
      final tr = context.strings;
      final count = createdIds.length;
      showToast(
        context,
        tr.shiftsScheduled(count),
        actionLabel: tr.undo,
        onAction: () async {
          for (final id in createdIds) {
            await viewModel.shiftRepo.delete(id);
          }
        },
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<WorkViewModel>();
    final jobs = viewModel.jobs;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final tr = context.strings;

    if (jobs.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
          title: Text(tr.scheduleShift),
        ),
        body: SafeArea(
          child: EmptyState(
            icon: HugeIcons.strokeRoundedBriefcase01,
            title: tr.noJobsYet,
            message: tr.addJobBeforeShift,
            actionLabel: tr.addJob,
            onAction: () async {
              await context.push(AppRoutes.addJob);
              final updatedJobs = getIt<WorkViewModel>().jobs;
              if (mounted && updatedJobs.isNotEmpty) {
                setState(() {
                  _jobId = updatedJobs.first.id;
                });
              }
            },
          ),
        ),
      );
    }

    final selectedJob = viewModel.jobsById[_jobId];

    return switch (_step) {
      0 => WizardScaffold(
          step: 0,
          steps: 3,
          title: tr.whichJobForShift,
          subtitle: tr.pickOne,
          primaryLabel: tr.next,
          onPrimary: _jobId != null ? _onNext : null,
          onClose: () => context.pop(),
          child: Column(
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpace.sm,
                  mainAxisSpacing: AppSpace.sm,
                  childAspectRatio: 1.35,
                ),
                itemCount: jobs.length + 1,
                itemBuilder: (context, index) {
                  if (index == jobs.length) {
                    return _AddJobCard(
                      onTap: () async {
                        await context.push(AppRoutes.addJob);
                        final updatedJobs = getIt<WorkViewModel>().jobs;
                        if (mounted && updatedJobs.isNotEmpty) {
                          setState(() {
                            _jobId = updatedJobs.last.id;
                          });
                        }
                      },
                    );
                  }
                  final job = jobs[index];
                  final isSelected = _jobId == job.id;
                  return _JobWorkCard(
                    job: job,
                    isSelected: isSelected,
                    onTap: () => setState(() {
                      _jobId = job.id;
                      _breakMinutes = job.defaultBreakMinutes;
                      _useCustomBreak = ![0, 15, 30, 45, 60].contains(job.defaultBreakMinutes);
                      if (_useCustomBreak) {
                        _customBreakController.text = job.defaultBreakMinutes.toString();
                      }
                      _longShiftAlertMinutes = job.longShiftAlertMinutes;
                      _useCustomAlertHours = ![0, 240, 360, 480, 600, 720].contains(job.longShiftAlertMinutes);
                      if (_useCustomAlertHours) {
                        _customAlertHoursController.text = (job.longShiftAlertMinutes / 60).toStringAsFixed(0);
                      }
                    }),
                  );
                },
              ),
            ],
          ),
        ),
      1 => WizardScaffold(
          step: 1,
          steps: 3,
          title: tr.scheduleRoster,
          subtitle: _mode == _ScheduleMode.recurring
              ? tr.t(
                  '$_calculatedRecurringCount shifts will be scheduled across $_repeatWeeks weeks.',
                  ne: '$_repeatWeeks हप्तामा $_calculatedRecurringCount सिफ्टहरू तय हुनेछन्।',
                  es: '$_calculatedRecurringCount turnos se programarán en $_repeatWeeks semanas.',
                  fr: '$_calculatedRecurringCount quarts seront planifiés sur $_repeatWeeks semaines.',
                  de: '$_calculatedRecurringCount Schichten werden über $_repeatWeeks Wochen geplant.',
                  ja: '$_repeatWeeks 週間にわたり $_calculatedRecurringCount 件のシフトが計画されます。',
                  zh: '将在 $_repeatWeeks 周内安排 $_calculatedRecurringCount 个班次。',
                  it: '$_calculatedRecurringCount turni saranno programmati su $_repeatWeeks settimane.',
                )
              : tr.t(
                  '${_selectedDates.length} ${_selectedDates.length == 1 ? "day" : "days"} selected.',
                  ne: '${_selectedDates.length} दिनहरू छानिएका छन्।',
                  es: '${_selectedDates.length} días seleccionados.',
                  fr: '${_selectedDates.length} jours sélectionnés.',
                  de: '${_selectedDates.length} Tage ausgewählt.',
                  ja: '${_selectedDates.length} 日が選択されました。',
                  zh: '已选择 ${_selectedDates.length} 天。',
                  it: '${_selectedDates.length} giorni selezionati.',
                ),
          onBack: () => setState(() => _step = 0),
          onClose: () => context.pop(),
          primaryLabel: tr.next,
          onPrimary: (_mode == _ScheduleMode.recurring && _selectedWeekdays.isNotEmpty) ||
                  (_mode == _ScheduleMode.specificDates && _selectedDates.isNotEmpty)
              ? _onNext
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mode switcher
              SegmentedTabs<_ScheduleMode>(
                options: {
                  _ScheduleMode.recurring: tr.weeklyRecurring,
                  _ScheduleMode.specificDates: tr.specificDates,
                },
                value: _mode,
                onChanged: (val) => setState(() => _mode = val),
              ),
              const SizedBox(height: AppSpace.lg),

              if (_mode == _ScheduleMode.recurring) ...[
                Text(
                  tr.whichWeekdaysWork,
                  style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpace.sm),
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
                  itemBuilder: (context, index) {
                    final dayNumber = index + 1;
                    final label = tr.weekdayShort(dayNumber);
                    final isSelected = _selectedWeekdays.contains(dayNumber);
                    return _WeekdayCard(
                      label: label,
                      isSelected: isSelected,
                      onTap: () => _toggleWeekday(dayNumber),
                    );
                  },
                ),
                const SizedBox(height: AppSpace.xl),

                Text(
                  tr.howManyWeeksSchedule,
                  style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpace.sm),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: AppSpace.sm,
                    mainAxisSpacing: AppSpace.sm,
                    childAspectRatio: 1.8,
                  ),
                  itemCount: _horizonOptions.length,
                  itemBuilder: (context, index) {
                    final entry = _horizonOptions.entries.elementAt(index);
                    final isSelected = _repeatWeeks == entry.key;
                    return _OptionGridCard(
                      label: tr.horizonOption(entry.key),
                      isSelected: isSelected,
                      onTap: () => setState(() => _repeatWeeks = entry.key),
                    );
                  },
                ),
                const SizedBox(height: AppSpace.xl),

                Container(
                  padding: const EdgeInsets.all(AppSpace.md),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 20),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: Text(
                          tr.t(
                            '${_selectedWeekdays.length} days/week automatically scheduled for the next $_repeatWeeks weeks ($_calculatedRecurringCount shifts total).',
                            ne: 'हप्तामा ${_selectedWeekdays.length} दिन आगामी $_repeatWeeks हप्ताका लागि स्वतः तय (जम्मा $_calculatedRecurringCount सिफ्टहरू)।',
                            es: '${_selectedWeekdays.length} días/sem programados para las próximas $_repeatWeeks semanas ($_calculatedRecurringCount turnos total).',
                            fr: '${_selectedWeekdays.length} jours/semaine planifiés sur $_repeatWeeks semaines ($_calculatedRecurringCount quarts au total).',
                            de: '${_selectedWeekdays.length} Tage/Woche geplant für die nächsten $_repeatWeeks Wochen ($_calculatedRecurringCount Schichten gesamt).',
                            ja: '今後 $_repeatWeeks 週間にわたり週 ${_selectedWeekdays.length} 日を自動計画（計 $_calculatedRecurringCount シフト）。',
                            zh: '未来 $_repeatWeeks 周每周自动排班 ${_selectedWeekdays.length} 天（共 $_calculatedRecurringCount 个班次）。',
                            it: '${_selectedWeekdays.length} giorni a settimana pianificati per le prossime $_repeatWeeks settimane ($_calculatedRecurringCount turni totali).',
                          ),
                          style: text.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Presets
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoicePill(
                        tr.today,
                        selected: _selectedDates.length == 1 &&
                            _selectedDates.contains(AppDate.dateOnly(DateTime.now())),
                        onTap: () => _selectPreset('today'),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      ChoicePill(
                        tr.tomorrow,
                        selected: _selectedDates.length == 1 &&
                            _selectedDates.contains(AppDate.dateOnly(DateTime.now().add(const Duration(days: 1)))),
                        onTap: () => _selectPreset('tomorrow'),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      ChoicePill(
                        tr.weekdaysLabel,
                        selected: false,
                        onTap: () => _selectPreset('weekdays'),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      ChoicePill(
                        tr.next7Days,
                        selected: _selectedDates.length == 7,
                        onTap: () => _selectPreset('next7'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.lg),

                // 14-day interactive grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: AppSpace.sm,
                    mainAxisSpacing: AppSpace.sm,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: 14,
                  itemBuilder: (context, i) {
                    final day = DateTime.now().add(Duration(days: i));
                    final isSelected = _selectedDates.contains(AppDate.dateOnly(day));
                    final shortDay = tr.weekdayShort(day.weekday);
                    return _OptionGridCard(
                      label: '$shortDay ${tr.formatNumber(day.day)}',
                      isSelected: isSelected,
                      onTap: () => _toggleDate(day),
                    );
                  },
                ),
                const SizedBox(height: AppSpace.xl),

                // Custom Date Picker button
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDates.add(AppDate.dateOnly(picked));
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(tr.pickDateFromCalendar),
                ),
              ],
            ],
          ),
        ),
      _ => WizardScaffold(
          step: 2,
          steps: 3,
          title: tr.whatTimeAreShifts,
          subtitle: '${selectedJob?.name ?? tr.work} · ${tr.formatNumber(_totalShiftCount)} ${tr.shiftsOnly.toLowerCase()}',
          onBack: () => setState(() => _step = 1),
          onClose: () => context.pop(),
          confirmClose: true,
          discardTitle: tr.discardThis,
          primaryLabel: tr.shiftsScheduled(_totalShiftCount),
          onPrimary: _save,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showTimePicker(context: context, initialTime: _startTime);
                        if (picked != null) setState(() => _startTime = picked);
                      },
                      child: Text('${tr.starts}: ${AppDate.timeOnly(DateTime(2000, 1, 1, _startTime.hour, _startTime.minute))}'),
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  if (_fixedEnd)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showTimePicker(context: context, initialTime: _endTime);
                          if (picked != null) setState(() => _endTime = picked);
                        },
                        child: Text('${tr.ends}: ${AppDate.timeOnly(DateTime(2000, 1, 1, _endTime.hour, _endTime.minute))}'),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),

              Text(tr.breakDuration, style: text.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpace.xs),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.xs,
                children: [
                  for (final b in [0, 15, 30, 45, 60])
                    ChoicePill(
                      b == 0 ? tr.noBreak : tr.minsBreak(b),
                      selected: !_useCustomBreak && _breakMinutes == b,
                      onTap: () => setState(() {
                        _useCustomBreak = false;
                        _breakMinutes = b;
                      }),
                    ),
                  ChoicePill(
                    tr.customOption,
                    selected: _useCustomBreak,
                    onTap: () => setState(() {
                      _useCustomBreak = true;
                      if (_customBreakController.text.isEmpty) {
                        _customBreakController.text = _breakMinutes.toString();
                      }
                    }),
                  ),
                ],
              ),
              if (_useCustomBreak) ...[
                const SizedBox(height: AppSpace.sm),
                UnderlineField(
                  label: tr.customBreakMinutesLabel,
                  hint: '20',
                  controller: _customBreakController,
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    final parsed = int.tryParse(val.trim());
                    if (parsed != null && parsed >= 0) {
                      setState(() => _breakMinutes = parsed);
                    }
                  },
                ),
              ],
              const SizedBox(height: AppSpace.lg),

              // Selectable Long-Shift Notification Threshold
              Text(tr.longShiftNotificationLabel, style: text.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpace.xs),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.xs,
                children: [
                  ChoicePill(
                    tr.offOption,
                    selected: !_useCustomAlertHours && _longShiftAlertMinutes == 0,
                    onTap: () => setState(() {
                      _useCustomAlertHours = false;
                      _longShiftAlertMinutes = 0;
                    }),
                  ),
                  for (final h in [4, 6, 8, 10, 12])
                    ChoicePill(
                      tr.notifyAfterHours(h),
                      selected: !_useCustomAlertHours && _longShiftAlertMinutes == h * 60,
                      onTap: () => setState(() {
                        _useCustomAlertHours = false;
                        _longShiftAlertMinutes = h * 60;
                      }),
                    ),
                  ChoicePill(
                    tr.customOption,
                    selected: _useCustomAlertHours,
                    onTap: () => setState(() {
                      _useCustomAlertHours = true;
                      if (_customAlertHoursController.text.isEmpty) {
                        final curH = _longShiftAlertMinutes > 0 ? (_longShiftAlertMinutes / 60).round() : 6;
                        _customAlertHoursController.text = curH.toString();
                        _longShiftAlertMinutes = curH * 60;
                      }
                    }),
                  ),
                ],
              ),
              if (_useCustomAlertHours) ...[
                const SizedBox(height: AppSpace.sm),
                UnderlineField(
                  label: tr.customHoursLabel,
                  hint: '6',
                  controller: _customAlertHoursController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (val) {
                    final parsed = double.tryParse(val.trim());
                    if (parsed != null && parsed >= 0) {
                      setState(() => _longShiftAlertMinutes = (parsed * 60).round());
                    }
                  },
                ),
              ],
              const SizedBox(height: AppSpace.lg),

              SwitchRow(
                title: tr.fixedEnd,
                subtitle: _fixedEnd ? tr.shiftEndsAutomatically : tr.shiftContinuesUntilEnd,
                value: _fixedEnd,
                onChanged: (val) => setState(() => _fixedEnd = val),
              ),
              const SizedBox(height: AppSpace.lg),

              // Shift Hourly Rate & Overtime Slider Protocol
              if (selectedJob != null) ...[
                ShiftRateSliderProtocol(
                  baseHourlyRateMinor: selectedJob.hourlyRateMinor,
                  currencyCode: selectedJob.currencyCode,
                  shiftDurationHours: _hoursPerShift,
                  initialConfig: _rateConfig,
                  onChanged: (config) {
                    setState(() => _rateConfig = config);
                  },
                ),
                const SizedBox(height: AppSpace.lg),
              ],

              // Live summary calculation card
              if (selectedJob != null) ...[
                () {
                  final activeRateMinor = (_rateConfig != null && _rateConfig!.isCustom)
                      ? _rateConfig!.calculateEffectiveHourlyRateMinor(
                          baseHourlyRateMinor: selectedJob.hourlyRateMinor,
                          durationHours: _hoursPerShift,
                        )
                      : selectedJob.hourlyRateMinor;
                  final estPerShift = (_hoursPerShift * activeRateMinor).round();
                  final totalEst = estPerShift * _totalShiftCount;

                  return Container(
                    padding: const EdgeInsets.all(AppSpace.md),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(tr.hoursPerShift, style: text.bodySmall),
                            Text('${tr.localizeDigits(_hoursPerShift.toStringAsFixed(1))} ${tr.hoursUnit}', style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(tr.estPayPerShift, style: text.bodySmall),
                            Text(
                              MoneyFormatter.format(estPerShift, selectedJob.currencyCode),
                              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const Divider(height: AppSpace.lg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(tr.totalProjectedEarnings, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                            Text(
                              MoneyFormatter.format(totalEst, selectedJob.currencyCode),
                              style: text.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }(),
              ],
            ],
          ),
        ),
    };
  }
}

class _JobWorkCard extends StatelessWidget {
  const _JobWorkCard({
    required this.job,
    required this.isSelected,
    required this.onTap,
  });

  final Job job;
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
            color: isSelected ? scheme.primary.withValues(alpha: 0.08) : scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected ? scheme.primary : scheme.outlineVariant,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          padding: const EdgeInsets.all(AppSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
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
                      HugeIcons.strokeRoundedBriefcase01,
                      size: 16,
                      color: isSelected ? scheme.onPrimary : scheme.primary,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Icon(Icons.check_circle, size: 18, color: scheme.primary),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                job.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isSelected ? scheme.primary : scheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${MoneyFormatter.format(job.hourlyRateMinor, job.currencyCode)} / ${context.strings.hourAbbr}',
                style: text.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddJobCard extends StatelessWidget {
  const _AddJobCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final tr = context.strings;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: scheme.outlineVariant,
            ),
          ),
          padding: const EdgeInsets.all(AppSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                alignment: Alignment.center,
                child: AppIcon(
                  HugeIcons.strokeRoundedAdd01,
                  size: 16,
                  color: scheme.primary,
                ),
              ),
              const Spacer(),
              Text(
                tr.addNewJob,
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: scheme.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                tr.createWorkspace,
                style: text.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekdayCard extends StatelessWidget {
  const _WeekdayCard({
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

class _OptionGridCard extends StatelessWidget {
  const _OptionGridCard({
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
            color: isSelected ? scheme.primary.withValues(alpha: 0.1) : scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected ? scheme.primary : scheme.outlineVariant,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xs),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: text.labelSmall?.copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? scheme.primary : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
