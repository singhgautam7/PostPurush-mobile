import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/history_repository.dart';
import '../../core/models/folder.dart';
import '../../core/models/history_entry.dart';
import '../../core/providers.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/util/format.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_icon_button.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/chart_card.dart';
import '../../core/widgets/chips.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/states.dart';
import '../history/history_screen.dart';
import '../workspace/workspace_controller.dart';
import 'analytics_summary.dart';

/// Which axis the breakdown groups by.
enum _By { collection, endpoint }

/// The chosen range. Its own provider so the page can be rebuilt by it without
/// the range resetting on every rebuild.
final NotifierProvider<AnalyticsRange, TimeRange> analyticsRangeProvider =
    NotifierProvider<AnalyticsRange, TimeRange>(AnalyticsRange.new);

class AnalyticsRange extends Notifier<TimeRange> {
  @override
  TimeRange build() => TimeRange.week;

  void set(TimeRange range) => state = range;
}

/// The summary for the chosen range, recomputed when the range changes or a new
/// request lands. Only the indexed columns are read, so a 30-day range costs
/// one query and no payload decodes.
final FutureProvider<AnalyticsSummary> analyticsSummaryProvider =
    FutureProvider<AnalyticsSummary>((Ref ref) async {
      final TimeRange range = ref.watch(analyticsRangeProvider);
      // Watching the history stream is what makes the page live: a send
      // invalidates this and the figures move.
      ref.watch(historyProvider);
      final List<HistoryStat> stats = await ref
          .read(historyRepositoryProvider)
          .statsSince(range.since(DateTime.now()));
      return AnalyticsSummary.of(stats, range: range);
    });

/// Board 10. Worked out from local history; nothing is uploaded.
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  _By _by = _By.collection;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final TimeRange range = ref.watch(analyticsRangeProvider);
    final AsyncValue<AnalyticsSummary> summary = ref.watch(
      analyticsSummaryProvider,
    );
    final List<Folder> folders = ref.watch(foldersProvider).value ??
        const <Folder>[];
    final AnalyticsSummary? data = summary.value;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppHeader(
              title: 'Analytics',
              onBack: () => context.pop(),
              actions: <Widget>[
                AppIconButton(
                  icon: Icons.history_rounded,
                  onPressed: () => context.push(Routes.history),
                  semanticLabel: 'Open History',
                ),
              ],
            ),
            // The range control stays even when there is nothing to show, so
            // the layout does not jump once there is.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.screen,
                Space.xs,
                Space.screen,
                Space.md,
              ),
              child: SegmentedToggle<TimeRange>(
                options: <(TimeRange, String)>[
                  for (final TimeRange r in TimeRange.values) (r, r.label),
                ],
                selected: range,
                onChanged: (TimeRange r) =>
                    ref.read(analyticsRangeProvider.notifier).set(r),
              ),
            ),
            Expanded(
              child: data == null
                  ? const Delayed(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: Space.screen),
                        child: RowGroup(
                          children: <Widget>[SkeletonRow(), SkeletonRow()],
                        ),
                      ),
                    )
                  : data.total == 0
                      ? EmptyState(
                          icon: Icons.bar_chart_rounded,
                          title: 'No request history yet',
                          message:
                              'Analytics are worked out from the requests you '
                              'send, on this device.',
                          primaryLabel: 'New request',
                          primaryIcon: Icons.add_rounded,
                          onPrimary: () {
                            ref.read(workspaceProvider.notifier).openBlank();
                            context.go(Routes.workspace);
                          },
                          topPadding: 40,
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(
                            Space.screen,
                            0,
                            Space.screen,
                            Space.bottomSafe,
                          ),
                          children: <Widget>[
                            Row(
                              spacing: Space.row,
                              children: <Widget>[
                                Expanded(
                                  child: StatCard(
                                    label: 'Requests',
                                    value: Fmt.thousands(data.total),
                                  ),
                                ),
                                Expanded(
                                  child: StatCard(
                                    label: 'Success',
                                    value: (data.successRate * 100)
                                        .toStringAsFixed(1),
                                    unit: '%',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: Space.row),
                            Row(
                              spacing: Space.row,
                              children: <Widget>[
                                Expanded(
                                  child: StatCard(
                                    label: 'Avg time',
                                    value: Fmt.thousands(data.avgMs),
                                    unit: 'ms',
                                  ),
                                ),
                                Expanded(
                                  child: StatCard(
                                    label: 'Errors',
                                    value: (data.errorRate * 100)
                                        .toStringAsFixed(1),
                                    unit: '%',
                                    tint: data.errorRate > 0 ? c.danger : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: Space.section),
                            StatusBreakdownCard(
                              counts: data.bandCounts,
                              total: data.total,
                            ),
                            const SizedBox(height: Space.row),
                            ChartCard(
                              title: 'Response time',
                              unit: 'ms',
                              legend: const <(String, bool)>[
                                ('avg', false),
                                ('P95', true),
                              ],
                              xLabels: data.bucketLabels,
                              series: <ChartSeries>[
                                ChartSeries(
                                  values: data.p95Series,
                                  colour: c.accent,
                                  dashed: true,
                                  strokeWidth: 2,
                                ),
                                ChartSeries(
                                  values: data.avgSeries,
                                  colour: c.primary,
                                  dots: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: Space.section),
                            Row(
                              children: <Widget>[
                                const Expanded(
                                  child: SectionHeader(label: 'Breakdown'),
                                ),
                                SizedBox(
                                  width: 200,
                                  child: SegmentedToggle<_By>(
                                    options: const <(_By, String)>[
                                      (_By.collection, 'Collection'),
                                      (_By.endpoint, 'Endpoint'),
                                    ],
                                    selected: _by,
                                    onChanged: (_By value) =>
                                        setState(() => _by = value),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: Space.row),
                            _Breakdown(
                              rows: _by == _By.collection
                                  ? data.byCollection(folders)
                                  : data.byEndpoint,
                            ),
                            const SizedBox(height: Space.section),
                            SectionHeader(
                              label: 'Recent',
                              trailing: TextButton(
                                onPressed: () => context.push(Routes.history),
                                child: Text(
                                  'See all in History',
                                  style: AppType.monoLabel.copyWith(
                                    color: c.accent,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: Space.row),
                            _Recent(),
                          ],
                        ),
            ),
          ],
        ),
      ),
      backgroundColor: c.surface,
    );
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.rows});

  final List<BreakdownRow> rows;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.md),
        child: Text(
          'Nothing to break down yet.',
          style: AppType.bodyMedium.copyWith(color: c.onSurfaceVariant),
        ),
      );
    }
    return RowGroup(
      children: <Widget>[
        for (final BreakdownRow row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.lg,
              vertical: Space.sm,
            ),
            child: Row(
              spacing: Space.md,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 3,
                    children: <Widget>[
                      Text(
                        row.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.titleMedium.copyWith(
                          color: c.onSurface,
                        ),
                      ),
                      Text(
                        '${Fmt.thousands(row.count)} req · '
                        '${Fmt.thousands(row.avgMs)} ms avg',
                        style: AppType.monoLabel.copyWith(
                          color: c.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(row.errorRate * 100).toStringAsFixed(1)}%',
                  style: AppType.monoTabular.copyWith(
                    fontWeight: FontWeight.w600,
                    // A high error rate is the one thing on this page worth
                    // tinting, and the threshold is the board's own.
                    color: row.errorRate >= 0.1
                        ? c.danger
                        : c.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Recent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<HistoryEntry> recent = (ref.watch(historyProvider).value ??
            const <HistoryEntry>[])
        .take(4)
        .toList(growable: false);
    if (recent.isEmpty) return const SizedBox.shrink();
    return RowGroup(
      children: <Widget>[
        for (final HistoryEntry e in recent)
          HistoryRow(
            entry: e,
            onTap: () {
              ref.read(workspaceProvider.notifier).openFromHistory(e);
              context.go(Routes.workspace);
            },
            onReplay: () async {
              final WorkspaceController controller = ref.read(
                workspaceProvider.notifier,
              );
              controller.openDraft(e.requestSnapshot);
              if (context.mounted) context.go(Routes.workspace);
              await controller.send();
            },
          ),
      ],
    );
  }
}
