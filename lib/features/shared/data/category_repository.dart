import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/shared/data/categories.dart';

/// Manages custom user-defined categories and learned merchants,
/// persisting them to the [AppPreferences] table in SQLite.
class CategoryRepository extends ChangeNotifier {
  CategoryRepository(this._db);

  final AppDatabase _db;

  static const _keyCustomCategories = 'custom_categories_json';
  static const _keyCustomMerchants = 'custom_merchants_json';

  List<TransactionCategory> _customCategories = [];
  Map<String, List<String>> _customMerchants = {};

  List<TransactionCategory> get customCategories => List.unmodifiable(_customCategories);
  Map<String, List<String>> get customMerchants => Map.unmodifiable(_customMerchants);

  Future<void> load() async {
    final rows = await (_db.select(_db.appPreferences)
          ..where((tbl) => tbl.key.isIn([_keyCustomCategories, _keyCustomMerchants])))
        .get();

    final map = {for (final r in rows) r.key: r.value};

    if (map.containsKey(_keyCustomCategories)) {
      try {
        final decoded = jsonDecode(map[_keyCustomCategories]!) as List<dynamic>;
        _customCategories = decoded
            .map((item) => TransactionCategory.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Failed to decode custom categories: $e');
        _customCategories = [];
      }
    }

    if (map.containsKey(_keyCustomMerchants)) {
      try {
        final decoded = jsonDecode(map[_keyCustomMerchants]!) as Map<String, dynamic>;
        _customMerchants = decoded.map(
          (k, v) => MapEntry(k, (v as List<dynamic>).map((e) => e.toString()).toList()),
        );
      } catch (e) {
        debugPrint('Failed to decode custom merchants: $e');
        _customMerchants = {};
      }
    }

    _sync();
    notifyListeners();
  }

  void _sync() {
    TransactionCategories.setCustomData(
      customCategories: _customCategories,
      customMerchants: _customMerchants,
    );
  }

  Future<void> _persistCategories() async {
    final jsonStr = jsonEncode(_customCategories.map((c) => c.toJson()).toList());
    await _db.into(_db.appPreferences).insertOnConflictUpdate(
          AppPreferencesCompanion(
            key: const Value(_keyCustomCategories),
            value: Value(jsonStr),
          ),
        );
  }

  Future<void> _persistMerchants() async {
    final jsonStr = jsonEncode(_customMerchants);
    await _db.into(_db.appPreferences).insertOnConflictUpdate(
          AppPreferencesCompanion(
            key: const Value(_keyCustomMerchants),
            value: Value(jsonStr),
          ),
        );
  }

  /// Adds a new custom category.
  Future<TransactionCategory> addCategory({
    required String label,
    required TransactionType type,
  }) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Category name cannot be empty');
    }

    final slug = trimmed
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    final value = slug.isEmpty ? 'cat_${DateTime.now().millisecondsSinceEpoch}' : slug;

    // Check if category already exists
    final existing = TransactionCategories.find(value, type) ?? TransactionCategories.find(trimmed, type);
    if (existing != null) {
      return existing;
    }

    final newCat = TransactionCategory(value, trimmed, type, isCustom: true);
    _customCategories.add(newCat);
    _sync();
    await _persistCategories();
    notifyListeners();
    return newCat;
  }

  /// Deletes a custom category by value.
  Future<void> deleteCategory(String value) async {
    _customCategories.removeWhere((c) => c.value == value);
    _customMerchants.remove(value);
    _sync();
    await _persistCategories();
    await _persistMerchants();
    notifyListeners();
  }

  /// Learns/adds a merchant to a category for quick chips suggestion.
  Future<void> addMerchant({
    required String categoryKey,
    required String merchant,
  }) async {
    final trimmedMerchant = merchant.trim();
    if (trimmedMerchant.isEmpty || trimmedMerchant.toLowerCase() == 'other') return;

    final key = categoryKey.trim().toLowerCase();
    final list = _customMerchants[key] ?? [];
    final inDefault = TransactionCategories.defaultMerchants[key]
            ?.any((m) => m.toLowerCase() == trimmedMerchant.toLowerCase()) ??
        false;
    final inCustom =
        list.any((m) => m.toLowerCase() == trimmedMerchant.toLowerCase());
    if (!inDefault && !inCustom) {
      list.add(trimmedMerchant);
      _customMerchants[key] = list;
      _sync();
      await _persistMerchants();
      notifyListeners();
    }
  }

  /// Removes a custom merchant shortcut from a category.
  Future<void> removeMerchant({
    required String categoryKey,
    required String merchant,
  }) async {
    final key = categoryKey.trim().toLowerCase();
    final list = _customMerchants[key];
    if (list != null) {
      list.removeWhere((m) => m.toLowerCase() == merchant.trim().toLowerCase());
      _customMerchants[key] = list;
      _sync();
      await _persistMerchants();
      notifyListeners();
    }
  }
}
