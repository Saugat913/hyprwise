import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/features/settings/data/model/app_settings.dart';
import 'package:finance_tracker/features/settings/data/repository/data_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/exchange_rate_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/shared/data/currency.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({
    required this.settingsRepo,
    required this.dataRepo,
    required this.financeStore,
    ExchangeRateRepository? ratesRepo,
  }) : ratesRepo = ratesRepo ?? getIt<ExchangeRateRepository>() {
    settingsRepo.addListener(_onSettingsChanged);
    financeStore.addListener(_onSettingsChanged);
  }

  final SettingsRepository settingsRepo;
  final DataRepository dataRepo;
  final FinanceStore financeStore;
  final ExchangeRateRepository ratesRepo;

  void _onSettingsChanged() {
    notifyListeners();
  }

  AppSettings get settings => settingsRepo.settings;
  String get baseCurrency => settings.baseCurrency;
  ThemeMode get themeMode => settings.themeMode;

  int get accountsCount => financeStore.accounts.length;
  int get jobsCount => financeStore.jobs.length;

  Future<void> setThemeMode(ThemeMode mode) => settingsRepo.setThemeMode(mode);
  Future<void> setBaseCurrency(String code) => settingsRepo.setBaseCurrency(code);
  Future<void> setLocaleCode(String code) => settingsRepo.setLocale(code);
  Future<void> setShowAssistantFab(bool value) => settingsRepo.setShowAssistantFab(value);
  String get localeCode => settingsRepo.localeCode;

  /// Checks internet connectivity, downloads live rates for [newCurrency],
  /// stores exchange rates, and updates base currency.
  /// Returns null on success, or an error message (e.g. 'NO_INTERNET').
  Future<String?> switchBaseCurrencyWithConversion(String newCurrency) async {
    final target = newCurrency.toUpperCase().trim();
    if (target == baseCurrency) return null;

    final online = await _checkInternet();
    if (!online) {
      return 'NO_INTERNET';
    }

    try {
      final url = Uri.parse('https://open.er-api.com/v6/latest/$target');
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(url);
      final response = await request.close();
      if (response.statusCode != 200) {
        return 'Could not retrieve exchange rates (HTTP ${response.statusCode})';
      }

      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final rates = json['rates'] as Map<String, dynamic>?;

      if (rates == null || rates.isEmpty) {
        return 'Invalid rate data received';
      }

      for (final cur in Currency.supported) {
        final code = cur.code;
        if (code == target) continue;
        final rawRate = rates[code];
        if (rawRate is num && rawRate > 0) {
          await ratesRepo.add(
            baseCode: target,
            quoteCode: code,
            rate: rawRate.toDouble(),
          );
        }
      }

      await settingsRepo.setBaseCurrency(target);
      await financeStore.accountsRepo.ensureFixedTwoAccounts(target);
      return null;
    } catch (e) {
      return 'Error updating rates: $e';
    }
  }

  Future<bool> _checkInternet() async {
    try {
      final res = await InternetAddress.lookup('dns.google')
          .timeout(const Duration(seconds: 4));
      return res.isNotEmpty && res[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<String> exportData() => dataRepo.exportJson();
  Future<void> importData(String jsonString) async {
    await dataRepo.importJson(jsonString);
    // Imports can contain the Pro customer's language, currency, theme and
    // alert preferences. Refresh the cached settings immediately.
    await settingsRepo.load();
  }
  Future<void> eraseAllData() => dataRepo.eraseAll();

  @override
  void dispose() {
    settingsRepo.removeListener(_onSettingsChanged);
    financeStore.removeListener(_onSettingsChanged);
    super.dispose();
  }
}
