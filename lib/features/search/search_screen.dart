import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/transitions.dart';
import '../../core/models/api_request.dart';
import '../../core/models/explore_api.dart';
import '../../core/models/folder.dart';
import '../../core/models/history_entry.dart';
import '../../core/providers.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/chips.dart';
import '../../core/widgets/fields.dart';
import '../explore/explore_repository.dart';
import '../explore/explore_screen.dart';
import '../history/history_screen.dart';
import '../workspace/workspace_controller.dart';

enum _Scope { requests, history, apis }

/// Board 1.3. One query covers saved requests, history and the Explore
/// catalogue, with a count on each segment.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _query = TextEditingController();
  _Scope _scope = _Scope.requests;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final String q = _query.text.trim().toLowerCase();

    final List<ApiRequest> requests = <ApiRequest>[
      for (final ApiRequest r in ref.watch(requestsProvider).value ??
          const <ApiRequest>[])
        if (q.isEmpty ||
            r.name.toLowerCase().contains(q) ||
            r.url.toLowerCase().contains(q))
          r,
    ];
    final List<HistoryEntry> history = <HistoryEntry>[
      for (final HistoryEntry e in ref.watch(historyProvider).value ??
          const <HistoryEntry>[])
        if (q.isEmpty ||
            e.name.toLowerCase().contains(q) ||
            e.path.toLowerCase().contains(q) ||
            e.host.toLowerCase().contains(q))
          e,
    ];
    final List<ExploreApi> apis = <ExploreApi>[
      for (final ExploreApi api in ref.watch(exploreApisProvider).value ??
          const <ExploreApi>[])
        if (q.isNotEmpty && api.matches(q)) api,
    ];

    final Map<String, String> folderNames = <String, String>{
      for (final Folder f in ref.watch(foldersProvider).value ??
          const <Folder>[])
        f.id: f.name,
    };

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const AppHeader(title: 'Search'),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.screen,
                Space.xs,
                Space.screen,
                Space.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: Space.lg,
                children: <Widget>[
                  SearchField(
                    controller: _query,
                    hint: 'Search requests, history and APIs',
                    onChanged: (_) => setState(() {}),
                  ),
                  SegmentedToggle<_Scope>(
                    options: const <(_Scope, String)>[
                      (_Scope.requests, 'Requests'),
                      (_Scope.history, 'History'),
                      (_Scope.apis, 'APIs'),
                    ],
                    badges: <Object?, String>{
                      _Scope.requests: '${requests.length}',
                      _Scope.history: '${history.length}',
                      _Scope.apis: '${apis.length}',
                    },
                    selected: _scope,
                    onChanged: (_Scope value) => setState(() => _scope = value),
                  ),
                ],
              ),
            ),
            Expanded(
              // The three scopes occupy the same area, so the swap is a
              // cross-fade rather than a cut.
              child: AppSwitcher(
                child: KeyedSubtree(
                  key: ValueKey<_Scope>(_scope),
                  child: q.isEmpty && _scope == _Scope.apis
                      ? const _Hint(
                          text:
                              'Type to search the bundled catalogue of public '
                              'APIs.',
                        )
                      : _results(q, requests, history, apis, folderNames, c),
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: c.surface,
    );
  }

  Widget _results(
    String q,
    List<ApiRequest> requests,
    List<HistoryEntry> history,
    List<ExploreApi> apis,
    Map<String, String> folderNames,
    AppColors c,
  ) {
    switch (_scope) {
      case _Scope.requests:
        if (requests.isEmpty) {
          return _Hint(
            text: q.isEmpty
                ? 'Your saved requests show up here.'
                : 'No saved request matches "$q".',
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.screen,
            0,
            Space.screen,
            Space.bottomSafe,
          ),
          children: <Widget>[
            RowGroup(
              children: <Widget>[
                for (final ApiRequest r in requests)
                  InkWell(
                    onTap: () {
                      ref.read(workspaceProvider.notifier).open(r);
                      context.go(Routes.workspace);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Space.lg,
                        vertical: Space.md,
                      ),
                      child: Row(
                        spacing: Space.md,
                        children: <Widget>[
                          MethodChip(r.method),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 3,
                              children: <Widget>[
                                Text(
                                  r.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppType.titleMedium.copyWith(
                                    color: c.onSurface,
                                  ),
                                ),
                                _Highlighted(
                                  text: r.url.replaceFirst(
                                    RegExp('^https?://'),
                                    '',
                                  ),
                                  query: q,
                                ),
                                if (r.folderId != null)
                                  Text(
                                    folderNames[r.folderId] ?? 'Deleted folder',
                                    style: AppType.monoLabel.copyWith(
                                      color: c.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      case _Scope.history:
        if (history.isEmpty) {
          return _Hint(
            text: q.isEmpty
                ? 'Everything you send shows up here.'
                : 'Nothing in history matches "$q".',
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.screen,
            0,
            Space.screen,
            Space.bottomSafe,
          ),
          children: <Widget>[
            RowGroup(
              children: <Widget>[
                for (final HistoryEntry e in history.take(60))
                  HistoryRow(
                    entry: e,
                    onTap: () {
                      ref.read(workspaceProvider.notifier).openFromHistory(e);
                      context.go(Routes.workspace);
                    },
                  ),
              ],
            ),
          ],
        );
      case _Scope.apis:
        if (apis.isEmpty) return _Hint(text: 'No API matches "$q".');
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.screen,
            0,
            Space.screen,
            Space.bottomSafe,
          ),
          children: <Widget>[
            RowGroup(
              children: <Widget>[
                for (final ExploreApi api in apis.take(60)) ApiRow(api: api),
              ],
            ),
          ],
        );
    }
  }
}

/// A match tinted the way the board tints it: `primaryContainer` behind the run
/// that matched.
class _Highlighted extends StatelessWidget {
  const _Highlighted({required this.text, required this.query});

  final String text;
  final String query;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final TextStyle base = AppType.monoTabular.copyWith(
      fontSize: 12,
      color: c.onSurfaceVariant,
    );
    if (query.isEmpty) {
      return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: base);
    }
    final String lower = text.toLowerCase();
    final List<InlineSpan> spans = <InlineSpan>[];
    int at = 0;
    while (true) {
      final int found = lower.indexOf(query, at);
      if (found < 0) {
        spans.add(TextSpan(text: text.substring(at)));
        break;
      }
      if (found > at) spans.add(TextSpan(text: text.substring(at, found)));
      spans.add(
        TextSpan(
          text: text.substring(found, found + query.length),
          style: base.copyWith(
            color: c.onPrimaryContainer,
            backgroundColor: c.primaryContainer,
          ),
        ),
      );
      at = found + query.length;
    }
    return Text.rich(
      TextSpan(children: spans, style: base),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      Space.screen,
      Space.sm,
      Space.screen,
      Space.bottomSafe,
    ),
    child: Text(
      text,
      style: AppType.body.copyWith(color: context.colors.onSurfaceVariant),
    ),
  );
}
