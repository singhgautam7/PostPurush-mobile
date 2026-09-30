import 'dart:async';

import 'package:dio/dio.dart';

import '../models/api_response.dart';
import '../models/load_test.dart';
import 'api_client.dart';
import 'request_builder.dart';

/// Runs one request many times over and reports as it goes.
///
/// Not on an isolate, deliberately. The work here is I/O bound: N sends are N
/// futures waiting on sockets, and the Dart event loop already keeps them off
/// the frame. An isolate would need its own client, its own socket pool and a
/// port for every sample, and would still be waiting on the same network. What
/// does risk a dropped frame is the reporting, so progress is throttled to
/// [reportInterval] and the aggregation is O(1) per sample: the percentile sort
/// happens once, when the run ends.
class LoadTester {
  LoadTester(this._client);

  final ApiClient _client;

  /// Ten updates a second is smooth to watch and cheap to draw.
  static const Duration reportInterval = Duration(milliseconds: 100);

  /// How many latency samples the live chart keeps. "last 10 s" on the board,
  /// which at any realistic throughput is well inside this.
  static const int liveWindow = 240;

  CancelToken? _cancelToken;
  bool _stopped = false;

  bool get running => _cancelToken != null;

  /// Emits a growing [LoadTestResult], ending with `finished: true`. The
  /// stream closes when the run stops, is cancelled, or the caller stops
  /// listening.
  Stream<LoadTestResult> run({
    required WireRequest wire,
    required LoadTestConfig config,
  }) {
    final StreamController<LoadTestResult> out =
        StreamController<LoadTestResult>();
    _stopped = false;
    final CancelToken token = _cancelToken = CancelToken();

    final Stopwatch clock = Stopwatch()..start();
    final List<int> latencies = <int>[];
    final List<int> live = <int>[];
    int completed = 0;
    int successes = 0;
    int errors = 0;
    int started = 0;

    final bool byCount = config.stop == LoadStop.iterations;
    final int target = byCount ? config.iterations : 0;
    final Duration window = Duration(seconds: config.durationSeconds);

    bool keepGoing() {
      if (_stopped || token.isCancelled) return false;
      return byCount ? started < target : clock.elapsed < window;
    }

    LoadTestResult snapshot({required bool finished}) => LoadTestResult(
      completed: completed,
      total: byCount ? target : completed,
      successes: successes,
      errors: errors,
      elapsedMs: clock.elapsedMilliseconds,
      // The live chart gets the rolling window, so the average on screen is
      // the average of the last few hundred sends. The final result gets every
      // sample, which is what the percentiles are computed from.
      latencies: finished ? List<int>.of(latencies) : List<int>.of(live),
      finished: finished,
    );

    final Timer ticker = Timer.periodic(reportInterval, (Timer _) {
      if (!out.isClosed) out.add(snapshot(finished: false));
    });

    Future<void> worker() async {
      while (keepGoing()) {
        started++;
        final ApiResponse response = await _client.send(
          wire,
          cancelToken: token,
        );
        if (response.failure == FailureKind.cancelled) return;
        completed++;
        latencies.add(response.durationMs);
        live.add(response.durationMs);
        if (live.length > liveWindow) live.removeAt(0);
        if (response.isSuccess) {
          successes++;
        } else {
          errors++;
        }
      }
    }

    Future<void>(() async {
      try {
        await Future.wait<void>(<Future<void>>[
          for (int i = 0; i < config.concurrency; i++) worker(),
        ]);
      } finally {
        clock.stop();
        ticker.cancel();
        _cancelToken = null;
        if (!out.isClosed) {
          out.add(snapshot(finished: true));
          await out.close();
        }
      }
    });

    // Losing the listener must not leave workers hammering a server.
    out.onCancel = () {
      _stopped = true;
      ticker.cancel();
      if (!token.isCancelled) token.cancel('load test listener gone');
    };

    return out.stream;
  }

  /// Stop keeps the partial results (board 11.5).
  void stop() {
    _stopped = true;
    _cancelToken?.cancel('stopped by the user');
  }
}
