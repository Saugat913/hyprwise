import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';

/// A supported language linked with associated currencies.
class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.badge,
    required this.associatedCurrencies,
    required this.defaultCurrencyCode,
  });

  final String code;
  final String name;
  final String nativeName;
  final String badge;
  final List<String> associatedCurrencies;
  final String defaultCurrencyCode;

  static const supported = <AppLanguage>[
    AppLanguage(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      badge: 'EN',
      associatedCurrencies: ['USD', 'AUD', 'CAD', 'GBP', 'SGD', 'HKD'],
      defaultCurrencyCode: 'USD',
    ),
    AppLanguage(
      code: 'ne',
      name: 'Nepali',
      nativeName: 'नेपाली',
      badge: 'ने',
      associatedCurrencies: ['NPR'],
      defaultCurrencyCode: 'NPR',
    ),
    AppLanguage(
      code: 'es',
      name: 'Spanish',
      nativeName: 'Español',
      badge: 'ES',
      associatedCurrencies: ['EUR'],
      defaultCurrencyCode: 'EUR',
    ),
    AppLanguage(
      code: 'fr',
      name: 'French',
      nativeName: 'Français',
      badge: 'FR',
      associatedCurrencies: ['EUR', 'CAD', 'CHF'],
      defaultCurrencyCode: 'EUR',
    ),
    AppLanguage(
      code: 'de',
      name: 'German',
      nativeName: 'Deutsch',
      badge: 'DE',
      associatedCurrencies: ['EUR', 'CHF'],
      defaultCurrencyCode: 'EUR',
    ),
    AppLanguage(
      code: 'ja',
      name: 'Japanese',
      nativeName: '日本語',
      badge: '日',
      associatedCurrencies: ['JPY'],
      defaultCurrencyCode: 'JPY',
    ),
    AppLanguage(
      code: 'zh',
      name: 'Mandarin Chinese',
      nativeName: '中文',
      badge: '中',
      associatedCurrencies: ['CNY', 'HKD', 'SGD'],
      defaultCurrencyCode: 'CNY',
    ),
    AppLanguage(
      code: 'it',
      name: 'Italian',
      nativeName: 'Italiano',
      badge: 'IT',
      associatedCurrencies: ['CHF', 'EUR'],
      defaultCurrencyCode: 'CHF',
    ),
  ];

  static AppLanguage fromCode(String code) => supported.firstWhere(
    (lang) => lang.code.toLowerCase() == code.toLowerCase(),
    orElse: () => supported.first,
  );
}

/// A supported currency. Codes are ISO-4217 three-letter strings; amounts are
/// always stored as integer minor units.
class Currency {
  const Currency(
    this.code,
    this._defaultName,
    this.symbol, {
    this.associatedLanguages = 'English',
    this.associatedLanguageCodes = const ['en'],
    this.defaultLanguageCode = 'en',
  });

  final String code;
  final String _defaultName;
  final String symbol;
  final String associatedLanguages;
  final List<String> associatedLanguageCodes;
  final String defaultLanguageCode;

  String get defaultName => _defaultName;
  String get name => AppStrings.current().currencyName(code, _defaultName);

  /// Symbolic representation that adapts to locale / language support.
  /// Uses symbolic representation like '$' instead of 'USD', 'A$' for Australian Dollar,
  /// 'रु' when locale is Nepali, '₹' for INR, '€' for EUR, '¥' for JPY/CNY, '£' for GBP,
  /// 'CA$' for CAD, 'HK$' for HKD, 'S$' for SGD, and 'CHF' for CHF.
  String symbolForLocale(String localeCode) {
    final lowerLocale = localeCode.toLowerCase();
    switch (code.toUpperCase()) {
      case 'USD':
        return r'$';
      case 'AUD':
        return r'A$';
      case 'CAD':
        return r'CA$';
      case 'HKD':
        return r'HK$';
      case 'SGD':
        return r'S$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'CNY':
        return '¥';
      case 'INR':
        return '₹';
      case 'NPR':
        return lowerLocale.startsWith('ne') ? 'रु' : 'Rs';
      case 'CHF':
        return 'CHF';
      default:
        return symbol;
    }
  }

  static const supported = <Currency>[
    Currency(
      'USD',
      'US dollar',
      r'$',
      associatedLanguages: 'English',
      associatedLanguageCodes: ['en'],
      defaultLanguageCode: 'en',
    ),
    Currency(
      'EUR',
      'Euro',
      '€',
      associatedLanguages: 'French, Spanish, German',
      associatedLanguageCodes: ['fr', 'es', 'de'],
      defaultLanguageCode: 'de',
    ),
    Currency(
      'JPY',
      'Japanese yen',
      '¥',
      associatedLanguages: 'Japanese',
      associatedLanguageCodes: ['ja'],
      defaultLanguageCode: 'ja',
    ),
    Currency(
      'GBP',
      'British pound',
      '£',
      associatedLanguages: 'English',
      associatedLanguageCodes: ['en'],
      defaultLanguageCode: 'en',
    ),
    Currency(
      'CNY',
      'Chinese yuan',
      '¥',
      associatedLanguages: 'Mandarin Chinese',
      associatedLanguageCodes: ['zh'],
      defaultLanguageCode: 'zh',
    ),
    Currency(
      'CHF',
      'Swiss franc',
      'CHF',
      associatedLanguages: 'German, French, Italian',
      associatedLanguageCodes: ['de', 'fr', 'it'],
      defaultLanguageCode: 'de',
    ),
    Currency(
      'CAD',
      'Canadian dollar',
      r'CA$',
      associatedLanguages: 'English, French',
      associatedLanguageCodes: ['en', 'fr'],
      defaultLanguageCode: 'en',
    ),
    Currency(
      'AUD',
      'Australian dollar',
      r'A$',
      associatedLanguages: 'English',
      associatedLanguageCodes: ['en'],
      defaultLanguageCode: 'en',
    ),
    Currency(
      'HKD',
      'Hong Kong dollar',
      r'HK$',
      associatedLanguages: 'Cantonese, English',
      associatedLanguageCodes: ['zh', 'en'],
      defaultLanguageCode: 'zh',
    ),
    Currency(
      'SGD',
      'Singapore dollar',
      r'S$',
      associatedLanguages: 'English, Mandarin, Malay, Tamil',
      associatedLanguageCodes: ['en', 'zh', 'ms', 'ta'],
      defaultLanguageCode: 'en',
    ),
    Currency(
      'NPR',
      'Nepali rupee',
      'रु',
      associatedLanguages: 'Nepali',
      associatedLanguageCodes: ['ne'],
      defaultLanguageCode: 'ne',
    ),
    Currency(
      'INR',
      'Indian rupee',
      '₹',
      associatedLanguages: 'Hindi, English',
      associatedLanguageCodes: ['hi', 'en'],
      defaultLanguageCode: 'hi',
    ),
  ];

  static Currency fromCode(String code) => supported.firstWhere(
    (currency) => currency.code == code.toUpperCase(),
    orElse: () => Currency(code.toUpperCase(), code.toUpperCase(), code),
  );
}

/// A conversion quote. The stored value is the quote amount per one base unit,
/// scaled by [scale] to preserve precision without floating point.
class ExchangeRateQuote {
  const ExchangeRateQuote({
    required this.baseCode,
    required this.quoteCode,
    required this.rateScaled,
  });

  static const int scale = 1000000;

  final String baseCode;
  final String quoteCode;
  final int rateScaled;

  double get rate => rateScaled / scale;

  factory ExchangeRateQuote.fromRow(ExchangeRate row) => ExchangeRateQuote(
    baseCode: row.baseCode,
    quoteCode: row.quoteCode,
    rateScaled: row.rateScaled,
  );
}

/// Converts amounts between currencies using stored quotes, falling back to an
/// identity conversion when currencies match or a rate is missing.
class CurrencyConverter {
  CurrencyConverter(Iterable<ExchangeRateQuote> quotes)
    : _quotes = {
        for (final quote in quotes)
          '${quote.baseCode}>${quote.quoteCode}': quote,
      };

  final Map<String, ExchangeRateQuote> _quotes;

  /// Converts [minorUnits] from [from] to [to]. Returns the input unchanged
  /// when no rate is available, so callers can still show a raw value.
  int convert(int minorUnits, String from, String to) {
    final fromUpper = from.toUpperCase();
    final toUpper = to.toUpperCase();
    if (fromUpper == toUpper) return minorUnits;

    final direct = _quotes['$fromUpper>$toUpper'];
    if (direct != null) {
      return (minorUnits * direct.rateScaled / ExchangeRateQuote.scale).round();
    }

    final inverse = _quotes['$toUpper>$fromUpper'];
    if (inverse != null && inverse.rateScaled != 0) {
      return (minorUnits * ExchangeRateQuote.scale / inverse.rateScaled)
          .round();
    }

    return minorUnits;
  }

  bool hasRate(String from, String to) {
    if (from.toUpperCase() == to.toUpperCase()) return true;
    return _quotes.containsKey('${from.toUpperCase()}>${to.toUpperCase()}') ||
        _quotes.containsKey('${to.toUpperCase()}>${from.toUpperCase()}');
  }
}
