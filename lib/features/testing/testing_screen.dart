import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/transitions.dart';
import '../../core/http/api_client.dart';
import '../../core/http/assertion_runner.dart';
import '../../core/http/load_tester.dart';
import '../../core/http/request_builder.dart';
import '../../core/models/api_request.dart';
import '../../core/models/api_response.dart';
import '../../core/models/load_test.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/util/format.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/chart_card.dart';
import '../../core/widgets/chips.dart';
import '../../core/widgets/fields.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/states.dart';
import 'assertion_sheet.dart';
import 'request_picker_sheet.dart';

enum _Mode { assertions, load }

/// Board 11. Assertions check one response; Load repeats a request and measures
/// it. Both run from a saved request you pick at the top.
class TestingScreen extends ConsumerStatefulWidget {
  const TestingScreen({super.key});

  @override
  ConsumerState<TestingScreen> createState() => _TestingScreenState();
}

class _TestingScreenState extends ConsumerState<TestingScreen> {
  _Mode _mode = _Mode.assertions;
  ApiRequest? _request;

  // Assertions.
  List<AssertionResult>? _results;
  ApiResponse? _lastResponse;
  bool _running = false;

  // Load test.
  LoadTestConfig _config = const LoadTestConfig();
  LoadTestResult? _load;
  StreamSubscription<LoadTestResult>? _loadSub;

  @override
  void dispose() {
    unawaited(_loadSub?.cancel());
    // Losing the screen must not leave a load test hammering a server.
    ref.read(loadTesterProvider).stop();
    super.dispose();
  }

  /// The first saved request is a better default than nothing at all.
  ApiRequest? get _target {
    if (_request != null) return _request;
    final List<ApiRequest> all = ref.read(requestsProvider).value ??
        const <ApiRequest>[];
    return all.isEmpty ? null : all.first;
  }

  Future<void> _pick() async {
    final ApiRequest? chosen = await showRequestPickerSheet(context, ref);
    if (chosen == null) return;
    setState(() {
      _request = chosen;
      _results = null;
      _lastResponse = null;
      _load = null;
    });
  }

  Future<void> _runAssertions(ApiRequest request) async {
    if (request.assertions.isEmpty) return;
    setState(() {
      _running = true;
      _results = null;
    });
    final ApiResponse response = await ref.read(apiClientProvider).send(
      RequestBuilder.build(request, ref.read(activeEnvironmentProvider)),
    );
    if (!mounted) return;
    setState(() {
      _running = false;
      _lastResponse = response;
      _results = AssertionRunner.runAll(request.assertions, response);
    });
  }

  Future<void> _saveAssertions(ApiRequest request) =>
      ref.read(collectionsRepositoryProvider).saveRequest(
        request.copyWith(updatedAt: DateTime.now()),
      );

  Future<void> _startLoad(ApiRequest request) async {
    await _loadSub?.cancel();
    setState(() => _load = const LoadTestResult());
    final Stream<LoadTestResult> stream = ref.read(loadTesterProvider).run(
      wire: RequestBuilder.build(request, ref.read(activeEnvironmentProvider)),
      config: _config,
    );
    _loadSub = stream.listen((LoadTestResult result) {
      if (mounted) setState(() => _load = result);
    });
  }

  void _stopLoad() => ref.read(loadTesterProvider).stop();

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AsyncValue<List<ApiRequest>> requests = ref.watch(requestsProvider);
    final ApiRequest? request = _target;

    if (!requests.isLoading &&
        (requests.value ?? const <ApiRequest>[]).isEmpty) {
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppHeader(title: 'Testing', onBack: () => context.pop()),
              const Expanded(
                child: EmptyState(
                  icon: Icons.science_outlined,
                  title: 'Nothing to test',
                  message:
                      'Save a request first. Assertions are kept with it, so '
                      'they run from the workspace too.',
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
            AppHeader(title: 'Testing', onBack: () => context.pop()),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.screen,
                Space.xs,
                Space.screen,
                Space.md,
              ),
              child: SegmentedToggle<_Mode>(
                options: const <(_Mode, String)>[
                  (_Mode.assertions, 'Assertions'),
                  (_Mode.load, 'Load'),
                ],
                selected: _mode,
                onChanged: (_Mode value) => setState(() => _mode = value),
              ),
            ),
            Expanded(
              child: request == null
                  ? const Delayed(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: Space.screen),
                        child: RowGroup(children: <Widget>[SkeletonRow()]),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        Space.screen,
                        0,
                        Space.screen,
                        Space.bottomSafe,
                      ),
                      children: <Widget>[
                        _TargetCard(request: request, onTap: _pick),
                        const SizedBox(height: Space.lg),
                        // Assertions and Load occupy the same page below the
                        // target, so the swap is a cross-fade.
                        AppSwitcher(
                          child: Column(
                            key: ValueKey<String>(
                              '${_mode.name}'
                              '${_results == null ? '' : '-results'}'
                              '${_load == null ? '' : '-load'}',
                            ),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: _mode == _Mode.assertions
                                ? _assertionsBody(request, c)
                                : _loadBody(request, c),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      backgroundColor: c.surface,
    );
  }

  List<Widget> _assertionsBody(ApiRequest request, AppColors c) {
    final List<Assertion> assertions = request.assertions;
    final List<AssertionResult>? results = _results;
    return <Widget>[
      if (results != null && _lastResponse != null)
        Padding(
          padding: const EdgeInsets.only(bottom: Space.lg),
          child: _Summary(results: results, response: _lastResponse!),
        ),
      SectionHeader(
        label: 'Assertions · ${assertions.length}',
        note: _running ? 'waiting for response' : 'saved with the request',
      ),
      const SizedBox(height: Space.row),
      if (assertions.isEmpty)
        AppButton(
          label: 'Add assertion',
          icon: Icons.add_rounded,
          type: AppButtonType.dotted,
          fullWidth: true,
          onPressed: () => _addAssertion(request),
        )
      else
        RowGroup(
          children: <Widget>[
            for (int i = 0; i < assertions.length; i++)
              _AssertionRow(
                assertion: assertions[i],
                result: results == null || i >= results.length
                    ? null
                    : results[i],
                waiting: _running,
                onEdit: () => _editAssertion(request, assertions[i]),
                onDelete: () => _deleteAssertion(request, assertions[i]),
              ),
            AddRowButton(
              label: 'Add assertion',
              onPressed: () => _addAssertion(request),
            ),
          ],
        ),
      const SizedBox(height: Space.lg),
      if (_running)
        AppButton(
          label: 'Cancel',
          icon: Icons.close_rounded,
          type: AppButtonType.secondary,
          fullWidth: true,
          onPressed: () => setState(() => _running = false),
        )
      else
        Row(
          spacing: Space.row,
          children: <Widget>[
            if (results != null)
              Expanded(
                child: AppButton(
                  label: 'Share',
                  icon: Icons.share_outlined,
                  type: AppButtonType.outlined,
                  fullWidth: true,
                  onPressed: () => SharePlus.instance.share(
                    ShareParams(
                      text: _resultsText(request, results, _lastResponse),
                      subject: 'Assertions · ${request.displayName}',
                    ),
                  ),
                ),
              ),
            Expanded(
              flex: 2,
              child: AppButton(
                label: results == null
                    ? 'Run ${Fmt.count(assertions.length, 'assertion')}'
                    : 'Run again',
                icon: results == null
                    ? Icons.play_arrow_rounded
                    : Icons.replay_rounded,
                fullWidth: true,
                onPressed: assertions.isEmpty
                    ? null
                    : () => _runAssertions(request),
              ),
            ),
          ],
        ),
    ];
  }

  List<Widget> _loadBody(ApiRequest request, AppColors c) {
    final LoadTestResult? load = _load;
    final bool running = load != null && !load.finished;
    return <Widget>[
      if (load == null) ...<Widget>[
        const SectionHeader(label: 'Setup'),
        const SizedBox(height: Space.row),
        RowGroup(
          children: <Widget>[
            StepperRow(
              label: 'Concurrency',
              note: 'requests in parallel',
              value: _config.concurrency,
              min: LoadTestConfig.minConcurrency,
              max: LoadTestConfig.maxConcurrency,
              onChanged: (int value) =>
                  setState(() => _config = _config.copyWith(concurrency: value)),
            ),
            Padding(
              padding: const EdgeInsets.all(Space.md),
              child: SegmentedToggle<LoadStop>(
                options: const <(LoadStop, String)>[
                  (LoadStop.iterations, 'Iterations'),
                  (LoadStop.duration, 'Duration'),
                ],
                selected: _config.stop,
                onChanged: (LoadStop stop) =>
                    setState(() => _config = _config.copyWith(stop: stop)),
              ),
            ),
            if (_config.stop == LoadStop.iterations)
              StepperRow(
                label: 'Iterations',
                note: 'total requests',
                value: _config.iterations,
                step: 50,
                min: LoadTestConfig.minIterations,
                max: LoadTestConfig.maxIterations,
                onChanged: (int value) => setState(
                  () => _config = _config.copyWith(iterations: value),
                ),
              )
            else
              StepperRow(
                label: 'Duration',
                note: 'how long to keep going',
                value: _config.durationSeconds,
                step: 5,
                suffix: ' s',
                min: LoadTestConfig.minDuration,
                max: LoadTestConfig.maxDuration,
                onChanged: (int value) => setState(
                  () => _config = _config.copyWith(durationSeconds: value),
                ),
              ),
          ],
        ),
        const SizedBox(height: Space.lg),
        const InlineError(
          icon: Icons.info_outline_rounded,
          message:
              'Runs from this phone, so the timings include your own network.',
        ),
        const SizedBox(height: Space.lg),
        AppButton(
          label: 'Start load test',
          icon: Icons.play_arrow_rounded,
          fullWidth: true,
          onPressed: () => _startLoad(request),
        ),
      ] else ...<Widget>[
        SectionHeader(
          label: running ? 'Running' : 'Results',
          note: running
              ? '${Fmt.elapsed(load.elapsedMs)} elapsed'
              : '${Fmt.thousands(load.completed)} requests · '
                  '${Fmt.elapsed(load.elapsedMs)}',
        ),
        const SizedBox(height: Space.row),
        Row(
          spacing: Space.row,
          children: <Widget>[
            Expanded(
              child: StatCard(
                label: running ? 'Done' : 'Throughput',
                value: running
                    ? Fmt.thousands(load.completed)
                    : Fmt.rate(load.throughput),
                unit: running
                    ? (load.total > 0 ? '/ ${Fmt.thousands(load.total)}' : '')
                    : 'req/s',
              ),
            ),
            Expanded(
              child: StatCard(
                label: running ? 'Rate' : 'P95',
                value: running
                    ? Fmt.rate(load.throughput)
                    : Fmt.thousands(load.p95Ms),
                unit: running ? 'req/s' : 'ms',
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
                label: running ? 'Avg' : 'Success',
                value: running
                    ? Fmt.thousands(load.avgMs)
                    : Fmt.thousands(load.successes),
                unit: running ? 'ms' : '',
              ),
            ),
            Expanded(
              child: StatCard(
                label: 'Errors',
                value: Fmt.thousands(load.errors),
                tint: load.errors > 0 ? c.danger : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.row),
        ChartCard(
          title: 'Latency · ms',
          note: running
              ? 'live · last ${LoadTester.liveWindow} sends'
              : '${Fmt.rate(load.throughput)} req/s',
          xLabels: const <String>[],
          series: <ChartSeries>[
            ChartSeries(
              values: <double>[
                for (final int ms in load.latencies) ms.toDouble(),
              ],
              colour: c.primary,
              strokeWidth: 2,
            ),
          ],
        ),
        if (!running) ...<Widget>[
          const SizedBox(height: Space.row),
          _LatencyBlock(load: load),
        ],
        const SizedBox(height: Space.lg),
        if (running)
          AppButton(
            label: 'Stop',
            icon: Icons.stop_rounded,
            type: AppButtonType.secondary,
            fullWidth: true,
            onPressed: _stopLoad,
          )
        else
          Row(
            spacing: Space.row,
            children: <Widget>[
              Expanded(
                child: AppButton(
                  label: 'Share',
                  icon: Icons.share_outlined,
                  type: AppButtonType.outlined,
                  fullWidth: true,
                  onPressed: () => SharePlus.instance.share(
                    ShareParams(
                      text: _loadText(request, load),
                      subject: 'Load test · ${request.displayName}',
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: AppButton(
                  label: 'Run again',
                  icon: Icons.replay_rounded,
                  fullWidth: true,
                  onPressed: () => _startLoad(request),
                ),
              ),
            ],
          ),
      ],
    ];
  }

  Future<void> _addAssertion(ApiRequest request) async {
    final Assertion? added = await showAssertionSheet(context);
    if (added == null) return;
    await _saveAssertions(
      request.copyWith(assertions: <Assertion>[...request.assertions, added]),
    );
    if (mounted) setState(() => _request = null);
  }

  Future<void> _editAssertion(ApiRequest request, Assertion assertion) async {
    final Assertion? updated = await showAssertionSheet(
      context,
      initial: assertion,
    );
    if (updated == null) return;
    await _saveAssertions(
      request.copyWith(
        assertions: <Assertion>[
          for (final Assertion a in request.assertions)
            if (a.id == assertion.id) updated else a,
        ],
      ),
    );
    if (mounted) setState(() => _request = null);
  }

  Future<void> _deleteAssertion(
    ApiRequest request,
    Assertion assertion,
  ) async {
    await _saveAssertions(
      request.copyWith(
        assertions: <Assertion>[
          for (final Assertion a in request.assertions)
            if (a.id != assertion.id) a,
        ],
      ),
    );
    if (mounted) setState(() => _request = null);
  }

  /// A shareable plain-text report, which is more use than a screenshot.
  static String _resultsText(
    ApiRequest request,
    List<AssertionResult> results,
    ApiResponse? response,
  ) {
    final StringBuffer out = StringBuffer()
      ..writeln('${request.method.label} ${request.displayName}')
      ..writeln(
        response == null
            ? ''
            : '${response.statusLabel} · ${Fmt.duration(response.durationMs)}',
      )
      ..writeln(AssertionRunner.summary(results))
      ..writeln();
    for (final AssertionResult r in results) {
      out.writeln(
        '${r.passed ? 'PASS' : 'FAIL'}  '
        '${r.assertion.target.label} '
        '${Assertion.expressionOf(r.assertion)} ${r.assertion.expected}'
        '  actual ${r.actual}',
      );
    }
    return out.toString();
  }

  static String _loadText(ApiRequest request, LoadTestResult load) =>
      '${request.method.label} ${request.displayName}\n'
      '${Fmt.thousands(load.completed)} requests in '
      '${Fmt.elapsed(load.elapsedMs)}\n'
      'throughput ${Fmt.rate(load.throughput)} req/s\n'
      'avg ${load.avgMs} ms · min ${load.minMs} ms · max ${load.maxMs} ms · '
      'P95 ${load.p95Ms} ms\n'
      'success ${load.successes} · errors ${load.errors}';
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({required this.request, required this.onTap});

  final ApiRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.md, Space.md),
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
                  Fmt.bareUrl(request.url),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.monoLabel.copyWith(
                    color: c.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.unfold_more_rounded,
            size: IconSpec.size,
            color: c.iconMuted,
          ),
        ],
      ),
    );
  }
}

/// The verdict line. It names how many passed, so colour is never the only
/// signal.
class _Summary extends StatelessWidget {
  const _Summary({required this.results, required this.response});

  final List<AssertionResult> results;
  final ApiResponse response;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final bool all = AssertionRunner.allPassed(results);
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: all ? c.successContainer : c.dangerContainer,
        borderRadius: Radii.cardR,
      ),
      child: Row(
        spacing: Space.md,
        children: <Widget>[
          Icon(
            all ? Icons.check_circle_rounded : Icons.error_rounded,
            size: IconSpec.size,
            color: all ? c.onSuccessContainer : c.onDangerContainer,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: <Widget>[
                Text(
                  AssertionRunner.summary(results),
                  style: AppType.titleMedium.copyWith(
                    color: all ? c.onSuccessContainer : c.onDangerContainer,
                  ),
                ),
                Text(
                  '${response.statusLabel} · '
                  '${Fmt.duration(response.durationMs)} · just now',
                  style: AppType.monoLabel.copyWith(
                    color: all ? c.onSuccessContainer : c.onDangerContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssertionRow extends StatelessWidget {
  const _AssertionRow({
    required this.assertion,
    required this.result,
    required this.waiting,
    required this.onEdit,
    required this.onDelete,
  });

  final Assertion assertion;
  final AssertionResult? result;
  final bool waiting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final bool failed = result != null && !result!.passed;
    final Color body = failed ? c.onDangerContainer : c.onSurface;
    return InkWell(
      // The Android click sound belongs to the system, not to a tool.
      enableFeedback: false,
      onTap: onEdit,
      child: Container(
        color: failed ? c.dangerContainer : null,
        padding: const EdgeInsets.only(left: Space.lg, right: Space.xs),
        child: Row(
          spacing: Space.sm,
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.row),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 3,
                  children: <Widget>[
                    Text(
                      assertion.target.label.toUpperCase(),
                      style: AppType.sectionHeader.copyWith(
                        color: failed
                            ? c.onDangerContainer
                            : c.onSurfaceVariant,
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        children: <InlineSpan>[
                          TextSpan(
                            text: '${Assertion.expressionOf(assertion)} ',
                          ),
                          TextSpan(
                            text: assertion.expected,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      style: AppType.monoTabular.copyWith(
                        color: body,
                        height: 1.45,
                      ),
                    ),
                    if (result != null)
                      Text(
                        _detail(result!),
                        style: AppType.monoLabel.copyWith(
                          color: failed
                              ? c.onDangerContainer
                              : c.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: IconSpec.tapTarget,
              height: IconSpec.tapTarget,
              child: Center(child: _trailing(c)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trailing(AppColors c) {
    if (waiting && result == null) {
      return Icon(
        Icons.hourglass_empty_rounded,
        size: IconSpec.size,
        color: c.iconMuted,
      );
    }
    if (result == null) {
      return IconButton(
        onPressed: onDelete,
        icon: Icon(
          Icons.more_vert_rounded,
          size: IconSpec.size,
          color: c.iconMuted,
        ),
        tooltip: 'Delete this assertion',
      );
    }
    return Icon(
      result!.passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
      size: IconSpec.size,
      color: result!.passed ? c.success : c.danger,
    );
  }

  /// A failure always prints expected against actual.
  static String _detail(AssertionResult r) {
    if (r.passed) {
      return r.note.isNotEmpty ? r.note : 'actual ${r.actual}';
    }
    final String expected = r.assertion.comparator.label == 'under'
        ? '< ${r.assertion.expected}'
        : r.assertion.expected;
    return 'expected $expected · actual ${r.actual}';
  }
}

/// Four fixed cells, avg · min · max · P95, so two runs line up.
class _LatencyBlock extends StatelessWidget {
  const _LatencyBlock({required this.load});

  final LoadTestResult load;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final List<(String, int)> cells = <(String, int)>[
      ('avg', load.avgMs),
      ('min', load.minMs),
      ('max', load.maxMs),
      ('P95', load.p95Ms),
    ];
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: Radii.thumbR,
        border: Border.all(color: c.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: <Widget>[
          for (int i = 0; i < cells.length; i++)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.md,
                  vertical: Space.row,
                ),
                decoration: BoxDecoration(
                  border: i == cells.length - 1
                      ? null
                      : Border(right: BorderSide(color: c.divider)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: <Widget>[
                    Text(
                      cells[i].$1,
                      style: AppType.monoLabel.copyWith(
                        color: c.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      Fmt.thousands(cells[i].$2),
                      style: AppType.monoTabular.copyWith(
                        color: c.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Runs the assertions saved with a request, from anywhere. Returns null when
/// the request has none.
Future<List<AssertionResult>?> runSavedAssertions(
  WidgetRef ref,
  ApiRequest request,
) async {
  if (request.assertions.isEmpty) return null;
  final ApiResponse response = await ref.read(apiClientProvider).send(
    RequestBuilder.build(request, ref.read(activeEnvironmentProvider)),
  );
  return AssertionRunner.runAll(request.assertions, response);
}

/// Exposed so the workspace can show the same status text.
String describeStatus(int status) => ApiClient.reasonFor(status);
