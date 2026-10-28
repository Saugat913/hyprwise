import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/notifications/reminder_planner.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/alerts/viewmodels/alerts_view_model.dart';
import 'package:finance_tracker/features/settings/data/repository/reminder_rule_repository.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  String _formatTimeMinutes(BuildContext context, int minutes) {
    final tod = TimeOfDay(hour: (minutes ~/ 60) % 24, minute: minutes % 60);
    return tod.format(context);
  }

  String _repeatDaysSummary(int mask, AppStrings tr) {
    if (mask == 0 || mask == 0x7F) return tr.everyDay;
    final days = <String>[];
    for (var d = 1; d <= 7; d++) {
      if (ReminderPlanner.weekdayInMask(mask, d)) {
        days.add(tr.weekdayShort(d));
      }
    }
    return days.join(', ');
  }

  String _ruleTypeLabel(ReminderType type, AppStrings tr) => switch (type) {
        ReminderType.shift => tr.shiftLabel,
        ReminderType.bill => tr.billsDueTitle,
        ReminderType.debt => tr.debts,
        ReminderType.custom => tr.customOption,
      };

  dynamic _ruleTypeIcon(ReminderType type) => switch (type) {
        ReminderType.shift => HugeIcons.strokeRoundedBriefcase01,
        ReminderType.bill => HugeIcons.strokeRoundedInvoice01,
        ReminderType.debt => HugeIcons.strokeRoundedCoinsSwap,
        ReminderType.custom => HugeIcons.strokeRoundedNotification01,
      };

  void _showRuleSheet(
    BuildContext context,
    AlertsViewModel viewModel, {
    ReminderRule? existing,
  }) {
    final tr = context.strings;
    var type = existing != null ? ReminderType.fromValue(existing.type) : ReminderType.shift;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    var offsetMinutes = existing?.offsetMinutes ?? 30;
    const presetOffsets = [0, 15, 30, 60, 120, 1440];
    var useCustomOffset = !presetOffsets.contains(offsetMinutes);
    final customOffsetCtrl = TextEditingController(
      text: useCustomOffset ? offsetMinutes.toString() : '',
    );
    var timeOfDayMinutes = existing?.timeOfDayMinutes ?? ReminderPlanner.defaultBillMinutes;
    var repeatDays = existing?.repeatDays ?? 0;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final text = Theme.of(ctx).textTheme;
            final scheme = Theme.of(ctx).colorScheme;

            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpace.lg,
                left: AppSpace.page,
                right: AppSpace.page,
                top: AppSpace.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existing == null ? tr.addReminderRule : tr.editReminderRule,
                        style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.md),

                  // Rule Type Selector
                  Text(
                    tr.reminderTypeLabel,
                    style: text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Wrap(
                    spacing: AppSpace.xs,
                    runSpacing: AppSpace.xs,
                    children: [
                      for (final t in ReminderType.values)
                        ChoicePill(
                          _ruleTypeLabel(t, tr),
                          selected: type == t,
                          onTap: () => setModalState(() {
                            type = t;
                            if (t == ReminderType.shift && offsetMinutes == 1440) {
                              offsetMinutes = 30;
                              useCustomOffset = false;
                            } else if ((t == ReminderType.bill || t == ReminderType.debt) &&
                                offsetMinutes == 30) {
                              offsetMinutes = 1440;
                              useCustomOffset = false;
                            }
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.md),

                  if (type == ReminderType.custom) ...[
                    UnderlineField(
                      label: tr.title,
                      hint: tr.reminderCustomDefault,
                      controller: titleCtrl,
                    ),
                    const SizedBox(height: AppSpace.md),
                  ],

                  if (type != ReminderType.custom) ...[
                    Text(
                      tr.reminderTimingLabel,
                      style: text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Wrap(
                      spacing: AppSpace.xs,
                      runSpacing: AppSpace.xs,
                      children: [
                        for (final m in presetOffsets)
                          ChoicePill(
                            tr.reminderOffsetLabel(m),
                            selected: !useCustomOffset && offsetMinutes == m,
                            onTap: () => setModalState(() {
                              useCustomOffset = false;
                              offsetMinutes = m;
                            }),
                          ),
                        ChoicePill(
                          tr.customOption,
                          selected: useCustomOffset,
                          onTap: () => setModalState(() {
                            useCustomOffset = true;
                            if (customOffsetCtrl.text.isEmpty) {
                              customOffsetCtrl.text = offsetMinutes.toString();
                            }
                          }),
                        ),
                      ],
                    ),
                    if (useCustomOffset) ...[
                      const SizedBox(height: AppSpace.sm),
                      UnderlineField(
                        label: tr.customMinutesBefore,
                        hint: '45',
                        controller: customOffsetCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          final parsed = int.tryParse(val.trim());
                          if (parsed != null && parsed >= 0) {
                            setModalState(() => offsetMinutes = parsed);
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: AppSpace.md),
                  ],

                  if (type != ReminderType.shift) ...[
                    Text(
                      tr.reminderTimeOfDayLabel,
                      style: text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: TimeOfDay(
                            hour: (timeOfDayMinutes ~/ 60) % 24,
                            minute: timeOfDayMinutes % 60,
                          ),
                        );
                        if (picked != null) {
                          setModalState(() {
                            timeOfDayMinutes = picked.hour * 60 + picked.minute;
                          });
                        }
                      },
                      icon: const Icon(Icons.access_time, size: 18),
                      label: Text(_formatTimeMinutes(ctx, timeOfDayMinutes)),
                    ),
                    const SizedBox(height: AppSpace.md),
                  ],

                  if (type == ReminderType.shift || type == ReminderType.custom) ...[
                    Text(
                      tr.reminderRepeatDaysLabel,
                      style: text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Wrap(
                      spacing: AppSpace.xs,
                      runSpacing: AppSpace.xs,
                      children: [
                        for (var d = 1; d <= 7; d++)
                          FilterChip(
                            label: Text(tr.weekdayShort(d)),
                            selected: (repeatDays & (1 << (d - 1))) != 0,
                            selectedColor: scheme.primary,
                            checkmarkColor: scheme.onPrimary,
                            labelStyle: text.labelSmall?.copyWith(
                              color: (repeatDays & (1 << (d - 1))) != 0
                                  ? scheme.onPrimary
                                  : scheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (sel) => setModalState(() {
                              final bit = 1 << (d - 1);
                              repeatDays = sel ? (repeatDays | bit) : (repeatDays & ~bit);
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.md),
                  ],

                  const SizedBox(height: AppSpace.sm),
                  AppButton(
                    existing == null ? tr.addReminderRule : tr.saveChanges,
                    onPressed: () async {
                      if (existing == null) {
                        await viewModel.addRule(
                          type: type,
                          title: titleCtrl.text.trim(),
                          offsetMinutes: type == ReminderType.custom ? 0 : offsetMinutes,
                          timeOfDayMinutes: type == ReminderType.shift ? null : timeOfDayMinutes,
                          repeatDays: repeatDays,
                        );
                      } else {
                        await viewModel.updateRule(
                          existing.id,
                          type: type,
                          title: titleCtrl.text.trim(),
                          offsetMinutes: type == ReminderType.custom ? 0 : offsetMinutes,
                          timeOfDayMinutes: type == ReminderType.shift ? null : timeOfDayMinutes,
                          repeatDays: repeatDays,
                          isEnabled: existing.isEnabled,
                        );
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<AlertsViewModel>();

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final text = Theme.of(context).textTheme;
        final scheme = Theme.of(context).colorScheme;
        final colors = context.colors;
        final tr = context.strings;
        final settings = viewModel.settings;
        final rules = viewModel.rules;

        return Scaffold(
          appBar: AppTopBar(
            title: tr.alertPreferences,
            actions: [
              TopBarAction(
                HugeIcons.strokeRoundedAdd01,
                tooltip: tr.addReminderRule,
                onPressed: () => _showRuleSheet(context, viewModel),
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.page, vertical: AppSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr.whichAlertsQuestion,
                    style: text.headlineMedium,
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    tr.changeThemAnytime,
                    style: text.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),

                  Expanded(
                    child: ListView(
                      children: [
                        SwitchRow(
                          title: tr.shiftRemindersTitle,
                          subtitle: tr.oneHourBefore,
                          value: settings.shiftReminders,
                          onChanged: viewModel.toggleShiftReminders,
                        ),
                        const SizedBox(height: AppSpace.sm),
                        SwitchRow(
                          title: tr.clockOutReminderTitle,
                          subtitle: tr.after6Hours,
                          value: settings.clockOutReminder,
                          onChanged: viewModel.toggleClockOutReminder,
                        ),
                        const SizedBox(height: AppSpace.sm),
                        SwitchRow(
                          title: tr.billsDueTitle,
                          subtitle: tr.oneDayBefore,
                          value: settings.billsDue,
                          onChanged: viewModel.toggleBillsDue,
                        ),
                        const SizedBox(height: AppSpace.sm),
                        SwitchRow(
                          title: tr.goalNudgesTitle,
                          subtitle: tr.weekly,
                          value: settings.goalNudges,
                          onChanged: viewModel.toggleGoalNudges,
                        ),
                        const SizedBox(height: AppSpace.sm),
                        SwitchRow(
                          title: tr.weeklySummaryTitle,
                          subtitle: tr.sundayEvening,
                          value: settings.weeklySummary,
                          onChanged: viewModel.toggleWeeklySummary,
                        ),
                        const SizedBox(height: AppSpace.sm),
                        SwitchRow(
                          title: tr.quietHoursTitle,
                          subtitle: tr.quietHoursTimeRange,
                          value: settings.quietHours,
                          onChanged: viewModel.toggleQuietHours,
                        ),
                        const SizedBox(height: AppSpace.xl),

                        // Flexible Reminder Ruleset Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr.reminderRulesSection,
                                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tr.reminderRulesSubtitle,
                                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpace.sm),
                            TextButton.icon(
                              onPressed: () => _showRuleSheet(context, viewModel),
                              icon: const Icon(Icons.add, size: 18),
                              label: Text(tr.add),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.sm),

                        for (final rule in rules) ...[
                          Builder(
                            builder: (context) {
                              final rType = ReminderType.fromValue(rule.type);
                              final titleText = rType == ReminderType.custom && rule.title.isNotEmpty
                                  ? rule.title
                                  : _ruleTypeLabel(rType, tr);
                              final subtitleParts = <String>[];
                              if (rType != ReminderType.custom) {
                                subtitleParts.add(tr.reminderOffsetLabel(rule.offsetMinutes));
                              }
                              if (rType != ReminderType.shift && rule.timeOfDayMinutes != null) {
                                subtitleParts.add(_formatTimeMinutes(context, rule.timeOfDayMinutes!));
                              }
                              if (rType == ReminderType.shift || rType == ReminderType.custom) {
                                subtitleParts.add(_repeatDaysSummary(rule.repeatDays, tr));
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppSpace.sm),
                                child: AppCard(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpace.md,
                                    vertical: AppSpace.sm,
                                  ),
                                  onTap: () => _showRuleSheet(context, viewModel, existing: rule),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: colors.brand.withValues(alpha: 0.14),
                                          borderRadius: BorderRadius.circular(AppRadius.sm),
                                        ),
                                        alignment: Alignment.center,
                                        child: HugeIcon(
                                          icon: _ruleTypeIcon(rType),
                                          color: colors.brand,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpace.sm),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              titleText,
                                              style: text.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              subtitleParts.join(' · '),
                                              style: text.bodySmall?.copyWith(
                                                color: scheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Switch(
                                        value: rule.isEnabled,
                                        onChanged: (val) => viewModel.toggleRule(rule.id, val),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () => viewModel.deleteRule(rule.id),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: AppSpace.md),
                      ],
                    ),
                  ),

                  AppButton(
                    tr.done,
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
