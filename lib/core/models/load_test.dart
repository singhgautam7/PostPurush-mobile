import 'package:freezed_annotation/freezed_annotation.dart';

part 'load_test.freezed.dart';
part 'load_test.g.dart';

/// Whether a load test stops after a count or after a clock (board 11.4).
enum LoadStop {
  iterations('Iterations'),
  duration('Duration');

  const LoadStop(this.label);

  final String label;
}

/// The setup block. The steppers keep every value inside these bounds without
/// a keyboard, so there is nothing to validate on submit.
@freezed
abstract class LoadTestConfig with _$LoadTestConfig {
  const factory LoadTestConfig({
    @Default(10) int concurrency,
    @Default(LoadStop.iterations) LoadStop stop,
    @Default(500) int iterations,
    @Default(30) int durationSeconds,
  }) = _LoadTestConfig;

  factory LoadTestConfig.fromJson(Map<String, dynamic> json) =>
      _$LoadTestConfigFromJson(json);

  static const int minConcurrency = 1;
  static const int maxConcurrency = 64;
  static const int minIterations = 10;
  static const int maxIterations = 10000;
  static const int minDuration = 5;
  static const int maxDuration = 600;
}

/// A finished, or in-flight, load test. Percentiles are computed from the
/// latency samples; the samples themselves are kept only for the chart and are
/// never persisted.
@freezed
abstract class LoadTestResult with _$LoadTestResult {
  const factory LoadTestResult({
    @Default(0) int completed,
    @Default(0) int total,
    @Default(0) int successes,
    @Default(0) int errors,
    @Default(0) int elapsedMs,
    @Default(<int>[]) List<int> latencies,
    @Default(false) bool finished,
  }) = _LoadTestResult;

  factory LoadTestResult.fromJson(Map<String, dynamic> json) =>
      _$LoadTestResultFromJson(json);
}

extension LoadTestResultX on LoadTestResult {
  /// Requests per second over the whole run.
  double get throughput =>
      elapsedMs <= 0 ? 0 : completed * 1000 / elapsedMs;

  int get avgMs => latencies.isEmpty
      ? 0
      : latencies.reduce((int a, int b) => a + b) ~/ latencies.length;

  int get minMs =>
      latencies.isEmpty ? 0 : latencies.reduce((int a, int b) => a < b ? a : b);

  int get maxMs =>
      latencies.isEmpty ? 0 : latencies.reduce((int a, int b) => a > b ? a : b);

  int get p95Ms => percentile(95);

  /// Nearest-rank percentile over a sorted copy, which is what every load
  /// tool reports and what makes two runs comparable.
  int percentile(int p) {
    if (latencies.isEmpty) return 0;
    final List<int> sorted = List<int>.of(latencies)..sort();
    final int rank = ((p / 100) * sorted.length).ceil().clamp(
      1,
      sorted.length,
    );
    return sorted[rank - 1];
  }
}
