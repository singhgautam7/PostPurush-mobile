import 'dart:convert';

import 'package:drift/drift.dart';

import '../error/guard.dart';
import '../models/environment.dart';
import 'app_db.dart';

class EnvironmentsRepository {
  EnvironmentsRepository(this._db);

  final AppDatabase _db;

  Stream<List<Environment>> watchAll() {
    final SimpleSelectStatement<Environments, EnvironmentRow> query =
        _db.select(_db.environments)
          ..orderBy(<OrderClauseGenerator<Environments>>[
            (Environments t) => OrderingTerm.asc(t.position),
          ]);
    return query.watch().map(
      (List<EnvironmentRow> rows) => decodeAll<Environment>(
        rows.map((EnvironmentRow r) => r.data),
        Environment.fromJson,
        what: 'environment',
        maxSchemaVersion: Environment.schema,
      ),
    );
  }

  Future<List<Environment>> all() async {
    final List<EnvironmentRow> rows = await (_db.select(
      _db.environments,
    )..orderBy(<OrderClauseGenerator<Environments>>[
          (Environments t) => OrderingTerm.asc(t.position),
        ]))
        .get();
    return decodeAll<Environment>(
      rows.map((EnvironmentRow r) => r.data),
      Environment.fromJson,
      what: 'environment',
      maxSchemaVersion: Environment.schema,
    );
  }

  Future<void> save(Environment env) => _db
      .into(_db.environments)
      .insertOnConflictUpdate(
        EnvironmentsCompanion.insert(
          id: env.id,
          name: Value<String>(env.name),
          position: Value<int>(env.order),
          data: jsonEncode(env.toJson()),
        ),
      );

  Future<void> delete(String id) => _db.transaction(() async {
    await (_db.delete(_db.environments)
          ..where((Environments t) => t.id.equals(id)))
        .go();
    // The active pointer must not outlive what it points at.
    final AppStateRow? active = await (_db.select(
      _db.appStates,
    )..where((AppStates t) => t.key.equals(StateKeys.activeEnvironment)))
        .getSingleOrNull();
    if (active?.value == id) {
      await (_db.delete(_db.appStates)
            ..where((AppStates t) => t.key.equals(StateKeys.activeEnvironment)))
          .go();
    }
  });

  Future<void> reorder(List<Environment> ordered) => _db.transaction(() async {
    for (int i = 0; i < ordered.length; i++) {
      await save(ordered[i].copyWith(order: i));
    }
  });

  /// Which environment fills in variables. Null is "No environment", which is
  /// a real choice and not a missing setting.
  Stream<String?> watchActiveId() {
    final SimpleSelectStatement<AppStates, AppStateRow> query =
        _db.select(_db.appStates)
          ..where((AppStates t) => t.key.equals(StateKeys.activeEnvironment));
    return query.watchSingleOrNull().map((AppStateRow? r) => r?.value);
  }

  Future<void> setActiveId(String? id) async {
    if (id == null) {
      await (_db.delete(_db.appStates)
            ..where((AppStates t) => t.key.equals(StateKeys.activeEnvironment)))
          .go();
      return;
    }
    await _db.into(_db.appStates).insertOnConflictUpdate(
      AppStatesCompanion.insert(key: StateKeys.activeEnvironment, value: id),
    );
  }
}
