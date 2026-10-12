import 'package:drift/drift.dart';

/// Small key/value store for local app preferences, onboarding and defaults.
class AppPreferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
