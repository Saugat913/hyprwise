import 'package:intl/intl.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';

String? _activeLocale([String? locale]) {
  try {
    final target = locale ??
        (getIt.isRegistered<SettingsRepository>()
            ? getIt<SettingsRepository>().localeCode
            : null);
    if (target == null || target == 'en') return null;
    return target;
  } catch (_) {
    return null;
  }
}

String _safeFormat(String pattern, DateTime date, [String? locale]) {
  final loc = _activeLocale(locale);
  if (loc != null) {
    try {
      return DateFormat(pattern, loc).format(date);
    } catch (_) {}
  }
  try {
    return DateFormat(pattern).format(date);
  } catch (_) {
    return date.toIso8601String();
  }
}

String _safeNamedFormat(DateFormat Function(String? loc) builder, DateTime date, [String? locale]) {
  final loc = _activeLocale(locale);
  if (loc != null) {
    try {
      return builder(loc).format(date);
    } catch (_) {}
  }
  try {
    return builder(null).format(date);
  } catch (_) {
    return date.toIso8601String();
  }
}

/// Centralized, locale-aware date formatting.
abstract final class DateFormatter {
  static String monthYear(DateTime date, {String? locale}) =>
      _safeNamedFormat(DateFormat.yMMMM, date, locale);

  static String monthShort(DateTime date, {String? locale}) =>
      _safeNamedFormat(DateFormat.MMM, date, locale);

  static String day(DateTime date, {String? locale}) =>
      _safeNamedFormat(DateFormat.d, date, locale);

  static String numeric(DateTime date, {String? locale}) =>
      _safeNamedFormat(DateFormat.yMd, date, locale);

  static String weekdayDate(DateTime date, {String? locale}) =>
      _safeNamedFormat(DateFormat.MMMEd, date, locale);

  static String time(DateTime date, {String? locale}) =>
      _safeNamedFormat(DateFormat.jm, date, locale);

  static String monthDayTime(DateTime date, {String? locale}) =>
      _safeNamedFormat((loc) => DateFormat.MMMd(loc).add_jm(), date, locale);

  /// Human-friendly relative label such as `Today`, `Yesterday`, `in 3 days`, localized.
  static String relative(DateTime date, {DateTime? now, String? locale}) {
    final reference = AppDate.dateOnly(now ?? DateTime.now());
    final target = AppDate.dateOnly(date);
    final days = target.difference(reference).inDays;
    final loc = (_activeLocale(locale) ?? 'en').toLowerCase();

    if (days == 0) {
      switch (loc) {
        case 'ne':
          return 'आज';
        case 'es':
          return 'Hoy';
        case 'fr':
          return "Aujourd'hui";
        case 'de':
          return 'Heute';
        case 'ja':
          return '今日';
        case 'zh':
          return '今天';
        case 'it':
          return 'Oggi';
        default:
          return 'Today';
      }
    }
    if (days == 1) {
      switch (loc) {
        case 'ne':
          return 'भोलि';
        case 'es':
          return 'Mañana';
        case 'fr':
          return 'Demain';
        case 'de':
          return 'Morgen';
        case 'ja':
          return '明日';
        case 'zh':
          return '明天';
        case 'it':
          return 'Domani';
        default:
          return 'Tomorrow';
      }
    }
    if (days == -1) {
      switch (loc) {
        case 'ne':
          return 'हिजो';
        case 'es':
          return 'Ayer';
        case 'fr':
          return 'Hier';
        case 'de':
          return 'Gestern';
        case 'ja':
          return '昨日';
        case 'zh':
          return '昨天';
        case 'it':
          return 'Ieri';
        default:
          return 'Yesterday';
      }
    }
    if (days > 1 && days < 7) {
      switch (loc) {
        case 'ne':
          return '$days दिनमा';
        case 'es':
          return 'En $days días';
        case 'fr':
          return 'Dans $days jours';
        case 'de':
          return 'In $days Tagen';
        case 'ja':
          return '$days日後';
        case 'zh':
          return '$days天后';
        case 'it':
          return 'Tra $days giorni';
        default:
          return 'In $days days';
      }
    }
    if (days < -1 && days > -7) {
      final past = -days;
      switch (loc) {
        case 'ne':
          return '$past दिन अगाडि';
        case 'es':
          return 'Hace $past días';
        case 'fr':
          return 'Il y a $past jours';
        case 'de':
          return 'Vor $past Tagen';
        case 'ja':
          return '$past日前';
        case 'zh':
          return '$past天前';
        case 'it':
          return '$past giorni fa';
        default:
          return '$past days ago';
      }
    }
    return numeric(date, locale: locale);
  }
}

/// Small date helpers shared across features.
abstract final class AppDate {
  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  static DateTime startOfMonth(DateTime date) =>
      DateTime(date.year, date.month);

  static DateTime endOfMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);

  static int daysInMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0).day;

  static List<DateTime> monthGrid(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final offset = first.weekday - DateTime.monday;
    final start = first.subtract(Duration(days: offset));
    return List.generate(42, (index) => start.add(Duration(days: index)));
  }

  static String header(DateTime date, {String? locale}) =>
      _safeFormat('EEEE, d MMM', date, locale);
  static String short(DateTime date, {String? locale}) =>
      _safeFormat('d MMM', date, locale);
  static String weekday(DateTime date, {String? locale}) =>
      _safeFormat('EEE', date, locale);
  static String weekdayDay(DateTime date, {String? locale}) =>
      _safeFormat('EEE d', date, locale);
  static String monthYear(DateTime date, {String? locale}) =>
      _safeFormat('MMMM y', date, locale);
  static String timeOnly(DateTime date, {String? locale}) =>
      _safeFormat('h:mm a', date, locale).toLowerCase();
}
