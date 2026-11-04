import 'package:flutter/foundation.dart';
import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/auth/data/auth_service.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/shared/data/currency.dart';

class OnboardingViewModel extends ChangeNotifier {
  OnboardingViewModel({
    required this.settingsRepo,
    required this.accountRepo,
  }) {
    _selectedLocale = settingsRepo.settings.localeCode.isNotEmpty
        ? settingsRepo.settings.localeCode
        : 'en';
    _selectedCurrency = settingsRepo.settings.baseCurrency.isNotEmpty
        ? settingsRepo.settings.baseCurrency
        : 'USD';
  }

  final SettingsRepository settingsRepo;
  final AccountRepository accountRepo;

  int _step = 0;
  int get step => _step;

  late String _selectedLocale;
  String get selectedLocale => _selectedLocale;

  late String _selectedCurrency;
  String get selectedCurrency => _selectedCurrency;

  void nextStep() {
    _step = (_step + 1).clamp(0, 2);
    notifyListeners();
  }

  void previousStep() {
    _step = (_step - 1).clamp(0, 2);
    notifyListeners();
  }

  void goToSettingUp() {
    _step = 2;
    notifyListeners();
  }

  Future<void> selectLocale(String code, {bool autoLinkCurrency = true}) async {
    _selectedLocale = code;
    await settingsRepo.setLocaleCode(code);
    if (autoLinkCurrency) {
      final lang = AppLanguage.fromCode(code);
      _selectedCurrency = lang.defaultCurrencyCode;
    }
    notifyListeners();
  }

  void selectCurrency(String code) {
    _selectedCurrency = code;
    notifyListeners();
  }

  Future<void> finishSetup() async {
    await settingsRepo.setLocaleCode(_selectedLocale);
    await settingsRepo.setBaseCurrency(_selectedCurrency);
    await accountRepo.ensureFixedTwoAccounts(_selectedCurrency);
    await settingsRepo.completeOnboarding();

    if (getIt.isRegistered<AuthService>()) {
      final auth = getIt<AuthService>();
      final currentUser = auth.currentUser;
      if (currentUser != null) {
        await auth.markUserOnboarded(
          userId: currentUser.id,
          locale: _selectedLocale,
          baseCurrency: _selectedCurrency,
        );
      }
    }
  }
}
