import 'package:freezed_annotation/freezed_annotation.dart';

import 'api_request.dart';
import 'api_response.dart';
import 'http_method.dart';

part 'history_entry.freezed.dart';
part 'history_entry.g.dart';

/// One send, kept so it can be reopened exactly as it was (board 5.1).
///
/// The snapshot holds the request as it was composed, with `{{variable}}`
/// placeholders intact. Resolved values are never written here: history must
/// not become a place where a secret ends up on disk.
@freezed
abstract class HistoryEntry with _$HistoryEntry {
  const factory HistoryEntry({
    required String id,
    required ApiRequest requestSnapshot,

    /// 0 when nothing came back.
    @Default(0) int status,
    @Default('') String reasonPhrase,
    @Default(0) int durationMs,
    @Default(0) int sizeBytes,
    required DateTime sentAt,

    /// Denormalised so the list and the analytics queries never have to decode
    /// the snapshot to draw a row or group by host.
    @Default(HttpMethod.get) HttpMethod method,
    @Default('') String host,
    @Default('') String path,
    @Default('') String name,
    String? folderId,

    /// Set when there was no response at all.
    FailureKind? failure,

    /// The response body, so a reopened entry shows what came back. Bodies
    /// past [maxStoredBody] are dropped rather than growing the database.
    @Default('') String body,
    @Default(<String, String>{}) Map<String, String> headers,
    @Default(1) int schemaVersion,
  }) = _HistoryEntry;

  factory HistoryEntry.fromJson(Map<String, dynamic> json) =>
      _$HistoryEntryFromJson(json);

  /// The current shape. Keep this and the `@Default` above in step: the
  /// generated code copies that annotation verbatim, where a static on this
  /// class is not in scope, so the literal cannot be replaced by the constant.
  static const int schema = 1;

  /// A response body larger than this is not kept. Reopening such an entry
  /// still restores the request; only the old body is gone.
  static const int maxStoredBody = 256 * 1024;

  static HistoryEntry from({
    required String id,
    required ApiRequest request,
    required ApiResponse response,
    required DateTime sentAt,
  }) {
    final Uri? uri = Uri.tryParse(request.url);
    return HistoryEntry(
      id: id,
      requestSnapshot: request,
      status: response.statusCode,
      reasonPhrase: response.reasonPhrase,
      durationMs: response.durationMs,
      sizeBytes: response.sizeBytes,
      sentAt: sentAt,
      method: request.method,
      host: uri?.host ?? '',
      path: uri?.path ?? request.url,
      name: request.name,
      folderId: request.folderId,
      failure: response.failure,
      body: response.body.length > maxStoredBody ? '' : response.body,
      headers: response.headers,
    );
  }
}

/// The status bands the history filter and the analytics chart both use.
enum StatusBand {
  all('All'),
  s2xx('2xx'),
  s3xx('3xx'),
  s4xx('4xx'),
  s5xx('5xx');

  const StatusBand(this.label);

  final String label;

  bool matches(int status) => switch (this) {
    StatusBand.all => true,
    StatusBand.s2xx => status >= 200 && status < 300,
    StatusBand.s3xx => status >= 300 && status < 400,
    StatusBand.s4xx => status >= 400 && status < 500,
    StatusBand.s5xx => status >= 500,
  };

  /// The band a status falls in, or [all] when nothing came back.
  static StatusBand of(int status) {
    if (status >= 200 && status < 300) return StatusBand.s2xx;
    if (status >= 300 && status < 400) return StatusBand.s3xx;
    if (status >= 400 && status < 500) return StatusBand.s4xx;
    if (status >= 500) return StatusBand.s5xx;
    return StatusBand.all;
  }
}

/// The analytics range control (board 10.1). Also the history retention unit.
enum TimeRange {
  day('24h', Duration(hours: 24)),
  week('7d', Duration(days: 7)),
  month('30d', Duration(days: 30)),
  all('All', null);

  const TimeRange(this.label, this.window);

  final String label;

  /// Null means every entry.
  final Duration? window;

  DateTime? since(DateTime now) => window == null ? null : now.subtract(window!);
}
