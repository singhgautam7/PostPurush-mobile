import 'package:flutter/foundation.dart';

import '../../core/db/history_repository.dart';
import '../../core/models/folder.dart';
import '../../core/models/history_entry.dart';
import '../../core/util/format.dart';

/// One line of the breakdown: a collection, or an endpoint.
@immutable
class BreakdownRow {
  const BreakdownRow({
    required this.label,
    required this.count,
    required this.avgMs,
    required this.errorRate,
  });

  final String label;
  final int count;
  final int avgMs;
  final double errorRate;
}

/// Everything the analytics page draws, computed once per range.
///
/// Pure: it takes rows and gives numbers. No clock beyond the one passed in, no
/// database, no widgets, which is what makes the percentile and bucketing logic
/// testable without a device.
@immutable
class AnalyticsSummary {
  const AnalyticsSummary({
    required this.total,
    required this.successes,
    required this.avgMs,
    required this.bandCounts,
    required this.avgSeries,
    required this.p95Series,
    required this.bucketLabels,
    required this.byEndpoint,
    required this.byFolderId,
    required this.range,
  });

  factory AnalyticsSummary.of(
    List<HistoryStat> stats, {
    required TimeRange range,
    DateTime? now,
  }) {
    if (stats.isEmpty) {
      return AnalyticsSummary(
        total: 0,
        successes: 0,
        avgMs: 0,
        bandCounts: const <int>[0, 0, 0, 0],
        avgSeries: const <double>[],
        p95Series: const <double>[],
        bucketLabels: const <String>[],
        byEndpoint: const <BreakdownRow>[],
        byFolderId: const <String?, BreakdownRow>{},
        range: range,
      );
    }

    final DateTime reference = now ?? DateTime.now();
    int successes = 0;
    int durationSum = 0;
    final List<int> bands = <int>[0, 0, 0, 0];

    for (final HistoryStat s in stats) {
      durationSum += s.durationMs;
      if (s.status >= 200 && s.status < 300) {
        successes++;
        bands[0]++;
      } else if (s.status >= 300 && s.status < 400) {
        bands[1]++;
      } else if (s.status >= 400 && s.status < 500) {
        bands[2]++;
      } else if (s.status >= 500) {
        bands[3]++;
      }
      // A send that produced nothing counts against the success rate but sits
      // in no status band, because it has no status.
    }

    final _Buckets buckets = _Buckets.of(stats, range: range, now: reference);

    // Per endpoint: the host and path together, which is what a reader
    // recognises. Query strings are dropped, so `/users?page=1` and
    // `/users?page=2` are one endpoint.
    final Map<String, List<HistoryStat>> endpoints =
        <String, List<HistoryStat>>{};
    final Map<String?, List<HistoryStat>> folders =
        <String?, List<HistoryStat>>{};
    for (final HistoryStat s in stats) {
      final String key = '${s.host}${s.path}';
      endpoints.putIfAbsent(key, () => <HistoryStat>[]).add(s);
      folders.putIfAbsent(s.folderId, () => <HistoryStat>[]).add(s);
    }

    return AnalyticsSummary(
      total: stats.length,
      successes: successes,
      avgMs: durationSum ~/ stats.length,
      bandCounts: bands,
      avgSeries: buckets.averages,
      p95Series: buckets.p95s,
      bucketLabels: buckets.labels,
      byEndpoint: _rows(endpoints),
      byFolderId: <String?, BreakdownRow>{
        for (final MapEntry<String?, List<HistoryStat>> e in folders.entries)
          e.key: _row(e.key ?? 'No folder', e.value),
      },
      range: range,
    );
  }

  final int total;
  final int successes;
  final int avgMs;

  /// 2xx, 3xx, 4xx, 5xx.
  final List<int> bandCounts;

  final List<double> avgSeries;
  final List<double> p95Series;
  final List<String> bucketLabels;

  final List<BreakdownRow> byEndpoint;

  /// Keyed by folder id so the screen can resolve names without this file
  /// knowing about folders.
  final Map<String?, BreakdownRow> byFolderId;

  final TimeRange range;

  double get successRate => total == 0 ? 0 : successes / total;
  double get errorRate => total == 0 ? 0 : 1 - successRate;

  /// The breakdown with folder names filled in, biggest first.
  List<BreakdownRow> byCollection(List<Folder> folders) {
    final Map<String, String> names = <String, String>{
      for (final Folder f in folders) f.id: f.name,
    };
    final List<BreakdownRow> out = <BreakdownRow>[
      for (final MapEntry<String?, BreakdownRow> e in byFolderId.entries)
        BreakdownRow(
          label: e.key == null ? 'No folder' : names[e.key] ?? 'Deleted folder',
          count: e.value.count,
          avgMs: e.value.avgMs,
          errorRate: e.value.errorRate,
        ),
    ]..sort((BreakdownRow a, BreakdownRow b) => b.count.compareTo(a.count));
    return out;
  }

  static List<BreakdownRow> _rows(Map<String, List<HistoryStat>> grouped) {
    final List<BreakdownRow> out = <BreakdownRow>[
      for (final MapEntry<String, List<HistoryStat>> e in grouped.entries)
        _row(e.key, e.value),
    ]..sort((BreakdownRow a, BreakdownRow b) => b.count.compareTo(a.count));
    // Ten is as many as fits before the list stops being a summary.
    return out.take(10).toList(growable: false);
  }

  static BreakdownRow _row(String label, List<HistoryStat> rows) {
    int sum = 0;
    int errors = 0;
    for (final HistoryStat s in rows) {
      sum += s.durationMs;
      if (s.status < 200 || s.status >= 300) errors++;
    }
    return BreakdownRow(
      label: label,
      count: rows.length,
      avgMs: rows.isEmpty ? 0 : sum ~/ rows.length,
      errorRate: rows.isEmpty ? 0 : errors / rows.length,
    );
  }
}

/// The chart's x axis: seven buckets, whose width follows the range.
class _Buckets {
  const _Buckets({
    required this.averages,
    required this.p95s,
    required this.labels,
  });

  factory _Buckets.of(
    List<HistoryStat> stats, {
    required TimeRange range,
    required DateTime now,
  }) {
    // Seven buckets whatever the range, so the chart's shape is comparable
    // between ranges and the axis never crowds.
    const int count = 7;
    final Duration window = range.window ??
        (stats.isEmpty
            ? const Duration(days: 7)
            : now.difference(stats.first.sentAt));
    final Duration span = window.inMinutes <= 0
        ? const Duration(days: 7)
        : window;
    final int minutesEach = (span.inMinutes / count).ceil().clamp(1, 1 << 30);
    final DateTime start = now.subtract(span);

    final List<List<int>> samples = List<List<int>>.generate(
      count,
      (int _) => <int>[],
      growable: false,
    );
    for (final HistoryStat s in stats) {
      final int minutes = s.sentAt.difference(start).inMinutes;
      final int at = (minutes ~/ minutesEach).clamp(0, count - 1);
      samples[at].add(s.durationMs);
    }

    return _Buckets(
      averages: <double>[
        for (final List<int> bucket in samples)
          bucket.isEmpty
              ? 0
              : bucket.reduce((int a, int b) => a + b) / bucket.length,
      ],
      p95s: <double>[for (final List<int> bucket in samples) _p95(bucket)],
      labels: <String>[
        for (int i = 0; i < count; i++)
          _label(
            start.add(Duration(minutes: minutesEach * i)),
            range: range,
          ),
      ],
    );
  }

  final List<double> averages;
  final List<double> p95s;
  final List<String> labels;

  static double _p95(List<int> values) {
    if (values.isEmpty) return 0;
    final List<int> sorted = List<int>.of(values)..sort();
    final int rank = (0.95 * sorted.length).ceil().clamp(1, sorted.length);
    return sorted[rank - 1].toDouble();
  }

  /// A day name over a week, an hour over a day, a date over anything longer.
  static String _label(DateTime at, {required TimeRange range}) =>
      switch (range) {
        TimeRange.day => '${at.hour.toString().padLeft(2, '0')}h',
        TimeRange.week => Fmt.weekdayShort(at),
        _ => '${at.day}/${at.month}',
      };
}
