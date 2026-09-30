import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/collections_repository.dart';
import '../../core/http/curl_parser.dart';
import '../../core/models/api_request.dart';
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
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_icon_button.dart';
import '../../core/widgets/app_menu.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/chips.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/states.dart';
import '../workspace/open_requests_sheet.dart';
import '../workspace/workspace_controller.dart';
import 'folder_sheet.dart';

/// Board 01. The Open strip stands in for the desktop tab bar, folders below
/// it, and New request floats where a centre nav action would have been.
class CollectionsScreen extends ConsumerStatefulWidget {
  const CollectionsScreen({super.key});

  @override
  ConsumerState<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends ConsumerState<CollectionsScreen> {
  /// Which folders are open. Kept in the widget: it is view state for one
  /// screen and does not belong in the database.
  final Set<String> _expanded = <String>{};

  void _openWorkspace() => context.push(Routes.workspace);

  void _newRequest() {
    ref.read(workspaceProvider.notifier).openBlank();
    _openWorkspace();
  }

  Future<void> _quickActions() async {
    final String? choice = await showAppMenu<String>(
      context: context,
      entries: const <AppMenuEntry<String>>[
        AppMenuEntry<String>(
          value: 'curl',
          label: 'Paste cURL',
          icon: Icons.content_paste_rounded,
        ),
        AppMenuEntry<String>(
          value: 'repeat',
          label: 'Repeat last',
          icon: Icons.history_rounded,
        ),
      ],
    );
    if (!mounted) return;
    switch (choice) {
      case 'curl':
        await _pasteCurl();
      case 'repeat':
        await _repeatLast();
    }
  }

  Future<void> _pasteCurl() async {
    final ApiRequest? parsed = await pasteCurlFromClipboard();
    if (!mounted) return;
    if (parsed == null) {
      AppSnackbar.info(context, 'The clipboard does not hold a cURL command');
      return;
    }
    ref.read(workspaceProvider.notifier).openDraft(parsed);
    _openWorkspace();
  }

  Future<void> _repeatLast() async {
    final List<ApiRequest> all = ref.read(requestsProvider).value ??
        const <ApiRequest>[];
    if (all.isEmpty) {
      AppSnackbar.info(context, 'Nothing to repeat yet');
      return;
    }
    final ApiRequest latest = all.reduce(
      (ApiRequest a, ApiRequest b) =>
          a.updatedAt.isAfter(b.updatedAt) ? a : b,
    );
    ref.read(workspaceProvider.notifier).open(latest);
    _openWorkspace();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Folder>> folders = ref.watch(foldersProvider);
    final AsyncValue<List<ApiRequest>> requests = ref.watch(requestsProvider);
    final WorkspaceState workspace = ref.watch(workspaceProvider);

    final List<Folder> folderList = folders.value ?? const <Folder>[];
    final List<ApiRequest> requestList = requests.value ?? const <ApiRequest>[];
    final bool loading = folders.isLoading || requests.isLoading;
    // An open request counts: a draft from Explore or a cURL paste has nowhere
    // else to be listed, and showing the first-run state over the top of one
    // loses it.
    final bool empty = !loading &&
        folderList.isEmpty &&
        requestList.isEmpty &&
        workspace.tabs.isEmpty;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CollapseOnScroll(
          builder: (BuildContext context, bool collapsed) => Stack(
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AppHeader(
                    title: 'Collections',
                    collapsed: collapsed,
                    actions: <Widget>[
                      if (!empty)
                        AppIconButton(
                          icon: Icons.create_new_folder_rounded,
                          onPressed: () => showFolderSheet(context, ref),
                          semanticLabel: 'New folder',
                        ),
                      Builder(
                        builder: (BuildContext anchor) => AppIconButton(
                          icon: Icons.more_horiz_rounded,
                          onPressed: () => _overflow(anchor),
                          semanticLabel: 'More options',
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: empty
                        ? EmptyState(
                            icon: Icons.folder_open_rounded,
                            title: 'No requests yet',
                            message: 'Create one or explore public APIs.',
                            primaryLabel: 'New request',
                            onPrimary: _newRequest,
                            secondaryLabel: 'Explore APIs',
                            secondaryIcon: Icons.explore_outlined,
                            onSecondary: () => context.go(Routes.explore),
                          )
                        : _Body(
                            folders: folderList,
                            requests: requestList,
                            workspace: workspace,
                            expanded: _expanded,
                            loading: loading,
                            onToggleFolder: (String id) => setState(
                              () => _expanded.contains(id)
                                  ? _expanded.remove(id)
                                  : _expanded.add(id),
                            ),
                            onOpenRequest: (ApiRequest r) {
                              ref.read(workspaceProvider.notifier).open(r);
                              _openWorkspace();
                            },
                            onFocusTab: (String id) {
                              ref.read(workspaceProvider.notifier).focusId(id);
                              _openWorkspace();
                            },
                            onCloseTab: (String id) =>
                                ref.read(workspaceProvider.notifier).close(id),
                            onShowOpen: () => showOpenRequestsSheet(context, ref),
                          ),
                  ),
                ],
              ),
              if (!empty)
                Positioned(
                  right: Space.screen,
                  bottom: NavSpec.height + NavSpec.bottom + Space.lg,
                  child: SafeArea(
                    top: false,
                    child: PrimaryActionButton(
                      label: 'New request',
                      icon: Icons.add_rounded,
                      onPressed: _newRequest,
                      onLongPress: _quickActions,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _overflow(BuildContext anchor) async {
    final String? choice = await showAppMenu<String>(
      context: anchor,
      entries: const <AppMenuEntry<String>>[
        AppMenuEntry<String>(
          value: 'curl',
          label: 'Paste cURL',
          icon: Icons.content_paste_rounded,
        ),
        AppMenuEntry<String>(
          value: 'folder',
          label: 'New folder',
          icon: Icons.create_new_folder_rounded,
        ),
        AppMenuEntry<String>(
          value: 'docs',
          label: 'API docs',
          icon: Icons.description_outlined,
        ),
      ],
    );
    if (!mounted) return;
    switch (choice) {
      case 'curl':
        await _pasteCurl();
      case 'folder':
        await showFolderSheet(context, ref);
      case 'docs':
        if (mounted) await context.push(Routes.apiDocs);
    }
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.folders,
    required this.requests,
    required this.workspace,
    required this.expanded,
    required this.loading,
    required this.onToggleFolder,
    required this.onOpenRequest,
    required this.onFocusTab,
    required this.onCloseTab,
    required this.onShowOpen,
  });

  final List<Folder> folders;
  final List<ApiRequest> requests;
  final WorkspaceState workspace;
  final Set<String> expanded;
  final bool loading;
  final ValueChanged<String> onToggleFolder;
  final ValueChanged<ApiRequest> onOpenRequest;
  final ValueChanged<String> onFocusTab;
  final ValueChanged<String> onCloseTab;
  final VoidCallback onShowOpen;

  @override
  Widget build(BuildContext context) {
    final List<Folder> top = <Folder>[
      for (final Folder f in folders) if (f.parentId == null) f,
    ];
    final List<ApiRequest> unfiled = <ApiRequest>[
      for (final ApiRequest r in requests) if (r.folderId == null) r,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Space.screen,
        Space.md,
        Space.screen,
        Space.bottomSafe + 56,
      ),
      children: <Widget>[
        if (workspace.tabs.isNotEmpty) ...<Widget>[
          SectionHeader(
            label: 'Open · ${workspace.tabs.length}',
            note: 'swipe up to close',
          ),
          const SizedBox(height: Space.row),
          _OpenStrip(
            workspace: workspace,
            onFocus: onFocusTab,
            onClose: onCloseTab,
            onShowAll: onShowOpen,
          ),
          const SizedBox(height: Space.section),
        ],
        if (loading && folders.isEmpty && requests.isEmpty)
          const Delayed(
            child: RowGroup(
              children: <Widget>[SkeletonRow(), SkeletonRow(titleFactor: 0.45)],
            ),
          )
        else ...<Widget>[
          if (unfiled.isNotEmpty) ...<Widget>[
            SectionHeader(
              label: 'No folder · ${unfiled.length}',
              note: 'top level',
            ),
            const SizedBox(height: Space.row),
            RowGroup(
              children: <Widget>[
                for (final ApiRequest r in unfiled)
                  _RequestRow(request: r, onTap: () => onOpenRequest(r)),
              ],
            ),
            const SizedBox(height: Space.section),
          ],
          if (top.isNotEmpty) ...<Widget>[
            SectionHeader(
              label: 'Folders · ${top.length}',
              note: 'tap to open',
            ),
            const SizedBox(height: Space.row),
            for (final Folder folder in top) ...<Widget>[
              _FolderBlock(
                folder: folder,
                folders: folders,
                requests: requests,
                expanded: expanded,
                onToggle: onToggleFolder,
                onOpenRequest: onOpenRequest,
              ),
              const SizedBox(height: Space.row),
            ],
          ],
        ],
      ],
    );
  }
}

/// A folder and, while it is open, its subfolders and requests inside one
/// container. Closed, it is a 56dp card on its own.
class _FolderBlock extends StatelessWidget {
  const _FolderBlock({
    required this.folder,
    required this.folders,
    required this.requests,
    required this.expanded,
    required this.onToggle,
    required this.onOpenRequest,
  });

  final Folder folder;
  final List<Folder> folders;
  final List<ApiRequest> requests;
  final Set<String> expanded;
  final ValueChanged<String> onToggle;
  final ValueChanged<ApiRequest> onOpenRequest;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final bool open = expanded.contains(folder.id);
    final int count = CollectionsRepository.countIn(
      folder.id,
      folders,
      requests,
    );
    final List<ApiRequest> own = <ApiRequest>[
      for (final ApiRequest r in requests) if (r.folderId == folder.id) r,
    ];
    final List<Folder> children = <Folder>[
      for (final Folder f in folders) if (f.parentId == folder.id) f,
    ];

    final Widget head = AppRow(
      title: folder.name,
      count: '$count',
      leading: Icon(
        open ? Icons.folder_open_rounded : Icons.folder_rounded,
        size: IconSpec.size,
        color: open ? c.accent : c.iconMuted,
        fill: open ? 1 : 0,
      ),
      trailing: Icon(
        open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
        size: IconSpec.size,
        color: c.iconMuted,
      ),
      onTap: () => onToggle(folder.id),
    );

    if (!open) return RowGroup(children: <Widget>[head]);
    return RowGroup(
      children: <Widget>[
        head,
        for (final Folder child in children)
          _SubfolderRow(
            folder: child,
            folders: folders,
            requests: requests,
            expanded: expanded,
            onToggle: onToggle,
            onOpenRequest: onOpenRequest,
          ),
        for (final ApiRequest r in own)
          _RequestRow(
            request: r,
            indent: Space.lg,
            onTap: () => onOpenRequest(r),
          ),
        if (own.isEmpty && children.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.lg,
              vertical: 14,
            ),
            child: Text(
              'Nothing in here yet.',
              style: AppType.bodyMedium.copyWith(color: c.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}

/// A nested folder drawn as a row inside its parent's container. Indented, with
/// the board's `subdirectory_arrow_right` glyph.
class _SubfolderRow extends StatelessWidget {
  const _SubfolderRow({
    required this.folder,
    required this.folders,
    required this.requests,
    required this.expanded,
    required this.onToggle,
    required this.onOpenRequest,
  });

  final Folder folder;
  final List<Folder> folders;
  final List<ApiRequest> requests;
  final Set<String> expanded;
  final ValueChanged<String> onToggle;
  final ValueChanged<ApiRequest> onOpenRequest;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final bool open = expanded.contains(folder.id);
    final int count = CollectionsRepository.countIn(
      folder.id,
      folders,
      requests,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppRow(
          title: folder.name,
          count: '$count',
          indent: Space.xl,
          leading: Icon(
            Icons.subdirectory_arrow_right_rounded,
            size: IconSpec.size,
            color: c.iconMuted,
          ),
          trailing: Icon(
            open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            size: IconSpec.size,
            color: c.iconMuted,
          ),
          onTap: () => onToggle(folder.id),
        ),
        if (open)
          for (final ApiRequest r in requests)
            if (r.folderId == folder.id)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Divider(color: c.divider, height: 1),
                  _RequestRow(
                    request: r,
                    indent: Space.xxl,
                    onTap: () => onOpenRequest(r),
                  ),
                ],
              ),
      ],
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({
    required this.request,
    required this.onTap,
    this.indent = 0,
  });

  final ApiRequest request;
  final VoidCallback onTap;
  final double indent;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(Space.lg + indent, 11, Space.lg, 11),
        child: Row(
          spacing: Space.md,
          children: <Widget>[
            MethodChip(request.method),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: <Widget>[
                  Text(
                    request.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.titleMedium.copyWith(color: c.onSurface),
                  ),
                  Text(
                    _shortUrl(request.url),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
    );
  }

  /// Drops the scheme, which is never the interesting part of a saved request.
  static String _shortUrl(String url) =>
      url.replaceFirst(RegExp('^https?://'), '');
}

/// The Open strip: the board's horizontal run of 196dp cards that bleeds off
/// the right edge, with a swipe up to close one.
class _OpenStrip extends StatelessWidget {
  const _OpenStrip({
    required this.workspace,
    required this.onFocus,
    required this.onClose,
    required this.onShowAll,
  });

  final WorkspaceState workspace;
  final ValueChanged<String> onFocus;
  final ValueChanged<String> onClose;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        // Bleeds into the screen margin, as the board's -20 does.
        padding: const EdgeInsets.only(right: Space.screen),
        itemCount: workspace.tabs.length,
        separatorBuilder: (BuildContext context, int _) =>
            const SizedBox(width: Space.row),
        itemBuilder: (BuildContext context, int i) {
          final WorkspaceTab tab = workspace.tabs[i];
          final bool active = i == workspace.activeIndex;
          return Dismissible(
            key: ValueKey<String>('open-${tab.id}'),
            direction: DismissDirection.up,
            onDismissed: (_) => onClose(tab.id),
            child: SizedBox(
              width: 196,
              child: AppCard(
                selected: active,
                onTap: () => onFocus(tab.id),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: Space.md,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: <Widget>[
                    Row(
                      spacing: Space.sm,
                      children: <Widget>[
                        MethodChip.auto(tab.draft.method),
                        Expanded(
                          child: Text(
                            tab.draft.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.titleMedium.copyWith(
                              color: active
                                  ? c.onPrimaryContainer
                                  : c.onSurface,
                            ),
                          ),
                        ),
                        if (tab.dirty)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: c.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    Text(
                      _statusLine(tab),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.monoLabel.copyWith(
                        color: active
                            ? c.onPrimaryContainer
                            : c.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static String _statusLine(WorkspaceTab tab) {
    final String path = Uri.tryParse(tab.draft.url)?.path ?? '';
    final String head = path.isEmpty ? 'no URL' : path;
    if (tab.sending) return '$head · sending';
    if (tab.response != null) {
      final int status = tab.response!.statusCode;
      return '$head · ${status == 0 ? 'failed' : status}';
    }
    return tab.dirty ? '$head · unsaved' : head;
  }
}

/// Reads the clipboard and parses a cURL command out of it.
Future<ApiRequest?> pasteCurlFromClipboard() async {
  final String text = await readClipboard();
  if (text.trim().isEmpty) return null;
  if (!CurlParser.looksLikeCurl(text)) return null;
  return CurlParser.parse(text, id: newId());
}

/// Kept here so the two callers (Collections and the workspace) share it.
Future<String> readClipboard() async {
  final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
  return data?.text ?? '';
}

/// A count line for the More screen's Collections row.
String collectionsSummary(List<Folder> folders, List<ApiRequest> requests) =>
    '${Fmt.count(requests.length, 'request')} · '
    '${Fmt.count(folders.length, 'folder')}';
