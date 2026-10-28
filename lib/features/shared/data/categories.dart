import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';

class TransactionCategory {
  const TransactionCategory(
    this.value,
    this._defaultLabel,
    this.type, {
    this.isCustom = false,
  });

  final String value;
  final String _defaultLabel;
  final TransactionType type;
  final bool isCustom;

  String get defaultLabel => _defaultLabel;

  String get label => isCustom
      ? _defaultLabel
      : AppStrings.current().categoryLabel(value, _defaultLabel);

  Map<String, dynamic> toJson() => {
        'value': value,
        'label': _defaultLabel,
        'type': type.value,
        'isCustom': isCustom,
      };

  factory TransactionCategory.fromJson(Map<String, dynamic> json) =>
      TransactionCategory(
        json['value'] as String,
        json['label'] as String,
        TransactionType.fromValue(json['type'] as String),
        isCustom: (json['isCustom'] as bool?) ?? true,
      );
}

/// Built-in and custom categories. Keep values stable for database persistence.
abstract final class TransactionCategories {
  static const builtIn = <TransactionCategory>[
    TransactionCategory('salary', 'Salary', TransactionType.income),
    TransactionCategory('shift_pay', 'Shift pay', TransactionType.income),
    TransactionCategory('business', 'Business', TransactionType.income),
    TransactionCategory('interest', 'Interest', TransactionType.income),
    TransactionCategory('borrowing', 'Borrowing', TransactionType.income),
    TransactionCategory('debt_repayment', 'Debt Repayment', TransactionType.income),
    TransactionCategory('gift_received', 'Gift received', TransactionType.income),
    TransactionCategory('other_income', 'Other income', TransactionType.income),
    TransactionCategory('groceries', 'Groceries', TransactionType.expense),
    TransactionCategory('eating_out', 'Eating out', TransactionType.expense),
    TransactionCategory(
      'entertainment',
      'Entertainment',
      TransactionType.expense,
    ),
    TransactionCategory('transport', 'Transport', TransactionType.expense),
    TransactionCategory('bills', 'Bills', TransactionType.expense),
    TransactionCategory('lending', 'Lending', TransactionType.expense),
    TransactionCategory('debt_repayment', 'Debt Repayment', TransactionType.expense),
    TransactionCategory(
      'other_expense',
      'Other expense',
      TransactionType.expense,
    ),
  ];

  static final List<TransactionCategory> _custom = [];
  static final Map<String, List<String>> _customMerchants = {};

  static List<TransactionCategory> get all => [...builtIn, ..._custom];
  static List<TransactionCategory> get customOnly => List.unmodifiable(_custom);

  /// Suggested merchants per category value, offered as quick-fill chips.
  static const defaultMerchants = <String, List<String>>{
    'groceries': ['Woolworths', 'Coles', 'Aldi'],
    'eating_out': ["Domino's", 'KFC', "McDonald's", 'Uber Eats'],
    'entertainment': ['Netflix', 'Spotify', 'QFX', 'Prime Video'],
    'transport': ['Opal', 'Uber', 'Shell'],
    'bills': ['Rent', 'Electricity', 'Internet', 'Phone'],
  };

  static Map<String, List<String>> get suggestedMerchants {
    final merged = Map<String, List<String>>.from(defaultMerchants);
    for (final entry in _customMerchants.entries) {
      final existing = merged[entry.key] ?? [];
      final combined = <String>{...existing, ...entry.value}.toList();
      merged[entry.key] = combined;
    }
    return merged;
  }

  static void setCustomData({
    required List<TransactionCategory> customCategories,
    required Map<String, List<String>> customMerchants,
  }) {
    _custom
      ..clear()
      ..addAll(customCategories);
    _customMerchants
      ..clear()
      ..addAll(customMerchants);
  }

  static List<String> merchantsFor(String categoryOrKey) {
    final needle = categoryOrKey.trim().toLowerCase();
    final cat = find(needle, TransactionType.expense) ??
        find(needle, TransactionType.income);
    final key = cat?.value ?? needle;
    final defaults = defaultMerchants[key] ?? const [];
    final customs = _customMerchants[key] ?? const [];
    final set = <String>{...defaults, ...customs};
    return set.toList();
  }

  static List<TransactionCategory> forType(TransactionType type) =>
      all.where((category) => category.type == type).toList(growable: false);

  static TransactionCategory? find(String valueOrLabel, TransactionType type) {
    final needle = valueOrLabel.trim().toLowerCase();
    for (final category in all) {
      if (category.type == type &&
          (category.value.toLowerCase() == needle ||
              category.defaultLabel.toLowerCase() == needle ||
              category.label.toLowerCase() == needle)) {
        return category;
      }
    }
    return null;
  }

  /// Resolves any stored category key or English label into the active locale's display label.
  static String localizedCategoryName(String raw) {
    final needle = raw.trim().toLowerCase();
    for (final category in all) {
      if (category.value.toLowerCase() == needle ||
          category.defaultLabel.toLowerCase() == needle ||
          category.label.toLowerCase() == needle) {
        return category.label;
      }
    }
    return AppStrings.current().categoryLabel(raw, raw);
  }

  static TransactionCategory fromValue(String valueOrLabel, TransactionType type) =>
      find(valueOrLabel, type) ??
      all.firstWhere(
        (category) => category.type == type,
        orElse: () => all.first,
      );
}
