import 'dart:async';
import 'package:flutter/material.dart' show Locale, ThemeMode;
import 'package:flutter/foundation.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/telemetry/telemetry_service.dart';
import 'package:finance_tracker/features/auth/data/auth_service.dart';
import 'package:finance_tracker/features/settings/data/model/app_settings.dart';

/// Device-local settings persisted in the `app_preferences` key/value table.
/// Call [load] once at startup; every setter persists and notifies listeners.
class SettingsRepository extends ChangeNotifier {
  SettingsRepository(this._db);

  final AppDatabase _db;

  static const keyLocale = 'locale';
  static const keyBaseCurrency = 'base_currency';
  static const keyThemeMode = 'theme_mode';
  static const keyOnboarded = 'onboarded';
  static const keyShiftReminders = 'alert_shift_reminders';
  static const keyClockOutReminder = 'alert_clock_out';
  static const keyBillsDue = 'alert_bills_due';
  static const keyGoalNudges = 'alert_goal_nudges';
  static const keyWeeklySummary = 'alert_weekly_summary';
  static const keyQuietHours = 'alert_quiet_hours';
  static const keyBackupEnabled = 'backup_enabled';
  static const keyBackupFrequency = 'backup_frequency';
  static const keyLastBackupAt = 'last_backup_at';
  static const keyShowAssistantFab = 'show_assistant_fab';

  AppSettings _settings = const AppSettings();

  AppSettings get settings => _settings;

  Future<void> load() async {
    final rows = await _db.select(_db.appPreferences).get();
    final map = {for (final row in rows) row.key: row.value};
    bool flag(String key, bool fallback) =>
        map.containsKey(key) ? map[key] == 'true' : fallback;
    _settings = AppSettings(
      localeCode: map[keyLocale] ?? 'en',
      baseCurrency: map[keyBaseCurrency] ?? 'USD',
      themeMode: switch (map[keyThemeMode]) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      onboarded: flag(keyOnboarded, false),
      shiftReminders: flag(keyShiftReminders, true),
      clockOutReminder: flag(keyClockOutReminder, true),
      billsDue: flag(keyBillsDue, true),
      goalNudges: flag(keyGoalNudges, false),
      weeklySummary: flag(keyWeeklySummary, true),
      quietHours: flag(keyQuietHours, true),
      backupEnabled: flag(keyBackupEnabled, false),
      backupFrequency: map[keyBackupFrequency] ?? 'daily',
      lastBackupAt: int.tryParse(map[keyLastBackupAt] ?? ''),
      showAssistantFab: flag(keyShowAssistantFab, true),
    );
    notifyListeners();
  }

  // --- Getters ---------------------------------------------------------

  String get localeCode => _settings.localeCode;
  Locale get locale => Locale(_settings.localeCode);
  String get baseCurrency => _settings.baseCurrency;
  ThemeMode get themeMode => _settings.themeMode;
  bool get onboarded => _settings.onboarded;
  bool get shiftReminders => _settings.shiftReminders;
  bool get clockOutReminder => _settings.clockOutReminder;
  bool get billsDue => _settings.billsDue;
  bool get goalNudges => _settings.goalNudges;
  bool get weeklySummary => _settings.weeklySummary;
  bool get quietHours => _settings.quietHours;
  bool get backupEnabled => _settings.backupEnabled;
  String get backupFrequency => _settings.backupFrequency;
  DateTime? get lastBackupAt =>
      _settings.lastBackupAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(_settings.lastBackupAt!);
  bool get showAssistantFab => _settings.showAssistantFab;

  // --- Setters ----------------------------------------------------------

  Future<void> setShowAssistantFab(bool value) => _apply(
    _settings.copyWith(showAssistantFab: value),
    {keyShowAssistantFab: '$value'},
  );

  Future<void> setLocale(String code) {
    TelemetryService.instance.setUserProperty(name: 'locale', value: code);
    if (getIt.isRegistered<AuthService>()) {
      unawaited(getIt<AuthService>().syncUserPreferences(locale: code));
    }
    return _apply(_settings.copyWith(localeCode: code), {keyLocale: code});
  }

  Future<void> setLocaleCode(String code) => setLocale(code);

  Future<void> setBaseCurrency(String code) {
    TelemetryService.instance.setUserProperty(name: 'base_currency', value: code);
    if (getIt.isRegistered<AuthService>()) {
      unawaited(getIt<AuthService>().syncUserPreferences(baseCurrency: code));
    }
    return _apply(
      _settings.copyWith(baseCurrency: code),
      {keyBaseCurrency: code},
    );
  }

  Future<void> setThemeMode(ThemeMode mode) {
    TelemetryService.instance.setUserProperty(name: 'theme_mode', value: mode.name);
    return _apply(
      _settings.copyWith(themeMode: mode),
      {keyThemeMode: mode.name},
    );
  }

  bool get alertsMasterEnabled =>
      _settings.shiftReminders ||
      _settings.clockOutReminder ||
      _settings.billsDue ||
      _settings.weeklySummary ||
      _settings.goalNudges;

  Future<void> setAllAlerts(bool enabled) {
    return _apply(
      _settings.copyWith(
        shiftReminders: enabled,
        clockOutReminder: enabled,
        billsDue: enabled,
        weeklySummary: enabled,
        goalNudges: enabled,
      ),
      {
        keyShiftReminders: '$enabled',
        keyClockOutReminder: '$enabled',
        keyBillsDue: '$enabled',
        keyWeeklySummary: '$enabled',
        keyGoalNudges: '$enabled',
      },
    );
  }

  Future<void> completeOnboarding() =>
      _apply(_settings.copyWith(onboarded: true), {keyOnboarded: 'true'});

  Future<void> resetOnboarding() =>
      _apply(_settings.copyWith(onboarded: false), {keyOnboarded: 'false'});

  Future<void> setShiftReminders(bool value) => _apply(
    _settings.copyWith(shiftReminders: value),
    {keyShiftReminders: '$value'},
  );

  Future<void> setClockOutReminder(bool value) => _apply(
    _settings.copyWith(clockOutReminder: value),
    {keyClockOutReminder: '$value'},
  );

  Future<void> setBillsDue(bool value) =>
      _apply(_settings.copyWith(billsDue: value), {keyBillsDue: '$value'});

  Future<void> setGoalNudges(bool value) => _apply(
    _settings.copyWith(goalNudges: value),
    {keyGoalNudges: '$value'},
  );

  Future<void> setWeeklySummary(bool value) => _apply(
    _settings.copyWith(weeklySummary: value),
    {keyWeeklySummary: '$value'},
  );

  Future<void> setQuietHours(bool value) => _apply(
    _settings.copyWith(quietHours: value),
    {keyQuietHours: '$value'},
  );

  Future<void> setBackupEnabled(bool value) => _apply(
    _settings.copyWith(backupEnabled: value),
    {keyBackupEnabled: '$value'},
  );

  /// `daily`, `weekly` or `monthly`.
  Future<void> setBackupFrequency(String value) => _apply(
    _settings.copyWith(backupFrequency: value),
    {keyBackupFrequency: value},
  );

  Future<void> setLastBackupAt(DateTime value) {
    final ms = value.millisecondsSinceEpoch;
    return _apply(
      _settings.copyWith(lastBackupAt: ms),
      {keyLastBackupAt: '$ms'},
    );
  }

  Future<String?> getString(String key) async {
    final row = await (_db.select(_db.appPreferences)
          ..where((p) => p.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setString(String key, String value) async {
    await _db.into(_db.appPreferences).insertOnConflictUpdate(
          AppPreferencesCompanion.insert(
            key: key,
            value: value,
          ),
        );
  }

  /// Applies [next] immediately, then persists [entries]; a null value
  /// deletes the key.
  Future<void> _apply(AppSettings next, Map<String, String?> entries) async {
    _settings = next;
    notifyListeners();
    for (final entry in entries.entries) {
      if (entry.value == null) {
        await (_db.delete(_db.appPreferences)
          ..where((p) => p.key.equals(entry.key))).go();
      } else {
        await _db
            .into(_db.appPreferences)
            .insertOnConflictUpdate(
              AppPreferencesCompanion.insert(
                key: entry.key,
                value: entry.value!,
              ),
            );
      }
    }
  }
}
