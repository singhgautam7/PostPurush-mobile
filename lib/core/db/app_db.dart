import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_db.g.dart';

/// Every table keeps its model as one JSON payload in `data`, alongside the
/// few columns a query actually filters or sorts on.
///
/// That split is deliberate. The payload carries its own `schemaVersion`, so a
/// model gaining a field is a code change and not a database migration, and a
/// row written by a newer build is skipped on read instead of crashing the
/// list. The indexed columns are what the collections list, search, history
/// and analytics read, so none of them has to decode a payload to draw a row.
@DataClassName('FolderRow')
class Folders extends Table {
  TextColumn get id => text()();
  TextColumn get parentId => text().nullable()();
  TextColumn get name => text().withDefault(const Constant<String>(''))();
  IntColumn get position => integer().withDefault(const Constant<int>(0))();
  TextColumn get data => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('RequestRow')
class Requests extends Table {
  TextColumn get id => text()();
  TextColumn get folderId => text().nullable()();
  TextColumn get name => text().withDefault(const Constant<String>(''))();
  TextColumn get method => text().withDefault(const Constant<String>('GET'))();
  TextColumn get url => text().withDefault(const Constant<String>(''))();
  IntColumn get position => integer().withDefault(const Constant<int>(0))();
  IntColumn get updatedAt => integer().withDefault(const Constant<int>(0))();
  TextColumn get data => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('EnvironmentRow')
class Environments extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withDefault(const Constant<String>(''))();
  IntColumn get position => integer().withDefault(const Constant<int>(0))();
  TextColumn get data => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('HistoryRow')
class HistoryEntries extends Table {
  TextColumn get id => text()();

  /// Milliseconds since epoch. Indexed: every history and analytics query
  /// orders or windows on it.
  IntColumn get sentAt => integer()();
  IntColumn get status => integer().withDefault(const Constant<int>(0))();
  IntColumn get durationMs => integer().withDefault(const Constant<int>(0))();
  IntColumn get sizeBytes => integer().withDefault(const Constant<int>(0))();
  TextColumn get method => text().withDefault(const Constant<String>('GET'))();
  TextColumn get host => text().withDefault(const Constant<String>(''))();
  TextColumn get path => text().withDefault(const Constant<String>(''))();
  TextColumn get name => text().withDefault(const Constant<String>(''))();
  TextColumn get folderId => text().nullable()();
  TextColumn get data => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Small pieces of app state that belong with the data rather than with the
/// device settings: which environment is active, which requests are open, the
/// folder the last save went to.
@DataClassName('AppStateRow')
class AppStates extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{key};
}

@DriftDatabase(
  tables: <Type>[Folders, Requests, Environments, HistoryEntries, AppStates],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  /// For tests: an in-memory database with the same schema.
  AppDatabase.forTesting(super.connection);

  static QueryExecutor _open() =>
      driftDatabase(name: 'postpurush', native: const DriftNativeOptions());

  /// One. The payloads carry their own versions, so the table shape only
  /// changes when a new index or table is needed.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (OpeningDetails details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      // The queries that matter are all on these columns; without the indexes
      // history and analytics degrade into a table scan as the log grows.
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_history_sent_at '
        'ON history_entries (sent_at DESC)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_history_status '
        'ON history_entries (status)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_requests_folder '
        'ON requests (folder_id, position)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_folders_parent '
        'ON folders (parent_id, position)',
      );
    },
  );
}

/// The keys used in [AppStates]. One place, so a typo is a compile error.
abstract final class StateKeys {
  static const String activeEnvironment = 'env.active';
  static const String openRequests = 'workspace.open';
  static const String lastFolder = 'save.lastFolder';
  static const String lastExportLanguage = 'export.language';
}
