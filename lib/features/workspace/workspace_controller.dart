import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_db.dart';
import '../../core/db/app_state_repository.dart';
import '../../core/db/collections_repository.dart';
import '../../core/db/history_repository.dart';
import '../../core/error/guard.dart';
import '../../core/http/api_client.dart';
import '../../core/http/request_builder.dart';
import '../../core/models/api_request.dart';
import '../../core/models/api_response.dart';
import '../../core/models/environment.dart';
import '../../core/models/history_entry.dart';
import '../../core/providers.dart';
import '../../core/util/ids.dart';

/// Where the response sheet is resting. Three stops, as the board describes:
/// the dock, half the screen, and the whole screen.
enum DockStop { collapsed, half, full }

/// One open request: the draft being edited, what was last saved, and the last
/// response it produced.
@immutable
class WorkspaceTab {
  const WorkspaceTab({
    required this.draft,
    this.saved,
    this.response,
    this.sending = false,
    this.sentAt,
    this.startedAt,
  });

  final ApiRequest draft;

  /// Null while the request has never been saved.
  final ApiRequest? saved;
  final ApiResponse? response;
  final bool sending;
  final DateTime? sentAt;

  /// When the current send started, for the dock's counter.
  final DateTime? startedAt;

  String get id => draft.id;

  /// The dot on Save. A never-saved request counts as dirty as soon as it has
  /// a URL, because there is something worth keeping.
  bool get dirty => saved == null
      ? draft.url.trim().isNotEmpty
      : !draft.sameAs(saved!);

  WorkspaceTab copyWith({
    ApiRequest? draft,
    ApiRequest? saved,
    bool clearSaved = false,
    ApiResponse? response,
    bool clearResponse = false,
    bool? sending,
    DateTime? sentAt,
    DateTime? startedAt,
    bool clearStartedAt = false,
  }) => WorkspaceTab(
    draft: draft ?? this.draft,
    saved: clearSaved ? null : (saved ?? this.saved),
    response: clearResponse ? null : (response ?? this.response),
    sending: sending ?? this.sending,
    sentAt: sentAt ?? this.sentAt,
    startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
  );
}

@immutable
class WorkspaceState {
  const WorkspaceState({
    this.tabs = const <WorkspaceTab>[],
    this.activeIndex = 0,
    this.stop = DockStop.collapsed,
    this.restored = false,
  });

  final List<WorkspaceTab> tabs;
  final int activeIndex;
  final DockStop stop;

  /// False until the open tabs have been read back from the database, so the
  /// first frame does not write an empty list over them.
  final bool restored;

  WorkspaceTab? get active =>
      activeIndex >= 0 && activeIndex < tabs.length ? tabs[activeIndex] : null;

  int get unsavedCount => tabs.where((WorkspaceTab t) => t.dirty).length;

  WorkspaceState copyWith({
    List<WorkspaceTab>? tabs,
    int? activeIndex,
    DockStop? stop,
    bool? restored,
  }) => WorkspaceState(
    tabs: tabs ?? this.tabs,
    activeIndex: activeIndex ?? this.activeIndex,
    stop: stop ?? this.stop,
    restored: restored ?? this.restored,
  );
}

/// The workspace: which requests are open, what is in each one, and what
/// happens when Send is pressed.
///
/// Drafts are persisted, so killing the app does not lose unsaved work; what
/// is persisted is the template, with `{{variable}}` intact. Resolution happens
/// in [send] and the resolved strings never leave that method.
class WorkspaceController extends Notifier<WorkspaceState> {
  final Map<String, CancelToken> _inFlight = <String, CancelToken>{};

  ApiClient get _client => ref.read(apiClientProvider);
  CollectionsRepository get _collections =>
      ref.read(collectionsRepositoryProvider);
  HistoryRepository get _history => ref.read(historyRepositoryProvider);
  AppStateRepository get _appState => ref.read(appStateRepositoryProvider);
  Environment? get _env => ref.read(activeEnvironmentProvider);

  @override
  WorkspaceState build() {
    ref.onDispose(cancelAll);
    // Reading the open tabs is a database round trip, so it happens after the
    // first frame and the workspace opens empty for one frame at most.
    unawaited(_restore());
    return const WorkspaceState();
  }

  Future<void> _restore() async {
    final String? raw = await _appState.read(StateKeys.openRequests);
    if (raw == null || raw.isEmpty) {
      state = state.copyWith(restored: true);
      return;
    }
    final List<WorkspaceTab> tabs = <WorkspaceTab>[];
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is List<Object?>) {
        for (final Object? entry in decoded) {
          if (entry is! Map<String, dynamic>) continue;
          final ApiRequest? draft = decodeOrNull<ApiRequest>(
            jsonEncode(entry),
            ApiRequest.fromJson,
            what: 'open request',
            maxSchemaVersion: ApiRequest.schema,
          );
          if (draft == null) continue;
          tabs.add(
            WorkspaceTab(
              draft: draft,
              saved: await _collections.request(draft.id),
            ),
          );
        }
      }
    } catch (error) {
      debugPrint('Could not restore open requests: $error');
    }
    state = state.copyWith(tabs: tabs, activeIndex: 0, restored: true);
  }

  Future<void> _persist() async {
    if (!state.restored) return;
    await _appState.write(
      StateKeys.openRequests,
      state.tabs.isEmpty
          ? null
          : jsonEncode(<Map<String, dynamic>>[
              for (final WorkspaceTab t in state.tabs) t.draft.toJson(),
            ]),
    );
  }

  // Opening and closing.

  /// A blank request, focused. Returns its id.
  String openBlank() {
    final ApiRequest draft = ApiRequest.blank(newId());
    _setTabs(<WorkspaceTab>[...state.tabs, WorkspaceTab(draft: draft)],
        activeIndex: state.tabs.length);
    return draft.id;
  }

  /// Opens a request that already exists, or focuses it if it is already open.
  void open(ApiRequest request) {
    final int at = state.tabs.indexWhere((WorkspaceTab t) => t.id == request.id);
    if (at >= 0) {
      state = state.copyWith(activeIndex: at, stop: DockStop.collapsed);
      return;
    }
    _setTabs(
      <WorkspaceTab>[
        ...state.tabs,
        WorkspaceTab(draft: request, saved: request),
      ],
      activeIndex: state.tabs.length,
    );
  }

  /// A request built elsewhere (a cURL paste, Explore, a history replay) that
  /// has never been saved.
  void openDraft(ApiRequest draft) {
    _setTabs(
      <WorkspaceTab>[...state.tabs, WorkspaceTab(draft: draft)],
      activeIndex: state.tabs.length,
    );
  }

  /// Reopens a history entry with the response it produced.
  void openFromHistory(HistoryEntry entry) {
    _setTabs(
      <WorkspaceTab>[
        ...state.tabs,
        WorkspaceTab(
          draft: entry.requestSnapshot.copyWith(id: newId()),
          response: ApiResponse.arrived(
            statusCode: entry.status,
            reasonPhrase: entry.reasonPhrase.isEmpty
                ? ApiClient.reasonFor(entry.status)
                : entry.reasonPhrase,
            headers: entry.headers,
            body: entry.body,
            durationMs: entry.durationMs,
            sizeBytes: entry.sizeBytes,
          ),
          sentAt: entry.sentAt,
        ),
      ],
      activeIndex: state.tabs.length,
    );
  }

  void focus(int index) => state = state.copyWith(
    activeIndex: index.clamp(0, state.tabs.length - 1),
    stop: DockStop.collapsed,
  );

  void focusId(String id) {
    final int at = state.tabs.indexWhere((WorkspaceTab t) => t.id == id);
    if (at >= 0) focus(at);
  }

  void close(String id) {
    cancel(id);
    final List<WorkspaceTab> next = <WorkspaceTab>[
      for (final WorkspaceTab t in state.tabs) if (t.id != id) t,
    ];
    _setTabs(
      next,
      activeIndex: state.activeIndex.clamp(0, next.isEmpty ? 0 : next.length - 1),
    );
  }

  /// "Close saved": everything with no unsaved edits goes.
  void closeSaved() {
    final List<WorkspaceTab> next = <WorkspaceTab>[
      for (final WorkspaceTab t in state.tabs) if (t.dirty) t,
    ];
    for (final WorkspaceTab t in state.tabs) {
      if (!t.dirty) cancel(t.id);
    }
    _setTabs(next, activeIndex: 0);
  }

  // Editing.

  void edit(ApiRequest Function(ApiRequest) change) {
    final WorkspaceTab? tab = state.active;
    if (tab == null) return;
    _replace(
      tab.copyWith(
        draft: change(tab.draft).copyWith(updatedAt: DateTime.now()),
      ),
    );
  }

  void setStop(DockStop stop) => state = state.copyWith(stop: stop);

  // Saving.

  /// Writes the draft as it stands. [folderId] and [name] come from the save
  /// sheet on a first save; afterwards Save writes in place.
  Future<void> save({String? name, String? folderId}) async {
    final WorkspaceTab? tab = state.active;
    if (tab == null) return;
    final ApiRequest saved = tab.draft.copyWith(
      name: name ?? tab.draft.name,
      folderId: folderId ?? tab.draft.folderId,
      updatedAt: DateTime.now(),
    );
    await _collections.saveRequest(saved);
    if (folderId != null) {
      await _appState.write(StateKeys.lastFolder, folderId);
    }
    _replace(tab.copyWith(draft: saved, saved: saved));
  }

  // Sending.

  /// Sends the active request and records it in history.
  ///
  /// Never throws: the client answers with a named failure instead, and the
  /// dock shows it. The token is kept so Cancel has something to cancel and so
  /// closing the tab stops the request.
  Future<void> send() async {
    final WorkspaceTab? tab = state.active;
    if (tab == null || tab.sending) return;
    if (!RequestBuilder.isSendable(tab.draft.url)) return;

    final String id = tab.id;
    final CancelToken token = CancelToken();
    _inFlight[id] = token;
    _replace(
      tab.copyWith(
        sending: true,
        startedAt: DateTime.now(),
        clearResponse: true,
      ),
    );

    final WireRequest wire = RequestBuilder.build(tab.draft, _env);
    final ApiResponse response = await _client.send(wire, cancelToken: token);
    _inFlight.remove(id);

    // The tab can have been closed, or another send started, while this one
    // was in flight.
    final int at = state.tabs.indexWhere((WorkspaceTab t) => t.id == id);
    if (at < 0) return;
    final DateTime now = DateTime.now();
    final WorkspaceTab current = state.tabs[at];
    _replace(
      current.copyWith(
        sending: false,
        response: response,
        sentAt: now,
        clearStartedAt: true,
      ),
      at: at,
    );
    // A response opens the sheet at half height; a failure stays in the dock,
    // where the retry is.
    if (response.arrived) {
      state = state.copyWith(stop: DockStop.half);
    }

    if (response.failure != FailureKind.cancelled) {
      await _history.add(
        HistoryEntry.from(
          id: newId(),
          request: current.draft,
          response: response,
          sentAt: now,
        ),
      );
    }
  }

  void cancel(String id) {
    final CancelToken? token = _inFlight.remove(id);
    if (token != null && !token.isCancelled) {
      token.cancel('cancelled by the user');
    }
    final int at = state.tabs.indexWhere((WorkspaceTab t) => t.id == id);
    if (at >= 0) {
      _replace(
        state.tabs[at].copyWith(sending: false, clearStartedAt: true),
        at: at,
      );
    }
  }

  /// Called when the workspace goes away. An in-flight request that nothing is
  /// waiting for is just a socket the OS has to clean up later.
  void cancelAll() {
    for (final CancelToken token in _inFlight.values) {
      if (!token.isCancelled) token.cancel('workspace closed');
    }
    _inFlight.clear();
  }

  void _replace(WorkspaceTab tab, {int? at}) {
    final int index = at ??
        state.tabs.indexWhere((WorkspaceTab t) => t.id == tab.id);
    if (index < 0) return;
    final List<WorkspaceTab> next = <WorkspaceTab>[...state.tabs];
    next[index] = tab;
    state = state.copyWith(tabs: next);
    unawaited(_persist());
  }

  void _setTabs(List<WorkspaceTab> tabs, {required int activeIndex}) {
    state = state.copyWith(
      tabs: tabs,
      activeIndex: tabs.isEmpty ? 0 : activeIndex.clamp(0, tabs.length - 1),
      stop: DockStop.collapsed,
    );
    unawaited(_persist());
  }
}

final NotifierProvider<WorkspaceController, WorkspaceState> workspaceProvider =
    NotifierProvider<WorkspaceController, WorkspaceState>(
      WorkspaceController.new,
    );

/// The tab the workspace screen draws. Selected on its own so editing one
/// request does not rebuild the open-requests strip.
final Provider<WorkspaceTab?> activeTabProvider = Provider<WorkspaceTab?>(
  (Ref ref) => ref.watch(workspaceProvider).active,
);
