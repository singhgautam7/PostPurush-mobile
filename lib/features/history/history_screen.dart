import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/history_entry.dart';
import '../../core/models/http_method.dart';
import '../../core/providers.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/util/format.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_icon_button.dart';
import '../../core/widgets/app_menu.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/chips.dart';
import '../../core/widgets/fields.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/states.dart';
import '../settings/settings_controller.dart';
import '../workspace/workspace_controller.dart';

/// Board 5.1 and 5.2. Tap a row to reopen the request exactly as it was sent,
/// with its response. Resend runs it again straight away.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _search = TextEditingController();
  StatusBand _band = StatusBand.all;
  HttpMethod? _method;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _accepts(HistoryEntry e) {
    if (!_band.matches(e.status)) return false;
    if (_method != null && e.method != _method) return false;
    final String q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    return e.name.toLowerCase().contains(q) ||
        e.path.toLowerCase().contains(q) ||
        e.host.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AsyncValue<List<HistoryEntry>> history = ref.watch(historyProvider);
    final int keepDays = ref.watch(settingsProvider).historyDays;
    final List<HistoryEntry> all = history.value ?? const <HistoryEntry>[];
    final List<HistoryEntry> shown = <HistoryEntry>[
      for (final HistoryEntry e in all) if (_accepts(e)) e,
    ];

    if (!history.isLoading && all.isEmpty) {
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppHeader(title: 'History', onBack: () => context.pop()),
              Expanded(
                child: EmptyState(
                  icon: Icons.history_rounded,
                  title: 'Nothing sent yet',
                  message:
                      'Requests you send appear here, newest first. They are '
                      'kept on this device for $keepDays days.',
                  primaryLabel: 'New request',
                  onPrimary: () {
                    ref.read(workspaceProvider.notifier).openBlank();
                    context.go(Routes.workspace);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppHeader(
              title: 'History',
              subtitle: '${all.length} kept · $keepDays days',
              onBack: () => context.pop(),
              actions: <Widget>[
                Builder(
                  builder: (BuildContext anchor) => AppIconButton(
                    icon: Icons.more_horiz_rounded,
                    onPressed: () => _overflow(anchor),
                    semanticLabel: 'More options',
                  ),
                ),
              ],
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
                    hint: 'Search URL or name',
                    onChanged: (_) => setState(() {}),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      spacing: Space.sm,
                      children: <Widget>[
                        for (final StatusBand band in StatusBand.values)
                          PillChip(
                            label: band.label,
                            count: all
                                .where((HistoryEntry e) => band.matches(e.status))
                                .length,
                            selected: _band == band,
                            onTap: () => setState(() => _band = band),
                          ),
                        Builder(
                          builder: (BuildContext anchor) => PillChip(
                            label: _method?.label ?? 'Method',
                            icon: Icons.arrow_drop_down_rounded,
                            selected: _method != null,
                            onTap: () => _pickMethod(anchor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: history.isLoading && all.isEmpty
                  ? const Delayed(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: Space.screen),
                        child: RowGroup(
                          children: <Widget>[SkeletonRow(), SkeletonRow()],
                        ),
                      ),
                    )
                  : shown.isEmpty
                      ? EmptyState(
                          icon: Icons.filter_alt_off_rounded,
                          title: 'No matches',
                          message: 'Nothing in history matches those filters.',
                          primaryLabel: 'Clear filters',
                          primaryIcon: Icons.close_rounded,
                          onPrimary: () => setState(() {
                            _band = StatusBand.all;
                            _method = null;
                            _search.clear();
                          }),
                          topPadding: 40,
                        )
                      : _Grouped(
                          entries: shown,
                          onOpen: (HistoryEntry e) {
                            ref
                                .read(workspaceProvider.notifier)
                                .openFromHistory(e);
                            context.go(Routes.workspace);
                          },
                          onReplay: (HistoryEntry e) async {
                            final WorkspaceController controller = ref.read(
                              workspaceProvider.notifier,
                            );
                            controller.openDraft(e.requestSnapshot);
                            if (context.mounted) context.go(Routes.workspace);
                            await controller.send();
                          },
                          onDelete: (HistoryEntry e) async {
                            await ref
                                .read(historyRepositoryProvider)
                                .delete(e.id);
                            if (!context.mounted) return;
                            AppSnackbar.undo(
                              context,
                              message: 'Entry deleted',
                              onUndo: () => ref
                                  .read(historyRepositoryProvider)
                                  .add(e),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      backgroundColor: c.surface,
    );
  }

  Future<void> _pickMethod(BuildContext anchor) async {
    final String? choice = await showAppMenu<String>(
      context: anchor,
      entries: <AppMenuEntry<String>>[
        AppMenuEntry<String>(
          value: 'all',
          label: 'Any method',
          selected: _method == null,
        ),
        const AppMenuEntry<String>.divider(),
        for (final HttpMethod m in HttpMethod.values)
          AppMenuEntry<String>(
            value: m.name,
            label: m.label,
            selected: _method == m,
          ),
      ],
    );
    if (choice == null) return;
    setState(
      () => _method = choice == 'all'
          ? null
          : HttpMethod.values.firstWhere((HttpMethod m) => m.name == choice),
    );
  }

  Future<void> _overflow(BuildContext anchor) async {
    final String? choice = await showAppMenu<String>(
      context: anchor,
      entries: const <AppMenuEntry<String>>[
        AppMenuEntry<String>(
          value: 'analytics',
          label: 'Analytics',
          icon: Icons.bar_chart_rounded,
        ),
        AppMenuEntry<String>(
          value: 'retention',
          label: 'How long to keep',
          icon: Icons.schedule_rounded,
        ),
        AppMenuEntry<String>.divider(),
        AppMenuEntry<String>(
          value: 'clear',
          label: 'Clear history',
          icon: Icons.delete_outline_rounded,
          danger: true,
        ),
      ],
    );
    if (!mounted) return;
    switch (choice) {
      case 'analytics':
        await context.push(Routes.analytics);
      case 'retention':
        await context.push(Routes.settings);
      case 'clear':
        final bool ok = await confirmDialog(
          context,
          title: 'Clear history?',
          message:
              'Every entry goes. Saved requests and folders are not '
              'touched.',
          confirmLabel: 'Clear',
        );
        if (ok) await ref.read(historyRepositoryProvider).clear();
    }
  }
}

/// Newest first, with a day header above each run.
class _Grouped extends StatelessWidget {
  const _Grouped({
    required this.entries,
    required this.onOpen,
    required this.onReplay,
    required this.onDelete,
  });

  final List<HistoryEntry> entries;
  final ValueChanged<HistoryEntry> onOpen;
  final ValueChanged<HistoryEntry> onReplay;
  final ValueChanged<HistoryEntry> onDelete;

  @override
  Widget build(BuildContext context) {
    final List<(String, List<HistoryEntry>)> groups =
        <(String, List<HistoryEntry>)>[];
    for (final HistoryEntry e in entries) {
      final String day = Fmt.dayLabel(e.sentAt);
      if (groups.isEmpty || groups.last.$1 != day) {
        groups.add((day, <HistoryEntry>[e]));
      } else {
        groups.last.$2.add(e);
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        Space.screen,
        0,
        Space.screen,
        Space.bottomSafe,
      ),
      itemCount: groups.length,
      itemBuilder: (BuildContext context, int i) {
        final (String day, List<HistoryEntry> rows) = groups[i];
        return Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : Space.section),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SectionHeader(label: '$day · ${rows.length}'),
              const SizedBox(height: Space.row),
              RowGroup(
                children: <Widget>[
                  for (final HistoryEntry e in rows)
                    Dismissible(
                      key: ValueKey<String>('hist-${e.id}'),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => onDelete(e),
                      background: ColoredBox(
                        color: context.colors.dangerContainer,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Space.xl,
                            ),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              size: IconSpec.size,
                              color: context.colors.onDangerContainer,
                            ),
                          ),
                        ),
                      ),
                      child: HistoryRow(
                        entry: e,
                        onTap: () => onOpen(e),
                        onReplay: () => onReplay(e),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// One history row, shared with the Analytics recent block and Search.
class HistoryRow extends StatelessWidget {
  const HistoryRow({
    required this.entry,
    required this.onTap,
    this.onReplay,
    super.key,
  });

  final HistoryEntry entry;
  final VoidCallback onTap;
  final VoidCallback? onReplay;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final (Color dot, _, _) = StatusChip.rolesFor(
      c,
      entry.status,
      arrived: entry.failure == null,
    );
    return InkWell(
      // The Android click sound belongs to the system, not to a tool.
      enableFeedback: false,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: Space.lg, right: Space.xs),
        child: Row(
          spacing: Space.md,
          children: <Widget>[
            MethodChip(entry.method),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.row),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 3,
                  children: <Widget>[
                    Text.rich(
                      TextSpan(
                        children: <InlineSpan>[
                          TextSpan(
                            text: entry.host,
                            style: AppType.monoTabular.copyWith(
                              color: c.onSurfaceVariant,
                            ),
                          ),
                          TextSpan(
                            text: entry.path,
                            style: AppType.monoTabular.copyWith(
                              color: c.onSurface,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text.rich(
                      TextSpan(
                        children: <InlineSpan>[
                          TextSpan(
                            text: entry.failure == null
                                ? '${entry.status}'
                                : 'failed',
                            style: AppType.monoLabelStrong.copyWith(color: dot),
                          ),
                          TextSpan(
                            text: ' · ${Fmt.duration(entry.durationMs)}'
                                ' · ${Fmt.relative(entry.sentAt)}',
                            style: AppType.monoLabel.copyWith(
                              color: c.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            if (onReplay != null)
              AppIconButton(
                icon: Icons.replay_rounded,
                onPressed: onReplay,
                semanticLabel: 'Send this again',
                filled: false,
                tint: c.iconMuted,
              ),
          ],
        ),
      ),
    );
  }
}
