import 'package:flutter/foundation.dart';
import 'package:finance_tracker/core/notifications/shift_notification_service.dart';
import 'package:finance_tracker/features/alerts/data/model/alerts.dart';
import 'package:finance_tracker/features/settings/data/model/app_settings.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';

class AlertsViewModel extends ChangeNotifier {
  AlertsViewModel({
    required this.financeStore,
    required this.settingsRepo,
  }) {
    financeStore.addListener(_onChanged);
    settingsRepo.addListener(_onChanged);
  }

  final FinanceStore financeStore;
  final SettingsRepository settingsRepo;

  void _onChanged() {
    notifyListeners();
  }

  AppSettings get settings => settingsRepo.settings;

  List<FinanceAlert> get alerts => financeStore.advice();

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
    financeStore.removeListener(_onChanged);
    settingsRepo.removeListener(_onChanged);
    super.dispose();
  }
}
