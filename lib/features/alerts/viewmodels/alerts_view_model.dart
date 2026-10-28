import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/notifications/reminder_planner.dart';
import 'package:finance_tracker/core/notifications/shift_notification_service.dart';
import 'package:finance_tracker/features/alerts/data/model/alerts.dart';
import 'package:finance_tracker/features/settings/data/model/app_settings.dart';
import 'package:finance_tracker/features/settings/data/repository/reminder_rule_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';

class AlertsViewModel extends ChangeNotifier {
  AlertsViewModel({
    required this.financeStore,
    required this.settingsRepo,
    required this.reminderRuleRepo,
  }) {
    financeStore.addListener(_onChanged);
    settingsRepo.addListener(_onChanged);
    _initRules();
  }

  final FinanceStore financeStore;
  final SettingsRepository settingsRepo;
  final ReminderRuleRepository reminderRuleRepo;

  StreamSubscription<List<ReminderRule>>? _rulesSub;
  List<ReminderRule> _rules = const [];
  List<ReminderRule> get rules => _rules;
  bool _seeded = false;

  void _initRules() {
    _rulesSub = reminderRuleRepo.watchAll().listen((items) async {
      if (items.isEmpty && !_seeded) {
        _seeded = true;
        await reminderRuleRepo.add(
          type: ReminderType.shift,
          offsetMinutes: 30,
          isEnabled: settings.shiftReminders,
        );
        await reminderRuleRepo.add(
          type: ReminderType.bill,
          offsetMinutes: 1440,
          timeOfDayMinutes: ReminderPlanner.defaultBillMinutes,
          isEnabled: settings.billsDue,
        );
        return;
      }
      _seeded = true;
      _rules = items;
      _syncPlannedReminders();
      notifyListeners();
    });
  }

  void _onChanged() {
    _syncPlannedReminders();
    notifyListeners();
  }

  void _syncPlannedReminders() {
    final tr = AppStrings(settings.localeCode);
    final plan = ReminderPlanner.plan(
      rules: _rules,
      shifts: financeStore.shifts,
      jobs: financeStore.jobs,
      recurring: financeStore.recurring,
      debts: financeStore.debts,
      tr: tr,
      now: DateTime.now(),
      shiftsEnabled: settings.shiftReminders,
      billsEnabled: settings.billsDue,
    );
    unawaited(ShiftNotificationService.instance.syncReminders(plan));
  }

  AppSettings get settings => settingsRepo.settings;

  List<FinanceAlert> get alerts => financeStore.advice();

  Future<void> addRule({
    required ReminderType type,
    String title = '',
    int offsetMinutes = 0,
    int? timeOfDayMinutes,
    int repeatDays = 0,
    bool isEnabled = true,
  }) async {
    await ShiftNotificationService.instance.requestPermission();
    await reminderRuleRepo.add(
      type: type,
      title: title,
      offsetMinutes: offsetMinutes,
      timeOfDayMinutes: timeOfDayMinutes,
      repeatDays: repeatDays,
      isEnabled: isEnabled,
    );
  }

  Future<void> updateRule(
    int id, {
    required ReminderType type,
    String title = '',
    int offsetMinutes = 0,
    int? timeOfDayMinutes,
    int repeatDays = 0,
    bool isEnabled = true,
  }) async {
    await reminderRuleRepo.update(
      id,
      type: type,
      title: title,
      offsetMinutes: offsetMinutes,
      timeOfDayMinutes: timeOfDayMinutes,
      repeatDays: repeatDays,
      isEnabled: isEnabled,
    );
  }

  Future<void> toggleRule(int id, bool enabled) async {
    if (enabled) {
      await ShiftNotificationService.instance.requestPermission();
    }
    await reminderRuleRepo.setEnabled(id, enabled);
  }

  Future<void> deleteRule(int id) async {
    await reminderRuleRepo.delete(id);
  }

  Future<void> toggleShiftReminders(bool val) async {
    if (val) {
      await ShiftNotificationService.instance.requestPermission();
    }
    await settingsRepo.setShiftReminders(val);
  }

  Future<void> toggleClockOutReminder(bool val) async {
    if (val) {
      await ShiftNotificationService.instance.requestPermission();
    }
    await settingsRepo.setClockOutReminder(val);
  }

  Future<void> toggleBillsDue(bool val) async {
    if (val) {
      await ShiftNotificationService.instance.requestPermission();
    }
    await settingsRepo.setBillsDue(val);
  }

  Future<void> toggleGoalNudges(bool val) async {
    if (val) {
      await ShiftNotificationService.instance.requestPermission();
    }
    await settingsRepo.setGoalNudges(val);
  }

  Future<void> toggleWeeklySummary(bool val) async {
    if (val) {
      await ShiftNotificationService.instance.requestPermission();
    }
    await settingsRepo.setWeeklySummary(val);
  }

  Future<void> toggleQuietHours(bool val) => settingsRepo.setQuietHours(val);

  @override
  void dispose() {
    _rulesSub?.cancel();
    financeStore.removeListener(_onChanged);
    settingsRepo.removeListener(_onChanged);
    super.dispose();
  }
}
