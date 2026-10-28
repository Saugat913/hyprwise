import 'package:flutter_test/flutter_test.dart';

import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/shared/data/currency.dart';

void main() {
  group('Multilingual and Multi-Currency System', () {
    test('All influential currencies are supported with correct metadata and linked languages', () {
      final expectedCurrencies = {
        'USD': ('US dollar', r'$', 'English'),
        'EUR': ('Euro', '€', 'French, Spanish, German'),
        'JPY': ('Japanese yen', '¥', 'Japanese'),
        'GBP': ('British pound', '£', 'English'),
        'CNY': ('Chinese yuan', '¥', 'Mandarin Chinese'),
        'CHF': ('Swiss franc', 'CHF', 'German, French, Italian'),
        'CAD': ('Canadian dollar', r'CA$', 'English, French'),
        'AUD': ('Australian dollar', r'A$', 'English'),
        'HKD': ('Hong Kong dollar', r'HK$', 'Cantonese, English'),
        'SGD': ('Singapore dollar', r'S$', 'English, Mandarin, Malay, Tamil'),
        'NPR': ('Nepali rupee', 'रु', 'Nepali'),
        'INR': ('Indian rupee', '₹', 'Hindi, English'),
      };

      for (final entry in expectedCurrencies.entries) {
        final cur = Currency.fromCode(entry.key);
        expect(cur.code, entry.key);
        expect(cur.name, entry.value.$1);
        expect(cur.associatedLanguages, entry.value.$3);
      }
    });

    test('Symbolic representation adapts to currency and current language', () {
      // USD uses symbolic $ instead of USD
      expect(MoneyFormatter.symbolFor('USD', locale: 'en'), r'$');
      expect(MoneyFormatter.format(123450, 'USD', locale: 'en'), r'$1,234.50');

      // Australian dollar uses A$
      expect(MoneyFormatter.symbolFor('AUD', locale: 'en'), r'A$');
      expect(MoneyFormatter.format(123450, 'AUD', locale: 'en'), r'A$1,234.50');

      // Canadian dollar uses CA$
      expect(MoneyFormatter.symbolFor('CAD', locale: 'en'), r'CA$');
      expect(MoneyFormatter.format(123450, 'CAD', locale: 'en'), r'CA$1,234.50');

      // Hong Kong dollar uses HK$
      expect(MoneyFormatter.symbolFor('HKD', locale: 'en'), r'HK$');

      // Singapore dollar uses S$
      expect(MoneyFormatter.symbolFor('SGD', locale: 'en'), r'S$');

      // Euro uses €
      expect(MoneyFormatter.symbolFor('EUR', locale: 'de'), '€');
      expect(MoneyFormatter.symbolFor('EUR', locale: 'fr'), '€');
      expect(MoneyFormatter.symbolFor('EUR', locale: 'es'), '€');

      // British Pound uses £
      expect(MoneyFormatter.symbolFor('GBP', locale: 'en'), '£');

      // Japanese Yen uses ¥
      expect(MoneyFormatter.symbolFor('JPY', locale: 'ja'), '¥');
      expect(MoneyFormatter.format(500000, 'JPY', locale: 'ja'), '¥5,000');

      // Chinese Yuan uses ¥
      expect(MoneyFormatter.symbolFor('CNY', locale: 'zh'), '¥');

      // Indian Rupee uses ₹
      expect(MoneyFormatter.symbolFor('INR', locale: 'en'), '₹');

      // Nepali Rupee uses रु in Nepali locale, and Rs in English locale
      expect(MoneyFormatter.symbolFor('NPR', locale: 'ne'), 'रु ');
      expect(MoneyFormatter.symbolFor('NPR', locale: 'en'), 'Rs ');

      // Swiss Franc uses CHF
      expect(MoneyFormatter.symbolFor('CHF', locale: 'de'), 'CHF ');
    });

    test('AppLanguage lists supported languages linked to currencies', () {
      final en = AppLanguage.fromCode('en');
      expect(en.associatedCurrencies, containsAll(['USD', 'AUD', 'CAD', 'GBP']));
      expect(en.defaultCurrencyCode, 'USD');

      final ne = AppLanguage.fromCode('ne');
      expect(ne.associatedCurrencies, contains('NPR'));
      expect(ne.defaultCurrencyCode, 'NPR');

      final ja = AppLanguage.fromCode('ja');
      expect(ja.associatedCurrencies, contains('JPY'));
      expect(ja.defaultCurrencyCode, 'JPY');

      final zh = AppLanguage.fromCode('zh');
      expect(zh.associatedCurrencies, containsAll(['CNY', 'HKD', 'SGD']));
      expect(zh.defaultCurrencyCode, 'CNY');

      final de = AppLanguage.fromCode('de');
      expect(de.associatedCurrencies, containsAll(['EUR', 'CHF']));
      expect(de.defaultCurrencyCode, 'EUR');

      final fr = AppLanguage.fromCode('fr');
      expect(fr.associatedCurrencies, containsAll(['EUR', 'CAD', 'CHF']));

      final es = AppLanguage.fromCode('es');
      expect(es.associatedCurrencies, contains('EUR'));
    });
  });
}
