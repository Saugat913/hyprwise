import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_categories.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_type.dart';

void main() {
  group('TransactionCategories', () {
    test('category keys are unique', () {
      final values = TransactionCategories.all.map((category) => category.value);

      expect(values.toSet().length, values.length);
    });

    test('categories returned for a type match that type', () {
      for (final type in TransactionType.values) {
        final categories = TransactionCategories.forType(type);

        expect(categories, isNotEmpty);
        expect(categories.every((category) => category.type == type), isTrue);
      }
    });

    test('unknown category safely falls back to a category of its type', () {
      for (final type in TransactionType.values) {
        expect(
          TransactionCategories.fromValue('not_a_category', type).type,
          type,
        );
      }
    });

    test('category lookup rejects a category from another transaction type', () {
      expect(
        TransactionCategories.find('salary', TransactionType.expense),
        isNull,
      );
      expect(
        TransactionCategories.find('food', TransactionType.expense),
        isNotNull,
      );
    });
  });
}
