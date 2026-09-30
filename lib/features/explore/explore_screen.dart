import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/api_request.dart';
import '../../core/models/explore_api.dart';
import '../../core/models/folder.dart';
import '../../core/providers.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/util/format.dart';
import '../../core/util/ids.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_icon_button.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/chips.dart';
import '../../core/widgets/fields.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/states.dart';
import '../workspace/workspace_controller.dart';
import '../../core/db/collections_repository.dart';
import '../workspace/save_request_sheet.dart';
import 'explore_repository.dart';

/// Board 03. A bundled, offline catalogue. Every API in it is callable, because
/// a native request is not subject to CORS, so there are no CORS warnings here.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    // The field mirrors the shared filter, so arriving from Search keeps it.
    _search.text = ref.read(exploreFiltersProvider).query;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AsyncValue<List<ExploreApi>> apis = ref.watch(exploreApisProvider);
    final ExploreFilters filters = ref.watch(exploreFiltersProvider);
    final List<ExploreCategory> categories = ref.watch(
      exploreCategoriesProvider,
    );
    final List<ExploreApi> all = apis.value ?? const <ExploreApi>[];
    final List<ExploreApi> matching = <ExploreApi>[
      for (final ExploreApi api in all) if (filters.accepts(api)) api,
    ];
    final List<ExploreApi> ready = <ExploreApi>[
      for (final ExploreApi api in matching) if (api.readyToCall) api,
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CollapseOnScroll(
          builder: (BuildContext context, bool collapsed) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppHeader(
                title: 'Explore',
                subtitle: apis.isLoading
                    ? 'loading the catalogue'
                    : '${Fmt.thousands(all.length)} public APIs · works offline',
                collapsed: collapsed,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.screen,
                  Space.xs,
                  Space.screen,
                  Space.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: Space.md,
                  children: <Widget>[
                    SearchField(
                      controller: _search,
                      hint: 'Search name, category or host',
                      onChanged: (String value) => ref
                          .read(exploreFiltersProvider.notifier)
                          .setQuery(value),
                    ),
                    const _FilterRow(),
                  ],
                ),
              ),
              Expanded(
                child: apis.isLoading
                    ? const Delayed(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: Space.screen,
                          ),
                          child: RowGroup(
                            children: <Widget>[SkeletonRow(), SkeletonRow()],
                          ),
                        ),
                      )
                    : apis.hasError
                        ? ErrorStateView(
                            message:
                                'The bundled catalogue could not be read.',
                            onRetry: () => ref.invalidate(exploreApisProvider),
                          )
                        : matching.isEmpty
                            ? _NoResults(
                                filters: filters,
                                all: all,
                                onClearSearch: () {
                                  _search.clear();
                                  ref
                                      .read(exploreFiltersProvider.notifier)
                                      .setQuery('');
                                },
                              )
                            : ListView(
                                padding: const EdgeInsets.fromLTRB(
                                  Space.screen,
                                  0,
                                  Space.screen,
                                  Space.bottomSafe,
                                ),
                                children: <Widget>[
                                  if (ready.isNotEmpty && !filters.any) ...<Widget>[
                                    SectionHeader(
                                      label: 'Ready to call',
                                      note: 'no auth needed · ${ready.length}',
                                    ),
                                    const SizedBox(height: Space.row),
                                    for (final ExploreApi api in ready.take(4))
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: Space.row,
                                        ),
                                        child: _ReadyCard(api: api),
                                      ),
                                    const SizedBox(height: Space.md),
                                  ],
                                  if (filters.any) ...<Widget>[
                                    SectionHeader(
                                      label: 'Matches · ${matching.length}',
                                      note: 'of ${all.length}',
                                    ),
                                    const SizedBox(height: Space.row),
                                    RowGroup(
                                      children: <Widget>[
                                        for (final ExploreApi api in matching)
                                          ApiRow(api: api),
                                      ],
                                    ),
                                  ] else ...<Widget>[
                                    SectionHeader(
                                      label: 'Categories · ${categories.length}',
                                      note: 'A to Z',
                                    ),
                                    const SizedBox(height: Space.row),
                                    RowGroup(
                                      children: <Widget>[
                                        for (final ExploreCategory cat
                                            in categories)
                                          AppRow(
                                            title: cat.name,
                                            subtitle: cat.summary,
                                            minHeight: 60,
                                            leading: Icon(
                                              Icons.folder_special_outlined,
                                              size: IconSpec.size,
                                              color: c.iconMuted,
                                            ),
                                            trailing: Icon(
                                              Icons.chevron_right_rounded,
                                              size: IconSpec.size,
                                              color: c.iconMuted,
                                            ),
                                            onTap: () => context.push(
                                              Routes.exploreCategory(cat.name),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// HTTPS and the four auth kinds, with the counts updating live.
class _FilterRow extends ConsumerWidget {
  const _FilterRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ExploreFilters filters = ref.watch(exploreFiltersProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: Space.sm,
        children: <Widget>[
          PillChip(
            label: 'HTTPS',
            selected: filters.httpsOnly,
            showCheck: true,
            onTap: () =>
                ref.read(exploreFiltersProvider.notifier).toggleHttps(),
          ),
          for (final ApiAuth auth in ApiAuth.values)
            PillChip(
              label: auth.filterLabel,
              selected: filters.auths.contains(auth),
              showCheck: true,
              onTap: () =>
                  ref.read(exploreFiltersProvider.notifier).toggleAuth(auth),
            ),
          if (filters.httpsOnly || filters.auths.isNotEmpty)
            PillChip(
              label: 'Clear',
              icon: Icons.close_rounded,
              onTap: () => ref.read(exploreFiltersProvider.notifier).clear(),
            ),
        ],
      ),
    );
  }
}

/// A card for an API you can call the moment it opens.
class _ReadyCard extends ConsumerWidget {
  const _ReadyCard({required this.api});

  final ExploreApi api;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors c = context.colors;
    return AppCard(
      onTap: () => context.push(Routes.exploreApi(api.name)),
      padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.sm, Space.md),
      child: Row(
        spacing: Space.md,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: <Widget>[
                Text(
                  api.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.titleMedium.copyWith(color: c.onSurface),
                ),
                Text(
                  api.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.bodyMedium.copyWith(
                    color: c.onSurfaceVariant,
                  ),
                ),
                Text(
                  api.category.toLowerCase(),
                  style: AppType.monoLabel.copyWith(color: c.onSurfaceMuted),
                ),
              ],
            ),
          ),
          AppButton(
            label: 'Try',
            icon: Icons.bolt_rounded,
            filledIcon: true,
            compact: true,
            onPressed: () => openAsRequest(context, ref, api),
          ),
        ],
      ),
    );
  }
}

/// One catalogue row: the name, what it does, then auth and HTTPS as plain
/// text. The bolt opens it as a request without leaving the list.
class ApiRow extends ConsumerWidget {
  const ApiRow({required this.api, super.key});

  final ExploreApi api;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors c = context.colors;
    final bool savedAlready = isSaved(ref, api);
    return InkWell(
      onTap: () => context.push(Routes.exploreApi(api.name)),
      child: Padding(
        padding: const EdgeInsets.only(left: Space.lg, right: Space.xs),
        child: Row(
          spacing: Space.md,
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 3,
                  children: <Widget>[
                    Text(
                      api.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.titleMedium.copyWith(color: c.onSurface),
                    ),
                    Text(
                      api.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.bodyMedium.copyWith(
                        color: c.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      api.metaLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.monoLabel.copyWith(
                        color: c.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AppIconButton(
              icon: savedAlready
                  ? Icons.library_add_check_rounded
                  : Icons.library_add_outlined,
              onPressed: savedAlready
                  ? null
                  : () => addToCollection(context, ref, api),
              semanticLabel: savedAlready
                  ? '${api.name} is already in a collection'
                  : 'Save ${api.name} to a collection',
              filled: false,
              tint: savedAlready ? c.success : c.iconMuted,
            ),
            AppIconButton(
              icon: Icons.bolt_rounded,
              onPressed: () => openAsRequest(context, ref, api),
              semanticLabel: 'Open ${api.name} as a request',
              filled: false,
              tint: c.accent,
            ),
          ],
        ),
      ),
    );
  }
}

/// Board 3.4. Names the filter that emptied the list and offers to drop it.
class _NoResults extends ConsumerWidget {
  const _NoResults({
    required this.filters,
    required this.all,
    required this.onClearSearch,
  });

  final ExploreFilters filters;
  final List<ExploreApi> all;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors c = context.colors;
    // What would match if the auth filters were dropped, so the offer to drop
    // them is a real count rather than a hope.
    final ExploreFilters withoutAuth = ExploreFilters(
      httpsOnly: filters.httpsOnly,
      query: filters.query,
    );
    final int wouldMatch = all.where(withoutAuth.accepts).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        Space.screen,
        Space.xxl,
        Space.screen,
        Space.bottomSafe,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Space.lg,
        children: <Widget>[
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.surfaceContainerHigh,
              borderRadius: Radii.cardR,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 32,
              color: c.iconMuted,
            ),
          ),
          Text(
            'No matches',
            style: AppType.display.copyWith(color: c.onSurface),
          ),
          Text(
            filters.auths.isEmpty
                ? 'Nothing for "${filters.query}".'
                : 'Nothing for "${filters.query}" with '
                    '${filters.auths.map((ApiAuth a) => a.filterLabel).join(' or ')} '
                    'on.'
                    '${wouldMatch > 0 ? ' $wouldMatch ${wouldMatch == 1 ? 'API matches' : 'APIs match'} without that filter.' : ''}',
            style: AppType.body.copyWith(color: c.onSurfaceVariant),
          ),
          Wrap(
            spacing: Space.row,
            runSpacing: Space.row,
            children: <Widget>[
              if (filters.auths.isNotEmpty && wouldMatch > 0)
                AppButton(
                  label: 'Show $wouldMatch with auth',
                  onPressed: () => ref
                      .read(exploreFiltersProvider.notifier)
                      .replace(withoutAuth),
                ),
              if (filters.query.isNotEmpty)
                AppButton(
                  label: 'Clear search',
                  type: AppButtonType.outlined,
                  onPressed: onClearSearch,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Whether this API's sample request is already saved somewhere.
bool isSaved(WidgetRef ref, ExploreApi api) {
  final String url = requestFrom(api).url;
  return (ref.watch(requestsProvider).value ?? const <ApiRequest>[])
      .any((ApiRequest r) => r.url == url);
}

/// Board 3.2. Saves the API's sample request into a collection named after its
/// category, making that collection if it does not exist yet, and offers to
/// move it somewhere else.
Future<void> addToCollection(
  BuildContext context,
  WidgetRef ref,
  ExploreApi api,
) async {
  final CollectionsRepository repository = ref.read(
    collectionsRepositoryProvider,
  );
  final List<Folder> folders = ref.read(foldersProvider).value ??
      const <Folder>[];
  Folder? folder = folders
      .where((Folder f) => f.parentId == null && f.name == api.category)
      .firstOrNull;
  if (folder == null) {
    folder = Folder(id: newId(), name: api.category, order: folders.length);
    await repository.saveFolder(folder);
  }

  final int order = (ref.read(requestsProvider).value ?? const <ApiRequest>[])
      .where((ApiRequest r) => r.folderId == folder!.id)
      .length;
  final ApiRequest saved = requestFrom(
    api,
  ).copyWith(name: api.name, folderId: folder.id, order: order);
  await repository.saveRequest(saved);

  if (!context.mounted) return;
  AppSnackbar.action(
    context,
    message: '${api.name} added to ${folder.name}',
    label: 'Change',
    onAction: () async {
      final SaveTarget? target = await showSaveRequestSheet(
        context,
        ref,
        request: saved,
      );
      if (target == null) return;
      await repository.saveRequest(
        saved.copyWith(name: target.name, folderId: target.folderId),
      );
    },
  );
}

/// Opens a catalogue entry in the workspace as an unsaved request.
///
/// The workspace lives in the Collections branch, so this crosses branches.
/// Anything pushed on the root navigator has to come off first: `go` rebuilds
/// the shell underneath it and would otherwise leave a pushed page, and its
/// barrier, sitting on top of Collections.
void openAsRequest(
  BuildContext context,
  WidgetRef ref,
  ExploreApi api, {
  ApiSample? sample,
}) {
  ref.read(workspaceProvider.notifier).openDraft(
    requestFrom(api, sample: sample),
  );
  final NavigatorState root = Navigator.of(context, rootNavigator: true);
  while (root.canPop()) {
    root.pop();
  }
  context.go(Routes.workspace);
}
