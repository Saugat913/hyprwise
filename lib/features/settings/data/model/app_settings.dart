import 'package:flutter/material.dart' show ThemeMode;

/// User-controlled, device-local settings. Kept intentionally small so it is
/// easy to encrypt and back up alongside financial data.
class AppSettings {
  const AppSettings({
    this.localeCode = 'en',
    this.baseCurrency = 'USD',
    this.themeMode = ThemeMode.system,
    this.onboarded = false,
    this.shiftReminders = true,
    this.clockOutReminder = true,
    this.billsDue = true,
    this.goalNudges = false,
    this.weeklySummary = true,
    this.quietHours = true,
    this.backupEnabled = false,
    this.backupFrequency = 'daily',
    this.lastBackupAt,
    this.showAssistantFab = true,
  });

  final String localeCode;
  final String baseCurrency;
  final ThemeMode themeMode;
  final bool onboarded;

  // Alert preferences.
  final bool shiftReminders;
  final bool clockOutReminder;
  final bool billsDue;
  final bool goalNudges;
  final bool weeklySummary;
  final bool quietHours;

  // Backup.
  final bool backupEnabled;
  final String backupFrequency;
  final int? lastBackupAt;

  // Assistant preference.
  final bool showAssistantFab;

  AppSettings copyWith({
    String? localeCode,
    String? baseCurrency,
    ThemeMode? themeMode,
    bool? onboarded,
    bool? shiftReminders,
    bool? clockOutReminder,
    bool? billsDue,
    bool? goalNudges,
    bool? weeklySummary,
    bool? quietHours,
    bool? backupEnabled,
    String? backupFrequency,
    int? lastBackupAt,
    bool? showAssistantFab,
  }) => AppSettings(
    localeCode: localeCode ?? this.localeCode,
    baseCurrency: baseCurrency ?? this.baseCurrency,
    themeMode: themeMode ?? this.themeMode,
    onboarded: onboarded ?? this.onboarded,
    shiftReminders: shiftReminders ?? this.shiftReminders,
    clockOutReminder: clockOutReminder ?? this.clockOutReminder,
    billsDue: billsDue ?? this.billsDue,
    goalNudges: goalNudges ?? this.goalNudges,
    weeklySummary: weeklySummary ?? this.weeklySummary,
    quietHours: quietHours ?? this.quietHours,
    backupEnabled: backupEnabled ?? this.backupEnabled,
    backupFrequency: backupFrequency ?? this.backupFrequency,
    lastBackupAt: lastBackupAt ?? this.lastBackupAt,
    showAssistantFab: showAssistantFab ?? this.showAssistantFab,
  );
}
