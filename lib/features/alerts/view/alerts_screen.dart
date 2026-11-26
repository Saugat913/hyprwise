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

IconGlyph _ruleTypeIcon(ReminderType type) => switch (type) {
      ReminderType.shift => HugeIcons.strokeRoundedBriefcase01,
      ReminderType.bill => HugeIcons.strokeRoundedInvoice01,
      ReminderType.debt => HugeIcons.strokeRoundedCoinsSwap,
      ReminderType.custom => HugeIcons.strokeRoundedNotification01,
    };

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  void _openRuleEditor(
    BuildContext context,
    AlertsViewModel viewModel, {
    ReminderRule? existing,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReminderRuleFormScreen(
          viewModel: viewModel,
          existing: existing,
        ),
      ),
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
                onPressed: () => _openRuleEditor(context, viewModel),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.page,
                vertical: AppSpace.md,
              ),
              children: [
                Text(
                  tr.changeThemAnytime,
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpace.md),

                // Core toggles unified inside one AppCard matching Settings
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                        child: SwitchRow(
                          title: tr.shiftRemindersTitle,
                          subtitle: tr.t(
                            '30 minutes before shift starts',
                            ne: 'सिफ्ट सुरु हुनु ३० मिनेट अघि',
                            hi: 'शिफ्ट शुरू होने से 30 मिनट पहले',
                            es: '30 minutos antes del turno',
                            fr: '30 minutes avant le quart',
                            de: '30 Minuten vor Schichtbeginn',
                            ja: 'シフト開始30分前',
                            zh: '班次开始前 30 分钟',
                            it: '30 minuti prima del turno',
                          ),
                          value: settings.shiftReminders,
                          onChanged: viewModel.toggleShiftReminders,
                        ),
                      ),
                      const RowDivider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                        child: SwitchRow(
                          title: tr.clockOutReminderTitle,
                          subtitle: tr.after6Hours,
                          value: settings.clockOutReminder,
                          onChanged: viewModel.toggleClockOutReminder,
                        ),
                      ),
                      const RowDivider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                        child: SwitchRow(
                          title: tr.billsDueTitle,
                          subtitle: tr.oneDayBefore,
                          value: settings.billsDue,
                          onChanged: viewModel.toggleBillsDue,
                        ),
                      ),
                      const RowDivider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                        child: SwitchRow(
                          title: tr.goalNudgesTitle,
                          subtitle: tr.weekly,
                          value: settings.goalNudges,
                          onChanged: viewModel.toggleGoalNudges,
                        ),
                      ),
                      const RowDivider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                        child: SwitchRow(
                          title: tr.weeklySummaryTitle,
                          subtitle: tr.sundayEvening,
                          value: settings.weeklySummary,
                          onChanged: viewModel.toggleWeeklySummary,
                        ),
                      ),
                      const RowDivider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                        child: SwitchRow(
                          title: tr.quietHoursTitle,
                          subtitle: tr.quietHoursTimeRange,
                          value: settings.quietHours,
                          onChanged: viewModel.toggleQuietHours,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.xl),

                // Flexible Reminder Ruleset Section Header (outside AppCard per design system)
                SectionHeader(
                  tr.reminderRulesSection,
                  actionLabel: tr.add,
                  onAction: () => _openRuleEditor(context, viewModel),
                  padding: const EdgeInsets.only(bottom: AppSpace.sm),
                ),

                if (rules.isEmpty)
                  AppCard(
                    child: EmptyState(
                      compact: true,
                      illustration: EmptyIllustration.alerts,
                      icon: HugeIcons.strokeRoundedNotification01,
                      title: tr.t(
                        'No custom reminder rules yet',
                        ne: 'कुनै अनुकूल रिमाइन्डर नियम छैन',
                        hi: 'अभी कोई कस्टम रिमाइंडर नियम नहीं',
                        es: 'Aún no hay reglas personalizadas',
                        fr: 'Aucune règle personnalisée',
                        de: 'Noch keine eigenen Regeln',
                        ja: 'カスタムルールはまだありません',
                        zh: '暂无自定义提醒规则',
                        it: 'Nessuna regola personalizzata',
                      ),
                      message: tr.t(
                        'Create custom alerts for shifts, recurring bills, debts, or personal check-ins.',
                        ne: 'सिफ्ट, बिल, ऋण वा व्यक्तिगत जाँचका लागि अनुकूल रिमाइन्डर बनाउनुहोस्।',
                        hi: 'शिफ्ट, बिल, कर्ज या निजी रिमाइंडर के लिए कस्टम नियम बनाएं।',
                        es: 'Crea alertas para turnos, facturas, deudas o recordatorios propios.',
                        fr: 'Créez des alertes pour vos quarts, factures, dettes ou rappels.',
                        de: 'Erstelle eigene Regeln für Schichten, Rechnungen oder Schulden.',
                        ja: 'シフト・請求・貸借・カスタムのリマインダーを作成できます。',
                        zh: '为班次、账单、借贷或个人事项创建自定义提醒规则。',
                        it: 'Crea avvisi per turni, bollette, debiti o promemoria personali.',
                      ),
                      actionLabel: tr.addReminderRule,
                      onAction: () => _openRuleEditor(context, viewModel),
                    ),
                  )
                else
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < rules.length; i++) ...[
                          if (i > 0) const RowDivider(),
                          Builder(
                            builder: (context) {
                              final rule = rules[i];
                              final rType = ReminderType.fromValue(rule.type);
                              final titleText =
                                  rType == ReminderType.custom && rule.title.isNotEmpty
                                      ? rule.title
                                      : _ruleTypeLabel(rType, tr);
                              final subtitleParts = <String>[];
                              if (rType != ReminderType.custom) {
                                subtitleParts.add(tr.reminderOffsetLabel(rule.offsetMinutes));
                              }
                              if (rType != ReminderType.shift && rule.timeOfDayMinutes != null) {
                                subtitleParts.add(
                                  _formatTimeMinutes(context, rule.timeOfDayMinutes!),
                                );
                              }
                              if (rType == ReminderType.shift || rType == ReminderType.custom) {
                                subtitleParts.add(_repeatDaysSummary(rule.repeatDays, tr));
                              }

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _openRuleEditor(context, viewModel, existing: rule),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpace.md,
                                      vertical: AppSpace.sm + 2,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: colors.brandBg,
                                            borderRadius: BorderRadius.circular(AppRadius.md),
                                          ),
                                          alignment: Alignment.center,
                                          child: AppIcon(
                                            _ruleTypeIcon(rType),
                                            color: colors.brandText,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpace.md),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                titleText,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: text.bodyMedium?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                subtitleParts.join(' · '),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
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
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),

                const SizedBox(height: AppSpace.xl),
                AppButton(
                  tr.done,
                  onPressed: () => context.pop(),
                ),
                const SizedBox(height: AppSpace.md),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Full-page form screen for adding or editing a reminder rule, consistent with
/// Hyprwise's dedicated form screens (`EditAccountScreen`, wizards) using
/// SectionHeaders outside 12px-radius AppCards and a pinned primary CTA bar.
class ReminderRuleFormScreen extends StatefulWidget {
  const ReminderRuleFormScreen({
    super.key,
    required this.viewModel,
    this.existing,
  });

  final AlertsViewModel viewModel;
  final ReminderRule? existing;

  @override
  State<ReminderRuleFormScreen> createState() => _ReminderRuleFormScreenState();
}

class _ReminderRuleFormScreenState extends State<ReminderRuleFormScreen> {
  static const List<int> _presetOffsets = [0, 15, 30, 60, 120, 1440];

  late ReminderType _type;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _customOffsetCtrl;
  late int _offsetMinutes;
  late bool _useCustomOffset;
  late int _timeOfDayMinutes;
  late int _repeatDays;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _type = existing != null ? ReminderType.fromValue(existing.type) : ReminderType.shift;
    _titleCtrl = TextEditingController(text: existing?.title ?? '');
    _offsetMinutes = existing?.offsetMinutes ?? 30;
    _useCustomOffset = !_presetOffsets.contains(_offsetMinutes);
    _customOffsetCtrl = TextEditingController(
      text: _useCustomOffset ? _offsetMinutes.toString() : '',
    );
    _timeOfDayMinutes = existing?.timeOfDayMinutes ?? ReminderPlanner.defaultBillMinutes;
    _repeatDays = existing?.repeatDays ?? 0;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _customOffsetCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final tr = context.strings;
    final trimmedTitle = _titleCtrl.text.trim();
    if (_type == ReminderType.custom && trimmedTitle.isEmpty) {
      showErrorToast(context, tr.reminderCustomDefault);
      return;
    }

    setState(() => _saving = true);
    try {
      final existing = widget.existing;
      if (existing == null) {
        await widget.viewModel.addRule(
          type: _type,
          title: trimmedTitle,
          offsetMinutes: _type == ReminderType.custom ? 0 : _offsetMinutes,
          timeOfDayMinutes: _type == ReminderType.shift ? null : _timeOfDayMinutes,
          repeatDays: _repeatDays,
        );
      } else {
        await widget.viewModel.updateRule(
          existing.id,
          type: _type,
          title: trimmedTitle,
          offsetMinutes: _type == ReminderType.custom ? 0 : _offsetMinutes,
          timeOfDayMinutes: _type == ReminderType.shift ? null : _timeOfDayMinutes,
          repeatDays: _repeatDays,
          isEnabled: existing.isEnabled,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showErrorToast(context, tr.couldNotSave('$e'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final tr = context.strings;
    final confirmed = await showConfirmDialog(
      context,
      title: '${tr.delete}?',
      message: tr.t(
        'This reminder rule will be removed and its scheduled notifications cancelled.',
        ne: 'यो रिमाइन्डर नियम र यसका तालिकाबद्ध सूचनाहरू हटाइनेछन्।',
        hi: 'यह रिमाइंडर नियम और इसकी निर्धारित सूचनाएँ हटा दी जाएँगी।',
        es: 'Se eliminará esta regla y sus notificaciones programadas.',
        fr: 'Cette règle et ses notifications planifiées seront supprimées.',
        de: 'Diese Regel und geplante Benachrichtigungen werden entfernt.',
        ja: 'このルールと予定された通知が削除されます。',
        zh: '此提醒规则及其已安排的通知将被删除。',
        it: 'Questa regola e le notifiche programmate verranno rimosse.',
      ),
      confirmLabel: tr.delete,
      cancelLabel: tr.cancel,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    try {
      await widget.viewModel.deleteRule(existing.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showErrorToast(context, tr.couldNotSave('$e'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.strings;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final isEditing = widget.existing != null;

    return Scaffold(
      appBar: AppTopBar(
        title: isEditing ? tr.editReminderRule : tr.addReminderRule,
        actions: [
          if (isEditing)
            TopBarAction(
              HugeIcons.strokeRoundedDelete02,
              tooltip: tr.delete,
              onPressed: _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.page,
                  AppSpace.md,
                  AppSpace.page,
                  AppSpace.xl,
                ),
                children: [
                  Text(
                    tr.reminderRulesSubtitle,
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpace.lg),

                  // 1. Reminder Type (2x2 clean 12px architectural grid)
                  SectionHeader(
                    tr.reminderTypeLabel,
                    padding: const EdgeInsets.only(bottom: AppSpace.sm),
                  ),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: AppSpace.sm,
                    mainAxisSpacing: AppSpace.sm,
                    childAspectRatio: 2.35,
                    children: [
                      for (final t in ReminderType.values)
                        _RuleTypeTile(
                          label: _ruleTypeLabel(t, tr),
                          icon: _ruleTypeIcon(t),
                          selected: _type == t,
                          onTap: () => setState(() {
                            _type = t;
                            if (t == ReminderType.shift && _offsetMinutes == 1440) {
                              _offsetMinutes = 30;
                              _useCustomOffset = false;
                            } else if ((t == ReminderType.bill || t == ReminderType.debt) &&
                                _offsetMinutes == 30) {
                              _offsetMinutes = 1440;
                              _useCustomOffset = false;
                            }
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xl),

                  // 2. Details / Timing card
                  if (_type == ReminderType.custom) ...[
                    SectionHeader(
                      tr.title,
                      padding: const EdgeInsets.only(bottom: AppSpace.sm),
                    ),
                    AppCard(
                      child: UnderlineField(
                        label: tr.title,
                        hint: tr.reminderCustomDefault,
                        controller: _titleCtrl,
                        autofocus: !isEditing,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xl),
                  ] else ...[
                    SectionHeader(
                      tr.reminderTimingLabel,
                      padding: const EdgeInsets.only(bottom: AppSpace.sm),
                    ),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: AppSpace.sm,
                            runSpacing: AppSpace.sm,
                            children: [
                              for (final m in _presetOffsets)
                                ChoicePill(
                                  tr.reminderOffsetLabel(m),
                                  selected: !_useCustomOffset && _offsetMinutes == m,
                                  onTap: () => setState(() {
                                    _useCustomOffset = false;
                                    _offsetMinutes = m;
                                  }),
                                ),
                              ChoicePill(
                                tr.customOption,
                                selected: _useCustomOffset,
                                onTap: () => setState(() {
                                  _useCustomOffset = true;
                                  if (_customOffsetCtrl.text.isEmpty) {
                                    _customOffsetCtrl.text = _offsetMinutes.toString();
                                  }
                                }),
                              ),
                            ],
                          ),
                          if (_useCustomOffset) ...[
                            const SizedBox(height: AppSpace.md),
                            UnderlineField(
                              label: tr.customMinutesBefore,
                              hint: '45',
                              controller: _customOffsetCtrl,
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                final parsed = int.tryParse(val.trim());
                                if (parsed != null && parsed >= 0) {
                                  setState(() => _offsetMinutes = parsed);
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.xl),
                  ],

                  // 3. Time of day card (for Bill / Debt / Custom)
                  if (_type != ReminderType.shift) ...[
                    SectionHeader(
                      tr.reminderTimeOfDayLabel,
                      padding: const EdgeInsets.only(bottom: AppSpace.sm),
                    ),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: ListRow(
                        leading: const IconTile(HugeIcons.strokeRoundedClock01),
                        title: _formatTimeMinutes(context, _timeOfDayMinutes),
                        subtitle: tr.reminderTimeOfDayLabel,
                        trailing: const Chevron(),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(
                              hour: (_timeOfDayMinutes ~/ 60) % 24,
                              minute: _timeOfDayMinutes % 60,
                            ),
                          );
                          if (picked != null && mounted) {
                            setState(() {
                              _timeOfDayMinutes = picked.hour * 60 + picked.minute;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpace.xl),
                  ],

                  // 4. Repeat Days (even 7-column Mon–Sun bar inside AppCard)
                  if (_type == ReminderType.shift || _type == ReminderType.custom) ...[
                    SectionHeader(
                      tr.reminderRepeatDaysLabel,
                      actionLabel: _repeatDaysSummary(_repeatDays, tr),
                      onAction: () => setState(() {
                        _repeatDays = _repeatDays == 0 ? 0x1F : 0; // Toggle Mon–Fri vs Every day
                      }),
                      padding: const EdgeInsets.only(bottom: AppSpace.sm),
                    ),
                    AppCard(
                      padding: const EdgeInsets.all(AppSpace.md),
                      child: Row(
                        children: [
                          for (var d = 1; d <= 7; d++) ...[
                            if (d > 1) const SizedBox(width: 6),
                            Expanded(
                              child: _WeekdayCell(
                                label: tr.weekdayShort(d),
                                selected: (_repeatDays & (1 << (d - 1))) != 0,
                                onTap: () => setState(() {
                                  final bit = 1 << (d - 1);
                                  _repeatDays =
                                      (_repeatDays & bit) != 0
                                          ? (_repeatDays & ~bit)
                                          : (_repeatDays | bit);
                                }),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Pinned bottom action bar matching wizard screens
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.page,
                AppSpace.md,
                AppSpace.page,
                AppSpace.lg,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: scheme.outlineVariant)),
              ),
              child: AppButton(
                isEditing ? tr.saveChanges : tr.addReminderRule,
                loading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleTypeTile extends StatelessWidget {
  const _RuleTypeTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconGlyph icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    return Material(
      color: selected ? colors.brandBg : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: selected ? colors.brandText : scheme.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.sm,
          ),
          child: Row(
            children: [
              AppIcon(
                icon,
                size: 18,
                color: selected ? colors.brandText : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelLarge?.copyWith(
                    fontSize: 13.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? colors.brandText : scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekdayCell extends StatelessWidget {
  const _WeekdayCell({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    return Material(
      color: selected ? scheme.primary : colors.fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 40,
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: selected ? scheme.onPrimary : scheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
