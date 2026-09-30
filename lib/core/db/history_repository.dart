import 'dart:convert';

import 'package:drift/drift.dart';

import '../error/guard.dart';
import '../models/history_entry.dart';
import 'app_db.dart';

/// One row per send. The list, Search, Analytics and the load test's "recent"
/// block all read this table, so a row carries denormalised columns and the
/// queries never decode a payload to draw or group.
class HistoryRepository {
  HistoryRepository(this._db);

  final AppDatabase _db;

  /// How many rows a single page of history loads. The list is virtualised, so
  /// this is about the query, not about the scroll.
  static const int pageSize = 200;

  /// The most recent entries, newest first. [limit] keeps a 30-day log from
  /// being decoded whole to fill one screen.
  Stream<List<HistoryEntry>> watchRecent({int limit = pageSize}) {
    final SimpleSelectStatement<HistoryEntries, HistoryRow> query =
        _db.select(_db.historyEntries)
          ..orderBy(<OrderClauseGenerator<HistoryEntries>>[
            (HistoryEntries t) => OrderingTerm.desc(t.sentAt),
          ])
          ..limit(limit);
    return query.watch().map(_decode);
  }

  /// Every entry inside a window, for Analytics. Only the columns are read:
  /// the payload is left on disk, because nothing on that page needs it.
  Future<List<HistoryStat>> statsSince(DateTime? since) async {
    final SimpleSelectStatement<HistoryEntries, HistoryRow> query =
        _db.select(_db.historyEntries)
          ..orderBy(<OrderClauseGenerator<HistoryEntries>>[
            (HistoryEntries t) => OrderingTerm.asc(t.sentAt),
          ]);
    if (since != null) {
      query.where(
        (HistoryEntries t) =>
            t.sentAt.isBiggerOrEqualValue(since.millisecondsSinceEpoch),
      );
    }
    final List<HistoryRow> rows = await query.get();
    return rows
        .map(
          (HistoryRow r) => HistoryStat(
            sentAt: DateTime.fromMillisecondsSinceEpoch(r.sentAt),
            status: r.status,
            durationMs: r.durationMs,
            host: r.host,
            path: r.path,
            folderId: r.folderId,
            name: r.name,
          ),
        )
        .toList(growable: false);
  }

  /// A count and a window is all the More screen's row needs.
  Future<int> countSince(DateTime? since) async {
    final Expression<int> count = _db.historyEntries.id.count();
    final JoinedSelectStatement<HasResultSet, dynamic> query =
        _db.selectOnly(_db.historyEntries)..addColumns(<Expression<int>>[count]);
    if (since != null) {
      query.where(
        _db.historyEntries.sentAt.isBiggerOrEqualValue(
          since.millisecondsSinceEpoch,
        ),
      );
    }
    final TypedResult row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<List<HistoryEntry>> search(String query, {int limit = 50}) async {
    final String like = '%${query.trim()}%';
    final SimpleSelectStatement<HistoryEntries, HistoryRow> q =
        _db.select(_db.historyEntries)
          ..where(
            (HistoryEntries t) =>
                t.name.like(like) | t.path.like(like) | t.host.like(like),
          )
          ..orderBy(<OrderClauseGenerator<HistoryEntries>>[
            (HistoryEntries t) => OrderingTerm.desc(t.sentAt),
          ])
          ..limit(limit);
    return _decode(await q.get());
  }

  Future<HistoryEntry?> entry(String id) async {
    final HistoryRow? row = await (_db.select(
      _db.historyEntries,
    )..where((HistoryEntries t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return decodeOrNull<HistoryEntry>(
      row.data,
      HistoryEntry.fromJson,
      what: 'history entry',
      maxSchemaVersion: HistoryEntry.schema,
    );
  }

  Future<void> add(HistoryEntry entry) => _db
      .into(_db.historyEntries)
      .insertOnConflictUpdate(
        HistoryEntriesCompanion.insert(
          id: entry.id,
          sentAt: entry.sentAt.millisecondsSinceEpoch,
          status: Value<int>(entry.status),
          durationMs: Value<int>(entry.durationMs),
          sizeBytes: Value<int>(entry.sizeBytes),
          method: Value<String>(entry.method.label),
          host: Value<String>(entry.host),
          path: Value<String>(entry.path),
          name: Value<String>(entry.name),
          folderId: Value<String?>(entry.folderId),
          data: jsonEncode(entry.toJson()),
        ),
      );

  Future<void> delete(String id) => (_db.delete(_db.historyEntries)
        ..where((HistoryEntries t) => t.id.equals(id)))
      .go();

  Future<void> clear() => _db.delete(_db.historyEntries).go();

  /// Drops everything older than the retention setting. Called once on launch,
  /// off the first frame, so history cannot grow without bound.
  Future<int> prune({required int keepDays}) {
    final int cutoff = DateTime.now()
        .subtract(Duration(days: keepDays))
        .millisecondsSinceEpoch;
    return (_db.delete(_db.historyEntries)
          ..where((HistoryEntries t) => t.sentAt.isSmallerThanValue(cutoff)))
        .go();
  }

  List<HistoryEntry> _decode(List<HistoryRow> rows) => decodeAll<HistoryEntry>(
    rows.map((HistoryRow r) => r.data),
    HistoryEntry.fromJson,
    what: 'history entry',
    maxSchemaVersion: HistoryEntry.schema,
  );
}

/// The columns Analytics reads, without the payload. Keeping this separate is
/// what lets a 30-day range be summarised without decoding a single body.
class HistoryStat {
  const HistoryStat({
    required this.sentAt,
    required this.status,
    required this.durationMs,
    required this.host,
    required this.path,
    required this.folderId,
    required this.name,
  });

  final DateTime sentAt;
  final int status;
  final int durationMs;
  final String host;
  final String path;
  final String? folderId;
  final String name;
}
