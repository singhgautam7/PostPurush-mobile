import 'package:drift/drift.dart';

import 'app_db.dart';

/// The small pieces of state that belong with the data: which requests are
/// open, the folder the last save went to, the language code export used last.
class AppStateRepository {
  AppStateRepository(this._db);

  final AppDatabase _db;

  Future<String?> read(String key) async {
    final AppStateRow? row = await (_db.select(
      _db.appStates,
    )..where((AppStates t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Stream<String?> watch(String key) {
    final SimpleSelectStatement<AppStates, AppStateRow> query =
        _db.select(_db.appStates)..where((AppStates t) => t.key.equals(key));
    return query.watchSingleOrNull().map((AppStateRow? r) => r?.value);
  }

  Future<void> write(String key, String? value) async {
    if (value == null) {
      await (_db.delete(_db.appStates)..where((AppStates t) => t.key.equals(key)))
          .go();
      return;
    }
    await _db.into(_db.appStates).insertOnConflictUpdate(
      AppStatesCompanion.insert(key: key, value: value),
    );
  }

  Future<List<String>> readList(String key) async {
    final String? raw = await read(key);
    if (raw == null || raw.isEmpty) return const <String>[];
    return raw.split('\u0000').where((String s) => s.isNotEmpty).toList();
  }

  Future<void> writeList(String key, List<String> values) =>
      write(key, values.isEmpty ? null : values.join('\u0000'));
}
