import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/http/variable_resolver.dart';
import '../../core/models/api_request.dart';
import '../../core/models/environment.dart';
import '../../core/models/key_value.dart';
import '../../core/providers.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/util/format.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_icon_button.dart';
import '../../core/widgets/app_menu.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/states.dart';
import 'variable_sheet.dart';

/// Board 4.5. Changes save as they are made. A secret stays masked until you
/// tap the eye, and hides itself again after thirty seconds.
class VariablesScreen extends ConsumerStatefulWidget {
  const VariablesScreen({required this.environmentId, super.key});

  final String environmentId;

  @override
  ConsumerState<VariablesScreen> createState() => _VariablesScreenState();
}

class _VariablesScreenState extends ConsumerState<VariablesScreen> {
  /// Which secrets are currently shown, and the timer that hides each again.
  final Set<String> _revealed = <String>{};
  final Map<String, Timer> _hideTimers = <String, Timer>{};
  DateTime? _savedAt;

  static const Duration _revealFor = Duration(seconds: 30);

  @override
  void dispose() {
    for (final Timer timer in _hideTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  void _reveal(String id) {
    setState(() => _revealed.add(id));
    _hideTimers.remove(id)?.cancel();
    _hideTimers[id] = Timer(_revealFor, () {
      if (mounted) setState(() => _revealed.remove(id));
    });
  }

  void _hide(String id) {
    _hideTimers.remove(id)?.cancel();
    setState(() => _revealed.remove(id));
  }

  Future<void> _write(Environment env, List<KeyValueRow> variables) async {
    await ref
        .read(environmentsRepositoryProvider)
        .save(env.copyWith(variables: variables));
    if (mounted) setState(() => _savedAt = DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final List<Environment> all = ref.watch(environmentsProvider).value ??
        const <Environment>[];
    final Environment? env = all
        .where((Environment e) => e.id == widget.environmentId)
        .firstOrNull;

    if (env == null) {
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppHeader(title: 'Variables', onBack: () => context.pop()),
              const Expanded(
                child: ErrorStateView(
                  message: 'That environment is no longer here.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final int usedIn = _usedIn(env, ref.watch(requestsProvider).value);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppHeader(
                  title: env.name,
                  subtitle: _savedAt == null
                      ? env.summary
                      : 'saved · ${Fmt.relative(_savedAt!)}',
                  onBack: () => context.pop(),
                  actions: <Widget>[
                    AppIconButton(
                      icon: Icons.edit_outlined,
                      onPressed: () =>
                          context.push(Routes.editEnvironment(env.id)),
                      semanticLabel: 'Edit name, icon and colour',
                    ),
                    Builder(
                      builder: (BuildContext anchor) => AppIconButton(
                        icon: Icons.more_horiz_rounded,
                        onPressed: () => _overflow(anchor, env),
                        semanticLabel: 'More options',
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: env.variables.isEmpty
                      ? EmptyState(
                          icon: Icons.data_object_rounded,
                          title: 'No variables',
                          message:
                              'Add one, then use it anywhere as {{name}}: in a '
                              'URL, a header, a body or the auth tab.',
                          primaryLabel: 'Add variable',
                          primaryIcon: Icons.add_rounded,
                          onPrimary: () => _add(env),
                          topPadding: 60,
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(
                            Space.screen,
                            Space.md,
                            Space.screen,
                            Space.bottomSafe,
                          ),
                          children: <Widget>[
                            SectionHeader(
                              label: 'Variables · ${env.variables.length}',
                              note: usedIn == 0
                                  ? 'use as {{name}}'
                                  : 'used in ${Fmt.count(usedIn, 'request')}',
                            ),
                            const SizedBox(height: Space.row),
                            _ReorderableVariables(
                              env: env,
                              revealed: _revealed,
                              onReveal: _reveal,
                              onHide: _hide,
                              onEdit: (KeyValueRow row) => _edit(env, row),
                              onDelete: (KeyValueRow row) => _delete(env, row),
                              onReorder: (int from, int to) {
                                final List<KeyValueRow> next =
                                    <KeyValueRow>[...env.variables];
                                next.insert(to, next.removeAt(from));
                                _write(env, next);
                              },
                            ),
                            const SizedBox(height: Space.row),
                            AppButton(
                              label: 'Add variable',
                              icon: Icons.add_rounded,
                              type: AppButtonType.dotted,
                              fullWidth: true,
                              onPressed: () => _add(env),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
      backgroundColor: c.surface,
    );
  }

  /// How many saved requests refer to any of this environment's variables.
  static int _usedIn(Environment env, List<ApiRequest>? requests) {
    if (requests == null || requests.isEmpty) return 0;
    final Set<String> names = <String>{
      for (final KeyValueRow v in env.variables) v.key,
    };
    if (names.isEmpty) return 0;
    int count = 0;
    for (final ApiRequest r in requests) {
      final bool hit = <String>[
        r.url,
        r.body,
        for (final KeyValueRow h in r.headers) h.value,
        for (final KeyValueRow p in r.params) p.value,
        r.auth.token,
        r.auth.keyValue,
      ].any(
        (String template) =>
            VariableResolver.namesIn(template).any(names.contains),
      );
      if (hit) count++;
    }
    return count;
  }

  Future<void> _add(Environment env) async {
    final KeyValueRow? row = await showVariableSheet(
      context,
      environmentName: env.name,
    );
    if (row == null) return;
    await _write(env, <KeyValueRow>[...env.variables, row]);
  }

  Future<void> _edit(Environment env, KeyValueRow row) async {
    final KeyValueRow? updated = await showVariableSheet(
      context,
      environmentName: env.name,
      initial: row,
    );
    if (updated == null) return;
    await _write(env, <KeyValueRow>[
      for (final KeyValueRow v in env.variables)
        if (v.id == row.id) updated else v,
    ]);
  }

  Future<void> _delete(Environment env, KeyValueRow row) async {
    final int at = env.variables.indexWhere((KeyValueRow v) => v.id == row.id);
    if (at < 0) return;
    final List<KeyValueRow> without = <KeyValueRow>[...env.variables]
      ..removeAt(at);
    await _write(env, without);
    if (!mounted) return;
    AppSnackbar.undo(
      context,
      message: '${row.key} deleted',
      onUndo: () => _write(
        env,
        <KeyValueRow>[...without]..insert(at, row),
      ),
    );
  }

  Future<void> _overflow(BuildContext anchor, Environment env) async {
    final String? choice = await showAppMenu<String>(
      context: anchor,
      entries: const <AppMenuEntry<String>>[
        AppMenuEntry<String>(
          value: 'paste',
          label: 'Paste lines',
          icon: Icons.content_paste_rounded,
          note: 'KEY=value, one per line',
        ),
        AppMenuEntry<String>(
          value: 'copy',
          label: 'Copy as .env',
          icon: Icons.content_copy_rounded,
          note: 'secrets left out',
        ),
      ],
    );
    if (!mounted) return;
    switch (choice) {
      case 'paste':
        await _pasteLines(env);
      case 'copy':
        await _copyEnv(env);
    }
  }

  Future<void> _pasteLines(Environment env) async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    final List<KeyValueRow> parsed = parseVariableLines(data?.text ?? '');
    if (!mounted) return;
    if (parsed.isEmpty) {
      AppSnackbar.info(context, 'No KEY=value lines on the clipboard');
      return;
    }
    // A pasted key that already exists updates it rather than adding a twin.
    final Map<String, KeyValueRow> byKey = <String, KeyValueRow>{
      for (final KeyValueRow v in env.variables) v.key: v,
    };
    for (final KeyValueRow row in parsed) {
      final KeyValueRow? old = byKey[row.key];
      byKey[row.key] = old == null ? row : old.copyWith(value: row.value);
    }
    await _write(env, byKey.values.toList(growable: false));
    if (mounted) {
      AppSnackbar.info(context, '${Fmt.count(parsed.length, 'line')} applied');
    }
  }

  Future<void> _copyEnv(Environment env) async {
    final String text = env.variables
        .where((KeyValueRow v) => !v.secret)
        .map((KeyValueRow v) => '${v.key}=${v.value}')
        .join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) AppSnackbar.info(context, 'Copied, secrets left out');
  }
}

class _ReorderableVariables extends StatelessWidget {
  const _ReorderableVariables({
    required this.env,
    required this.revealed,
    required this.onReveal,
    required this.onHide,
    required this.onEdit,
    required this.onDelete,
    required this.onReorder,
  });

  final Environment env;
  final Set<String> revealed;
  final ValueChanged<String> onReveal;
  final ValueChanged<String> onHide;
  final ValueChanged<KeyValueRow> onEdit;
  final ValueChanged<KeyValueRow> onDelete;
  final void Function(int from, int to) onReorder;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surfaceContainer,
        borderRadius: Radii.cardR,
        border: Border.all(color: c.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: env.variables.length,
        onReorderItem: onReorder,
        proxyDecorator:
            (Widget child, int index, Animation<double> animation) =>
                AnimatedBuilder(
                  animation: animation,
                  builder: (BuildContext context, Widget? _) => Transform.scale(
                    scale: 1 + 0.02 * animation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: c.surfaceContainerHigh,
                        borderRadius: Radii.cardR,
                        border: Border.all(color: c.primary, width: 2),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: child,
                    ),
                  ),
                ),
        itemBuilder: (BuildContext context, int i) {
          final KeyValueRow row = env.variables[i];
          return Column(
            key: ValueKey<String>('var-${row.id}'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (i > 0) Divider(color: c.divider, height: 1),
              Dismissible(
                key: ValueKey<String>('dismiss-var-${row.id}'),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => onDelete(row),
                background: Container(
                  color: c.dangerContainer,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: Space.xl),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: IconSpec.size,
                    color: c.onDangerContainer,
                  ),
                ),
                child: _VariableRow(
                  index: i,
                  row: row,
                  revealed: revealed.contains(row.id),
                  onReveal: () => onReveal(row.id),
                  onHide: () => onHide(row.id),
                  onEdit: () => onEdit(row),
                  onDelete: () => onDelete(row),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VariableRow extends StatelessWidget {
  const _VariableRow({
    required this.index,
    required this.row,
    required this.revealed,
    required this.onReveal,
    required this.onHide,
    required this.onEdit,
    required this.onDelete,
  });

  final int index;
  final KeyValueRow row;
  final bool revealed;
  final VoidCallback onReveal;
  final VoidCallback onHide;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final bool hidden = row.secret && !revealed;
    return InkWell(
      // The Android click sound belongs to the system, not to a tool.
      enableFeedback: false,
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.sm),
        child: Row(
          spacing: Space.sm,
          children: <Widget>[
            ReorderableDelayedDragStartListener(
              index: index,
              child: SizedBox(
                width: IconSpec.tapTarget,
                height: IconSpec.tapTarget,
                child: Center(
                  child: Icon(
                    Icons.drag_indicator_rounded,
                    size: IconSpec.size,
                    color: c.iconMuted,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: <Widget>[
                  Row(
                    spacing: 6,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          row.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.monoTabular.copyWith(
                            color: c.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (row.secret)
                        Icon(
                          hidden
                              ? Icons.lock_rounded
                              : Icons.lock_open_rounded,
                          size: 14,
                          color: c.iconMuted,
                        ),
                    ],
                  ),
                  Text(
                    hidden ? VariableResolver.mask(row.value) : row.value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.monoTabular.copyWith(
                      color: c.onSurfaceVariant,
                    ),
                  ),
                  if (row.secret && revealed)
                    Text(
                      'hides again in 30 s',
                      style: AppType.monoLabel.copyWith(
                        color: c.onSurfaceMuted,
                      ),
                    ),
                ],
              ),
            ),
            if (row.secret)
              AppIconButton(
                icon: hidden
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                onPressed: hidden ? onReveal : onHide,
                semanticLabel: hidden
                    ? 'Show ${row.key}'
                    : 'Hide ${row.key}',
                filled: false,
                tint: c.iconMuted,
              )
            else
              Builder(
                builder: (BuildContext anchor) => AppIconButton(
                  icon: Icons.more_vert_rounded,
                  onPressed: () async {
                    final String? choice = await showAppMenu<String>(
                      context: anchor,
                      entries: const <AppMenuEntry<String>>[
                        AppMenuEntry<String>(
                          value: 'edit',
                          label: 'Edit',
                          icon: Icons.edit_outlined,
                        ),
                        AppMenuEntry<String>(
                          value: 'delete',
                          label: 'Delete',
                          icon: Icons.delete_outline_rounded,
                          danger: true,
                        ),
                      ],
                    );
                    if (choice == 'edit') onEdit();
                    if (choice == 'delete') onDelete();
                  },
                  semanticLabel: 'Options for ${row.key}',
                  filled: false,
                  tint: c.iconMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
