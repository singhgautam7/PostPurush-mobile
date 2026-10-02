import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/nav_shell.dart';
import '../../app/transitions.dart';
import '../../core/http/request_builder.dart';
import '../../core/http/variable_resolver.dart';
import '../../core/models/api_request.dart';
import '../../core/models/environment.dart';
import '../../core/models/http_method.dart';
import '../../core/models/key_value.dart';
import '../../core/providers.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/util/format.dart';
import '../../core/util/ids.dart';
import '../../core/widgets/app_icon_button.dart';
import '../../core/widgets/app_menu.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/chips.dart';
import '../../core/widgets/code_view.dart';
import '../../core/widgets/fields.dart';
import '../../core/widgets/key_value_editor.dart';
import '../../core/widgets/states.dart';
import '../../core/widgets/url_bar.dart';
import '../../core/widgets/variable_text.dart';
import '../collections/collections_screen.dart';
import '../environments/variable_sheet.dart';
import 'code_export_sheet.dart';
import 'environment_switcher.dart';
import 'keyboard_strip.dart';
import 'method_sheet.dart';
import 'open_requests_sheet.dart';
import 'response_dock.dart';
import 'response_sheet.dart';
import 'save_request_sheet.dart';
import 'workspace_controller.dart';

enum RequestPane { params, headers, body, auth }

/// The board's three stops, as fractions of the screen height. Collapsed is
/// the dock's own height, so dragging the sheet down lands exactly on it.
/// Low enough to be out of the way, high enough that the sheet animates down
/// to it rather than vanishing.
const double _collapsedStop = 0.06;
const double _halfStop = 0.56;
const double _fullStop = 1.0;

/// Board 02. The request fills the screen; Send and the response live in the
/// dock above the nav, and the response grows out of it into a sheet.
class WorkspaceScreen extends ConsumerStatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> {
  final VariableEditingController _url = VariableEditingController();
  final FocusNode _urlFocus = FocusNode();
  final DraggableScrollableController _sheet = DraggableScrollableController();

  /// How far the response sheet is open, for the scrim behind it. A notifier
  /// rather than setState: the extent changes every frame of a drag and only
  /// the scrim cares about it.
  final ValueNotifier<double> _extent = ValueNotifier<double>(_halfStop);

  /// Captured in initState, because `ref` is no longer usable by the time
  /// dispose runs and the pill has to be handed back from there.
  late final NavHidden _nav = ref.read(navHiddenProvider.notifier);
  RequestPane _pane = RequestPane.params;

  /// Which tab the URL field currently mirrors, so switching requests reloads
  /// it and typing in it does not.
  String? _mirroring;

  @override
  void initState() {
    super.initState();
    _url.addListener(_onUrlChanged);
    _urlFocus.addListener(_onFocusChanged);
    // The workspace is a page, not a destination. The nav has nothing to offer
    // while a request is open, and swiping to another tab from under it is not
    // something anyone means to do, so the pill leaves for as long as this page
    // is on screen. Set once here and cleared once in dispose: writing it from
    // build raced the clear and left the pill hidden after popping.
    _setNav(hidden: true);
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  void _setNav({required bool hidden}) {
    // A provider cannot be written during a build or a dispose, so both ends
    // go through the next frame.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _nav.set(hidden: hidden),
    );
  }

  @override
  void dispose() {
    _url
      ..removeListener(_onUrlChanged)
      ..dispose();
    _urlFocus
      ..removeListener(_onFocusChanged)
      ..dispose();
    _sheet.dispose();
    _extent.dispose();
    // The pill belongs to the destinations, so it comes back when this page
    // leaves.
    _setNav(hidden: false);
    super.dispose();
  }

  void _onUrlChanged() {
    final WorkspaceTab? tab = ref.read(activeTabProvider);
    if (tab == null || _mirroring != tab.id) return;
    if (tab.draft.url == _url.text) return;
    ref
        .read(workspaceProvider.notifier)
        .edit((ApiRequest r) => r.copyWith(url: _url.text));
  }

  /// Loads the field from the tab, and picks the pane that has something in it.
  void _syncFrom(WorkspaceTab tab) {
    _mirroring = tab.id;
    _url.value = TextEditingValue(
      text: tab.draft.url,
      selection: TextSelection.collapsed(offset: tab.draft.url.length),
    );
    _pane = tab.draft.bodyType != BodyType.none
        ? RequestPane.body
        : tab.draft.headers.isNotEmpty
        ? RequestPane.headers
        : RequestPane.params;
    if (tab.draft.url.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _urlFocus.requestFocus();
      });
    }
  }

  void _edit(ApiRequest Function(ApiRequest) change) =>
      ref.read(workspaceProvider.notifier).edit(change);

  /// Animates the sheet to a stop, for the expand button, the scrim and the
  /// dock.
  ///
  /// The animation runs first and the state is written after it: writing
  /// `collapsed` first takes the sheet out of the tree, which detaches the
  /// controller and skips the closing animation entirely.
  Future<void> _goToStop(DockStop stop) async {
    final WorkspaceController controller = ref.read(workspaceProvider.notifier);
    if (!_sheet.isAttached) {
      controller.setStop(stop);
      return;
    }
    await _sheet.animateTo(
      switch (stop) {
        DockStop.collapsed => _collapsedStop,
        DockStop.half => _halfStop,
        DockStop.full => _fullStop,
      },
      duration: Motion.of(context, Motion.containerTransform),
      curve: Motion.curveOf(context, Motion.decelerate),
    );
    if (mounted) controller.setStop(stop);
  }

  /// Where the finger left it decides the stop. Dragging it down to collapsed
  /// is what closes it, and the sheet is only taken out of the tree once it has
  /// animated all the way down, so the close has the same motion as the open.
  void _onSheetMoved(double extent) {
    _extent.value = extent;
    // Collapsed only once the sheet has actually reached the bottom stop, not
    // partway down: the sheet leaves the tree the moment this says collapsed,
    // and leaving early cut the closing animation off mid-flight.
    final DockStop stop = extent >= (_halfStop + _fullStop) / 2
        ? DockStop.full
        : extent <= _collapsedStop + 0.01
        ? DockStop.collapsed
        : DockStop.half;
    if (stop != ref.read(workspaceProvider).stop) {
      ref.read(workspaceProvider.notifier).setStop(stop);
    }
  }

  Future<void> _save() async {
    final WorkspaceTab? tab = ref.read(activeTabProvider);
    if (tab == null) return;
    final WorkspaceController controller = ref.read(workspaceProvider.notifier);
    if (tab.saved != null && tab.draft.name.isNotEmpty) {
      await controller.save();
      if (mounted) AppSnackbar.info(context, 'Saved');
      return;
    }
    final SaveTarget? target = await showSaveRequestSheet(
      context,
      ref,
      request: tab.draft,
    );
    if (target == null) return;
    await controller.save(name: target.name, folderId: target.folderId);
    if (mounted) AppSnackbar.info(context, 'Saved to Folders');
  }

  Future<void> _pickMethod(HttpMethod current) async {
    final HttpMethod? chosen = await showMethodSheet(context, current: current);
    if (chosen != null) _edit((ApiRequest r) => r.copyWith(method: chosen));
  }

  Future<void> _pasteCurl() async {
    final ApiRequest? parsed = await pasteCurlFromClipboard();
    if (!mounted) return;
    if (parsed == null) {
      AppSnackbar.info(context, 'The clipboard does not hold a cURL command');
      return;
    }
    _edit(
      (ApiRequest r) => r.copyWith(
        method: parsed.method,
        url: parsed.url,
        headers: parsed.headers,
        params: parsed.params,
        body: parsed.body,
        bodyType: parsed.bodyType,
        auth: parsed.auth,
      ),
    );
    _mirroring = null;
  }

  /// "Add it": creates the missing variable in the active environment without
  /// leaving the workspace.
  Future<void> _addMissing(String name, Environment env) async {
    final KeyValueRow? row = await showVariableSheet(
      context,
      environmentName: env.name,
      initial: KeyValueRow(id: newId(), key: name),
    );
    if (row == null) return;
    await ref
        .read(environmentsRepositoryProvider)
        .save(env.copyWith(variables: <KeyValueRow>[...env.variables, row]));
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final WorkspaceState state = ref.watch(workspaceProvider);
    final WorkspaceTab? tab = state.active;
    final Environment? env = ref.watch(activeEnvironmentProvider);

    final bool keyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;

    if (tab == null) {
      return Scaffold(
        body: SafeArea(
          child: EmptyState(
            icon: Icons.bolt_rounded,
            title: 'Nothing open',
            message: 'Start a request, or open one from Folders.',
            primaryLabel: 'New request',
            onPrimary: () => ref.read(workspaceProvider.notifier).openBlank(),
            secondaryLabel: 'Folders',
            secondaryIcon: Icons.folder_open_rounded,
            onSecondary: () => context.go(Routes.collections),
          ),
        ),
      );
    }

    if (_mirroring != tab.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _mirroring != tab.id) setState(() => _syncFrom(tab));
      });
    }

    final bool canSend = RequestBuilder.isSendable(tab.draft.url);
    final List<String> missing = VariableResolver.missingAcross(
      RequestBuilder.templateStrings(tab.draft),
      env,
    );
    final bool sheetOpen =
        tab.response != null &&
        tab.response!.arrived &&
        state.stop != DockStop.collapsed;

    return PopScope(
      // Back steps the response sheet down before it leaves the workspace,
      // which is what a sheet at half or full height should answer to.
      canPop: !sheetOpen,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (didPop) return;
        ref
            .read(workspaceProvider.notifier)
            .setStop(
              state.stop == DockStop.full ? DockStop.half : DockStop.collapsed,
            );
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _TopBar(
                    tab: tab,
                    onBack: () => context.pop(),
                    onSave: canSend ? _save : null,
                    onOverflow: (BuildContext anchor) => _overflow(anchor, tab),
                  ),
                  _TitleRow(
                    tab: tab,
                    total: state.tabs.length,
                    index: state.activeIndex,
                    onTap: () => showOpenRequestsSheet(context, ref),
                    onSwipe: (int delta) {
                      final int next = state.activeIndex + delta;
                      if (next >= 0 && next < state.tabs.length) {
                        ref.read(workspaceProvider.notifier).focus(next);
                      }
                    },
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        Space.screen,
                        Space.lg,
                        Space.screen,
                        Space.bottomSafeDock,
                      ),
                      children: <Widget>[
                        UrlBar(
                          controller: _url,
                          method: tab.draft.method,
                          env: env,
                          focusNode: _urlFocus,
                          onMethodTap: () => _pickMethod(tab.draft.method),
                          onSubmitted: (_) {
                            if (canSend) {
                              ref.read(workspaceProvider.notifier).send();
                            }
                          },
                        ),
                        if (RequestBuilder.urlError(tab.draft.url) != null)
                          Padding(
                            padding: const EdgeInsets.only(top: Space.sm),
                            child: InlineError(
                              icon: Icons.link_off_rounded,
                              message: RequestBuilder.urlError(tab.draft.url)!,
                            ),
                          ),
                        if (missing.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: Space.sm),
                            child: InlineError(
                              message: env == null
                                  ? '${missing.first} needs an environment'
                                  : "${missing.first} isn't in ${env.name}",
                              actionLabel: env == null ? null : 'Add it',
                              onAction: env == null
                                  ? null
                                  : () => _addMissing(missing.first, env),
                            ),
                          ),
                        if (tab.draft.url.isEmpty) ...<Widget>[
                          const SizedBox(height: Space.lg),
                          _QuickActions(
                            onPasteCurl: _pasteCurl,
                            onExplore: () => context.go(Routes.explore),
                            onRecent: () => context.push(Routes.history),
                          ),
                        ],
                        const SizedBox(height: Space.lg),
                        SegmentedToggle<RequestPane>(
                          options: const <(RequestPane, String)>[
                            (RequestPane.params, 'Params'),
                            (RequestPane.headers, 'Headers'),
                            (RequestPane.body, 'Body'),
                            (RequestPane.auth, 'Auth'),
                          ],
                          badges: <Object?, String>{
                            if (tab.draft.params.badge != null)
                              RequestPane.params: tab.draft.params.badge!,
                            if (tab.draft.headers.badge != null)
                              RequestPane.headers: tab.draft.headers.badge!,
                          },
                          selected: _pane,
                          onChanged: (RequestPane value) =>
                              setState(() => _pane = value),
                        ),
                        const SizedBox(height: Space.lg),
                        // The four panes swap in place, so the change reads as
                        // one pane replacing another rather than a redraw.
                        AppSwitcher(
                          child: _PaneBody(
                            key: ValueKey<RequestPane>(_pane),
                            pane: _pane,
                            tab: tab,
                            env: env,
                            onEdit: _edit,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (keyboardUp && _urlFocus.hasFocus)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: KeyboardStrip(
                    controller: _url,
                    env: env,
                    onCreateVariable: (String name) =>
                        env == null ? null : _addMissing(name, env),
                  ),
                )
              else if (sheetOpen) ...<Widget>[
                // The scrim a modal sheet has: it dims the request behind the
                // response and closes the sheet when tapped.
                Positioned.fill(
                  child: _SheetScrim(
                    extent: _extent,
                    onTap: () => _goToStop(DockStop.collapsed),
                  ),
                ),
                // A real sheet: it follows the finger, snaps to the board's
                // collapsed, half and full stops, and once it is full the same
                // drag scrolls the body, because the sheet hands its scroll
                // controller down.
                _SheetEntrance(
                  child: NotificationListener<DraggableScrollableNotification>(
                    onNotification: (DraggableScrollableNotification n) {
                      _onSheetMoved(n.extent);
                      return false;
                    },
                    child: DraggableScrollableSheet(
                      controller: _sheet,
                      initialChildSize: _halfStop,
                      minChildSize: _collapsedStop,
                      maxChildSize: _fullStop,
                      snap: true,
                      // All three of the board's stops, so a drag lands on one
                      // of them rather than wherever the finger stopped.
                      snapSizes: const <double>[_collapsedStop, _halfStop],
                      snapAnimationDuration: Motion.containerTransform,
                      builder:
                          (
                            BuildContext context,
                            ScrollController scrollController,
                          ) => ResponseSheet(
                            response: tab.response!,
                            scrollController: scrollController,
                            stop: state.stop,
                            onStopChanged: _goToStop,
                            onResend: () =>
                                ref.read(workspaceProvider.notifier).send(),
                          ),
                    ),
                  ),
                ),
              ] else if (!keyboardUp)
                Positioned(
                  left: Space.lg,
                  right: Space.lg,
                  // The nav is gone here, so the dock takes its place rather
                  // than floating above a gap where it used to be.
                  bottom: NavSpec.bottom,
                  child: SafeArea(
                    top: false,
                    // The dock rises into place rather than appearing, which
                    // is the one animation this corner needs: cross-fading the
                    // three of them left both painted at once and the page
                    // read as blurred.
                    child: AppReveal(
                      visible: true,
                      child: ResponseDock(
                        tab: tab,
                        canSend: canSend,
                        onSend: () =>
                            ref.read(workspaceProvider.notifier).send(),
                        onCancel: () =>
                            ref.read(workspaceProvider.notifier).cancel(tab.id),
                        onExpand: () => _goToStop(DockStop.half),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        backgroundColor: c.surface,
      ),
    );
  }

  Future<void> _overflow(BuildContext anchor, WorkspaceTab tab) async {
    final String? choice = await showAppMenu<String>(
      context: anchor,
      entries: <AppMenuEntry<String>>[
        const AppMenuEntry<String>(
          value: 'export',
          label: 'Export as code',
          icon: Icons.code_rounded,
          note: 'cURL, JavaScript, Python and more',
        ),
        const AppMenuEntry<String>(
          value: 'curl',
          label: 'Paste cURL',
          icon: Icons.content_paste_rounded,
        ),
        const AppMenuEntry<String>(
          value: 'copyUrl',
          label: 'Copy URL',
          icon: Icons.link_rounded,
        ),
        if (tab.saved != null)
          const AppMenuEntry<String>(
            value: 'duplicate',
            label: 'Duplicate',
            icon: Icons.copy_all_outlined,
          ),
        const AppMenuEntry<String>(
          value: 'testing',
          label: 'Assertions',
          icon: Icons.science_outlined,
        ),
        const AppMenuEntry<String>.divider(),
        AppMenuEntry<String>(
          value: 'close',
          label: tab.dirty ? 'Close without saving' : 'Close',
          icon: Icons.close_rounded,
          danger: tab.dirty,
        ),
      ],
    );
    if (!mounted) return;
    switch (choice) {
      case 'export':
        await showCodeExportSheet(context, ref, request: tab.draft);
      case 'curl':
        await _pasteCurl();
      case 'copyUrl':
        await copyToClipboard(tab.draft.url);
        if (mounted) AppSnackbar.info(context, 'URL copied');
      case 'duplicate':
        ref
            .read(workspaceProvider.notifier)
            .openDraft(
              tab.draft.copyWith(
                id: newId(),
                name: '${tab.draft.displayName} copy',
              ),
            );
      case 'testing':
        if (mounted) await context.push(Routes.testing);
      case 'close':
        ref.read(workspaceProvider.notifier).close(tab.id);
        if (mounted) context.pop();
    }
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.tab,
    required this.onBack,
    required this.onSave,
    required this.onOverflow,
  });

  final WorkspaceTab tab;
  final VoidCallback onBack;
  final VoidCallback? onSave;
  final void Function(BuildContext) onOverflow;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.md, 0),
    child: Row(
      spacing: Space.sm,
      children: <Widget>[
        AppIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: onBack,
          semanticLabel: 'Back to Folders',
        ),
        Flexible(child: EnvironmentChip(request: tab.draft)),
        const Spacer(),
        AppIconButton(
          icon: Icons.save_rounded,
          onPressed: onSave,
          semanticLabel: 'Save this request',
          badge: tab.dirty,
        ),
        Builder(
          builder: (BuildContext anchor) => AppIconButton(
            icon: Icons.more_horiz_rounded,
            onPressed: () => onOverflow(anchor),
            semanticLabel: 'More options',
          ),
        ),
      ],
    ),
  );
}

/// The name, the chevron that opens the open-requests sheet, and the `1 of 3
/// open` counter. A sideways swipe here moves to the next open request.
class _TitleRow extends StatelessWidget {
  const _TitleRow({
    required this.tab,
    required this.total,
    required this.index,
    required this.onTap,
    required this.onSwipe,
  });

  final WorkspaceTab tab;
  final int total;
  final int index;
  final VoidCallback onTap;
  final ValueChanged<int> onSwipe;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final bool named = tab.draft.name.trim().isNotEmpty;
    return GestureDetector(
      onHorizontalDragEnd: (DragEndDetails details) {
        final double v = details.primaryVelocity ?? 0;
        if (v.abs() < 240) return;
        onSwipe(v < 0 ? 1 : -1);
      },
      behavior: HitTestBehavior.opaque,
      child: InkWell(
        // The Android click sound belongs to the system, not to a tool.
        enableFeedback: false,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.screen,
            Space.sm,
            Space.screen,
            Space.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: <Widget>[
              Row(
                spacing: Space.xs,
                children: <Widget>[
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: Space.xs,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            tab.draft.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.headerTitle.copyWith(
                              color: named ? c.onSurface : c.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.unfold_more_rounded,
                          size: IconSpec.size,
                          color: c.iconMuted,
                        ),
                      ],
                    ),
                  ),
                  if (total > 1)
                    Text(
                      '${index + 1} of $total open',
                      style: AppType.monoLabel.copyWith(
                        color: c.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              Text(
                _subtitle(tab),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.bodyMedium.copyWith(color: c.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _subtitle(WorkspaceTab tab) {
    if (tab.saved == null) return 'Not saved yet';
    if (tab.dirty) return 'edited just now';
    return 'saved · ${Fmt.relative(tab.draft.updatedAt)}';
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onPasteCurl,
    required this.onExplore,
    required this.onRecent,
  });

  final VoidCallback onPasteCurl;
  final VoidCallback onExplore;
  final VoidCallback onRecent;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: Space.sm,
    runSpacing: Space.sm,
    children: <Widget>[
      PillChip(
        label: 'Paste cURL',
        icon: Icons.content_paste_rounded,
        onTap: onPasteCurl,
      ),
      PillChip(
        label: 'From Explore',
        icon: Icons.explore_outlined,
        onTap: onExplore,
      ),
      PillChip(label: 'Recent', icon: Icons.history_rounded, onTap: onRecent),
    ],
  );
}

/// The four panes.
class _PaneBody extends StatelessWidget {
  const _PaneBody({
    required this.pane,
    super.key,
    required this.tab,
    required this.env,
    required this.onEdit,
  });

  final RequestPane pane;
  final WorkspaceTab tab;
  final Environment? env;
  final void Function(ApiRequest Function(ApiRequest)) onEdit;

  @override
  Widget build(BuildContext context) => switch (pane) {
    RequestPane.params => KeyValueEditor(
      rows: tab.draft.params,
      env: env,
      addLabel: 'Add parameter',
      emptyNote:
          'Query params show up here as you type them into the URL. '
          'Edits here update the URL.',
      onChanged: (List<KeyValueRow> rows) =>
          onEdit((ApiRequest r) => r.copyWith(params: rows)),
    ),
    RequestPane.headers => KeyValueEditor(
      rows: tab.draft.headers,
      env: env,
      addLabel: 'Add header',
      emptyNote: 'Nothing but the defaults goes out with this request.',
      onChanged: (List<KeyValueRow> rows) =>
          onEdit((ApiRequest r) => r.copyWith(headers: rows)),
    ),
    RequestPane.body => _BodyPane(tab: tab, env: env, onEdit: onEdit),
    RequestPane.auth => _AuthPane(tab: tab, onEdit: onEdit),
  };
}

class _BodyPane extends StatefulWidget {
  const _BodyPane({required this.tab, required this.env, required this.onEdit});

  final WorkspaceTab tab;
  final Environment? env;
  final void Function(ApiRequest Function(ApiRequest)) onEdit;

  @override
  State<_BodyPane> createState() => _BodyPaneState();
}

class _BodyPaneState extends State<_BodyPane> {
  late final TextEditingController _body = TextEditingController(
    text: widget.tab.draft.body,
  );
  String? _mirroring;

  @override
  void initState() {
    super.initState();
    _mirroring = widget.tab.id;
    _body.addListener(_push);
  }

  @override
  void didUpdateWidget(_BodyPane old) {
    super.didUpdateWidget(old);
    if (_mirroring != widget.tab.id) {
      _mirroring = widget.tab.id;
      _body.text = widget.tab.draft.body;
    }
  }

  @override
  void dispose() {
    _body
      ..removeListener(_push)
      ..dispose();
    super.dispose();
  }

  void _push() {
    if (_mirroring != widget.tab.id) return;
    if (widget.tab.draft.body == _body.text) return;
    widget.onEdit((ApiRequest r) => r.copyWith(body: _body.text));
  }

  /// The one bit of JSON validation the editor needs: is it parseable, and if
  /// not, where. The board shows exactly that.
  String? get _jsonError {
    if (widget.tab.draft.bodyType != BodyType.json) return null;
    final String text = _body.text.trim();
    if (text.isEmpty) return null;
    // Braces hold variables, which are not JSON until they resolve, so the
    // check runs against a substituted copy. A decode, not an outline: this
    // runs on every keystroke and the spans would be thrown away.
    final String probe = text.replaceAll(VariableResolver.pattern, '0');
    return JsonOutline.isValid(probe) ? null : 'That is not valid JSON yet.';
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final BodyType type = widget.tab.draft.bodyType;
    final String? error = _jsonError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Space.md,
      children: <Widget>[
        Row(
          spacing: Space.sm,
          children: <Widget>[
            for (final BodyType t in <BodyType>[
              BodyType.json,
              BodyType.form,
              BodyType.raw,
            ])
              PillChip(
                label: t.label,
                selected: type == t,
                onTap: () => widget.onEdit(
                  (ApiRequest r) =>
                      r.copyWith(bodyType: type == t ? BodyType.none : t),
                ),
              ),
            const Spacer(),
            if (type == BodyType.json && _body.text.trim().isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: Space.xs,
                children: <Widget>[
                  Icon(
                    error == null
                        ? Icons.check_circle_rounded
                        : Icons.error_rounded,
                    size: 16,
                    color: error == null ? c.success : c.danger,
                  ),
                  Text(
                    error == null ? 'valid' : 'invalid',
                    style: AppType.monoLabel.copyWith(
                      color: error == null ? c.success : c.danger,
                    ),
                  ),
                ],
              ),
            if (type == BodyType.json)
              AppIconButton(
                icon: Icons.format_align_left_rounded,
                onPressed: error != null ? null : _format,
                semanticLabel: 'Format the JSON',
                filled: false,
                size: 40,
                glyphSize: 22,
              ),
          ],
        ),
        if (!widget.tab.draft.method.sendsBody)
          InlineError(
            icon: Icons.info_outline_rounded,
            message:
                '${widget.tab.draft.method.label} does not normally carry a '
                'body, so this one will not be sent.',
          ),
        if (error != null)
          InlineError(icon: Icons.data_object_rounded, message: error),
        if (type == BodyType.form)
          KeyValueEditor(
            rows: widget.tab.draft.formFields,
            env: widget.env,
            addLabel: 'Add field',
            emptyNote: 'Form fields go out url-encoded.',
            onChanged: (List<KeyValueRow> rows) =>
                widget.onEdit((ApiRequest r) => r.copyWith(formFields: rows)),
          )
        else if (type == BodyType.none)
          Container(
            padding: const EdgeInsets.all(Space.screen),
            decoration: BoxDecoration(
              color: c.surfaceContainer,
              borderRadius: Radii.cardR,
              border: Border.all(color: c.outline),
            ),
            child: Text(
              'No body. Pick JSON, Form or Raw to add one.',
              style: AppType.note.copyWith(color: c.onSurfaceVariant),
            ),
          )
        else
          _BodyEditor(controller: _body, env: widget.env),
      ],
    );
  }

  void _format() {
    final String pretty = JsonOutline.of(
      _body.text,
      colors: context.colors,
      base: AppType.monoCode,
    ).lines.map((CodeLine l) => l.text).join('\n');
    if (pretty.trim().isNotEmpty) _body.text = pretty;
  }
}

/// The body field, with its variables highlighted as they are typed.
class _BodyEditor extends StatelessWidget {
  const _BodyEditor({required this.controller, required this.env});

  final TextEditingController controller;
  final Environment? env;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: c.surfaceContainer,
        borderRadius: Radii.cardR,
        border: Border.all(color: c.outline),
      ),
      child: TextField(
        controller: controller,
        maxLines: null,
        minLines: 6,
        style: AppType.monoCode.copyWith(color: c.onSurface),
        cursorColor: c.primary,
        cursorWidth: 2,
        autocorrect: false,
        enableSuggestions: false,
        keyboardType: TextInputType.multiline,
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: '{\n  "title": "Test post"\n}',
          hintStyle: AppType.monoCode.copyWith(color: c.onSurfaceMuted),
        ),
      ),
    );
  }
}

class _AuthPane extends StatefulWidget {
  const _AuthPane({required this.tab, required this.onEdit});

  final WorkspaceTab tab;
  final void Function(ApiRequest Function(ApiRequest)) onEdit;

  @override
  State<_AuthPane> createState() => _AuthPaneState();
}

class _AuthPaneState extends State<_AuthPane> {
  late final TextEditingController _a = TextEditingController();
  late final TextEditingController _b = TextEditingController();
  AuthType? _loadedFor;

  AuthConfig get _auth => widget.tab.draft.auth;

  @override
  void initState() {
    super.initState();
    _load();
    _a.addListener(_push);
    _b.addListener(_push);
  }

  @override
  void didUpdateWidget(_AuthPane old) {
    super.didUpdateWidget(old);
    if (_loadedFor != _auth.type) _load();
  }

  @override
  void dispose() {
    _a
      ..removeListener(_push)
      ..dispose();
    _b
      ..removeListener(_push)
      ..dispose();
    super.dispose();
  }

  void _load() {
    _loadedFor = _auth.type;
    switch (_auth.type) {
      case AuthType.none:
        _a.text = '';
        _b.text = '';
      case AuthType.bearer:
        _a.text = _auth.token;
      case AuthType.basic:
        _a.text = _auth.username;
        _b.text = _auth.password;
      case AuthType.apiKey:
        _a.text = _auth.keyName;
        _b.text = _auth.keyValue;
    }
  }

  void _push() {
    if (_loadedFor != _auth.type) return;
    final AuthConfig next = switch (_auth.type) {
      AuthType.none => _auth,
      AuthType.bearer => _auth.copyWith(token: _a.text),
      AuthType.basic => _auth.copyWith(username: _a.text, password: _b.text),
      AuthType.apiKey => _auth.copyWith(keyName: _a.text, keyValue: _b.text),
    };
    if (next == _auth) return;
    widget.onEdit((ApiRequest r) => r.copyWith(auth: next));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: <Widget>[
        RowGroup(
          children: <Widget>[
            for (final AuthType type in AuthType.values)
              AppRow(
                title: type.label,
                selected: _auth.type == type,
                trailing: SizedBox(
                  width: IconSpec.tapTarget,
                  height: IconSpec.tapTarget,
                  child: Center(
                    child: Icon(
                      _auth.type == type
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: IconSpec.size,
                      color: _auth.type == type
                          ? context.colors.primary
                          : context.colors.iconMuted,
                    ),
                  ),
                ),
                onTap: () => widget.onEdit(
                  (ApiRequest r) =>
                      r.copyWith(auth: r.auth.copyWith(type: type)),
                ),
              ),
          ],
        ),
        switch (_auth.type) {
          AuthType.none => const SizedBox.shrink(),
          AuthType.bearer => LabelledField(
            label: 'Token',
            controller: _a,
            hint: '{{token}}',
            mono: true,
          ),
          AuthType.basic => Column(
            spacing: Space.md,
            children: <Widget>[
              LabelledField(label: 'Username', controller: _a, mono: true),
              LabelledField(
                label: 'Password',
                controller: _b,
                hint: '{{password}}',
                mono: true,
              ),
            ],
          ),
          AuthType.apiKey => Column(
            spacing: Space.md,
            children: <Widget>[
              LabelledField(
                label: 'Key name',
                controller: _a,
                hint: 'X-API-Key',
                mono: true,
              ),
              LabelledField(
                label: 'Key value',
                controller: _b,
                hint: '{{apiKey}}',
                mono: true,
              ),
              SegmentedToggle<ApiKeyLocation>(
                options: const <(ApiKeyLocation, String)>[
                  (ApiKeyLocation.header, 'Header'),
                  (ApiKeyLocation.query, 'Query'),
                ],
                selected: _auth.keyIn,
                onChanged: (ApiKeyLocation where) => widget.onEdit(
                  (ApiRequest r) =>
                      r.copyWith(auth: r.auth.copyWith(keyIn: where)),
                ),
              ),
            ],
          ),
        },
      ],
    );
  }
}

/// The dim behind the response sheet, tied to how far the sheet is open.
///
/// It fades in over the travel from collapsed to half and goes no darker after
/// that: by half the page behind is mostly covered anyway, and a scrim that
/// keeps darkening on the way to full reads as a flicker.
class _SheetScrim extends StatelessWidget {
  const _SheetScrim({required this.extent, required this.onTap});

  final ValueNotifier<double> extent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color scrim = context.colors.scrim;
    return ValueListenableBuilder<double>(
      valueListenable: extent,
      builder: (BuildContext context, double e, Widget? _) {
        final double t = ((e - _collapsedStop) / (_halfStop - _collapsedStop))
            .clamp(0.0, 1.0);
        return IgnorePointer(
          // Nothing to tap through to while it is dark, and nothing to catch
          // while it is clear.
          ignoring: t < 0.05,
          child: GestureDetector(
            onTap: onTap,
            child: ColoredBox(color: Color.lerp(Colors.transparent, scrim, t)!),
          ),
        );
      },
    );
  }
}

/// Slides the response sheet up the first time it appears.
///
/// [DraggableScrollableSheet] lays itself out at its initial extent, so on its
/// own it simply appears at half height. One slide on mount gives it the
/// entrance every other sheet in the app gets from `showAppSheet`.
class _SheetEntrance extends StatefulWidget {
  const _SheetEntrance({required this.child});

  final Widget child;

  @override
  State<_SheetEntrance> createState() => _SheetEntranceState();
}

class _SheetEntranceState extends State<_SheetEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    duration: Motion.of(context, Motion.sheet),
    vsync: this,
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SlideTransition(
    position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _c,
            curve: Motion.curveOf(context, Motion.decelerate),
          ),
        ),
    child: widget.child,
  );
}
