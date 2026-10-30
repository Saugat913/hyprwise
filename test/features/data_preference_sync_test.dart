import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/settings/data/repository/data_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';

void main() {
  test(
    'cloud export and import preserve onboarding and customer preferences',
    () async {
      final sourceDb = AppDatabase.forTesting(NativeDatabase.memory());
      final targetDb = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(sourceDb.close);
      addTearDown(targetDb.close);

      final sourceSettings = SettingsRepository(sourceDb);
      await sourceSettings.load();
      await sourceSettings.setLocaleCode('ne');
      await sourceSettings.setBaseCurrency('NPR');
      await sourceSettings.setThemeMode(ThemeMode.dark);
      await sourceSettings.setShiftReminders(false);
      await sourceSettings.completeOnboarding();

      final backup = await DataRepository(sourceDb).exportJson();
      final decoded = jsonDecode(backup) as Map<String, dynamic>;
      expect(decoded['preferences'], isA<List>());

      final targetSettings = SettingsRepository(targetDb);
      await targetSettings.load();
      await DataRepository(targetDb).importJson(backup);
      await targetSettings.load();

      expect(targetSettings.settings.onboarded, isTrue);
      expect(targetSettings.settings.localeCode, 'ne');
      expect(targetSettings.settings.baseCurrency, 'NPR');
      expect(targetSettings.settings.themeMode, ThemeMode.dark);
      expect(targetSettings.settings.shiftReminders, isFalse);
    },
  );
}
