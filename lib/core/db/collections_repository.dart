import 'dart:convert';

import 'package:drift/drift.dart';

import '../error/guard.dart';
import '../models/api_request.dart';
import '../models/folder.dart';
import 'app_db.dart';

/// Folders and the requests inside them. Reads are streams, so a save
/// repaints exactly the lists that watch it and nothing else.
class CollectionsRepository {
  CollectionsRepository(this._db);

  final AppDatabase _db;

  Stream<List<Folder>> watchFolders() {
    final SimpleSelectStatement<Folders, FolderRow> query = _db.select(_db.folders)
      ..orderBy(<OrderClauseGenerator<Folders>>[
        (Folders t) => OrderingTerm.asc(t.position),
        (Folders t) => OrderingTerm.asc(t.name),
      ]);
    return query.watch().map(
      (List<FolderRow> rows) => decodeAll<Folder>(
        rows.map((FolderRow r) => r.data),
        Folder.fromJson,
        what: 'folder',
        maxSchemaVersion: Folder.schema,
      ),
    );
  }

  Stream<List<ApiRequest>> watchRequests() {
    final SimpleSelectStatement<Requests, RequestRow> query =
        _db.select(_db.requests)
          ..orderBy(<OrderClauseGenerator<Requests>>[
            (Requests t) => OrderingTerm.asc(t.position),
            (Requests t) => OrderingTerm.desc(t.updatedAt),
          ]);
    return query.watch().map(
      (List<RequestRow> rows) => decodeAll<ApiRequest>(
        rows.map((RequestRow r) => r.data),
        ApiRequest.fromJson,
        what: 'request',
        maxSchemaVersion: ApiRequest.schema,
      ),
    );
  }

  Future<List<ApiRequest>> allRequests() async {
    final List<RequestRow> rows = await _db.select(_db.requests).get();
    return decodeAll<ApiRequest>(
      rows.map((RequestRow r) => r.data),
      ApiRequest.fromJson,
      what: 'request',
      maxSchemaVersion: ApiRequest.schema,
    );
  }

  Future<ApiRequest?> request(String id) async {
    final RequestRow? row = await (_db.select(
      _db.requests,
    )..where(($RequestsTable t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return decodeOrNull<ApiRequest>(
      row.data,
      ApiRequest.fromJson,
      what: 'request',
      maxSchemaVersion: ApiRequest.schema,
    );
  }

  Future<void> saveFolder(Folder folder) => _db
      .into(_db.folders)
      .insertOnConflictUpdate(
        FoldersCompanion.insert(
          id: folder.id,
          parentId: Value<String?>(folder.parentId),
          name: Value<String>(folder.name),
          position: Value<int>(folder.order),
          data: jsonEncode(folder.toJson()),
        ),
      );

  /// Deleting a folder moves its requests and subfolders up to its own parent
  /// rather than taking them with it. Losing requests to a tidy-up is not a
  /// trade the user agreed to.
  Future<void> deleteFolder(String id) => _db.transaction(() async {
    final FolderRow? row = await (_db.select(
      _db.folders,
    )..where((Folders t) => t.id.equals(id))).getSingleOrNull();
    final String? parent = row?.parentId;
    await (_db.update(_db.requests)..where((Requests t) => t.folderId.equals(id)))
        .write(RequestsCompanion(folderId: Value<String?>(parent)));
    await (_db.update(_db.folders)..where((Folders t) => t.parentId.equals(id)))
        .write(FoldersCompanion(parentId: Value<String?>(parent)));
    await (_db.delete(_db.folders)..where((Folders t) => t.id.equals(id))).go();
    await _reindexRequestPayloadFolders(id, parent);
  });

  /// The payload carries `folderId` too, so it has to follow the column.
  Future<void> _reindexRequestPayloadFolders(String from, String? to) async {
    final List<RequestRow> rows = await (_db.select(
      _db.requests,
    )..where((Requests t) => t.folderId.equalsNullable(to))).get();
    for (final RequestRow row in rows) {
      final ApiRequest? r = decodeOrNull<ApiRequest>(
        row.data,
        ApiRequest.fromJson,
        what: 'request',
        maxSchemaVersion: ApiRequest.schema,
      );
      if (r == null || r.folderId != from) continue;
      await saveRequest(r.copyWith(folderId: to));
    }
  }

  Future<void> saveRequest(ApiRequest request) => _db
      .into(_db.requests)
      .insertOnConflictUpdate(
        RequestsCompanion.insert(
          id: request.id,
          folderId: Value<String?>(request.folderId),
          name: Value<String>(request.name),
          method: Value<String>(request.method.label),
          url: Value<String>(request.url),
          position: Value<int>(request.order),
          updatedAt: Value<int>(request.updatedAt.millisecondsSinceEpoch),
          data: jsonEncode(request.toJson()),
        ),
      );

  Future<void> deleteRequest(String id) =>
      (_db.delete(_db.requests)..where((Requests t) => t.id.equals(id))).go();

  /// Writes a new order in one transaction, so a reorder never leaves the list
  /// half-renumbered if the app is killed mid-drag.
  Future<void> reorderRequests(List<ApiRequest> ordered) =>
      _db.transaction(() async {
        for (int i = 0; i < ordered.length; i++) {
          await saveRequest(ordered[i].copyWith(order: i));
        }
      });

  Future<void> reorderFolders(List<Folder> ordered) => _db.transaction(() async {
    for (int i = 0; i < ordered.length; i++) {
      await saveFolder(ordered[i].copyWith(order: i));
    }
  });

  /// How many requests sit in a folder, counting its subfolders.
  ///
  /// For one folder. A screen that draws the whole tree builds a [FolderIndex]
  /// instead: this walks every folder and every request per call, so calling
  /// it once per row is quadratic in the number of folders.
  static int countIn(
    String folderId,
    List<Folder> folders,
    List<ApiRequest> requests,
  ) {
    final Set<String> ids = <String>{folderId};
    // Folders are a shallow tree in practice; one pass per level is enough and
    // avoids recursion over a cycle a corrupt payload could introduce.
    bool grew = true;
    while (grew) {
      grew = false;
      for (final Folder f in folders) {
        if (f.parentId != null && ids.contains(f.parentId) && ids.add(f.id)) {
          grew = true;
        }
      }
    }
    return requests.where((ApiRequest r) => ids.contains(r.folderId)).length;
  }
}

/// The folder tree, worked out once: who sits under whom, what is in each
/// folder, and the count each row prints.
///
/// Collections used to derive all of this per row, from the two flat lists, so
/// drawing the tree cost roughly folders squared times requests. This is two
/// passes and a walk, and every row is then a map lookup.
class FolderIndex {
  FolderIndex._(this.children, this.requestsIn, this.totals);

  factory FolderIndex.of(List<Folder> folders, List<ApiRequest> requests) {
    final Map<String?, List<Folder>> children = <String?, List<Folder>>{};
    for (final Folder f in folders) {
      (children[f.parentId] ??= <Folder>[]).add(f);
    }
    final Map<String?, List<ApiRequest>> requestsIn =
        <String?, List<ApiRequest>>{};
    for (final ApiRequest r in requests) {
      (requestsIn[r.folderId] ??= <ApiRequest>[]).add(r);
    }

    // Totals bottom-up, iteratively and with a seen set, so a parent cycle in
    // a corrupt payload cannot hang the home screen.
    final Map<String, int> totals = <String, int>{};
    final Set<String> seen = <String>{};
    int walk(Folder folder) {
      if (!seen.add(folder.id)) return totals[folder.id] ?? 0;
      int sum = requestsIn[folder.id]?.length ?? 0;
      for (final Folder child in children[folder.id] ?? const <Folder>[]) {
        sum += walk(child);
      }
      return totals[folder.id] = sum;
    }

    for (final Folder f in folders) {
      walk(f);
    }
    return FolderIndex._(children, requestsIn, totals);
  }

  final Map<String?, List<Folder>> children;
  final Map<String?, List<ApiRequest>> requestsIn;
  final Map<String, int> totals;

  List<Folder> get roots => children[null] ?? const <Folder>[];
  List<ApiRequest> get unfiled => requestsIn[null] ?? const <ApiRequest>[];

  List<Folder> childrenOf(String id) => children[id] ?? const <Folder>[];
  List<ApiRequest> requestsOf(String id) =>
      requestsIn[id] ?? const <ApiRequest>[];

  /// Requests in the folder and everything under it.
  int totalIn(String id) => totals[id] ?? 0;
}
