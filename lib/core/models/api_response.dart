import 'dart:convert';

/// Why a send produced no response at all. A server error is not one of these:
/// a 500 is still a response and uses the ordinary sheet (board 2.5).
enum FailureKind {
  /// DNS, TLS, connection refused.
  network,
  timeout,

  /// The user pressed Cancel.
  cancelled,

  /// Anything else dio could not classify.
  unknown;

  String get title => switch (this) {
    FailureKind.network => "Couldn't reach",
    FailureKind.timeout => 'Timed out',
    FailureKind.cancelled => 'Cancelled',
    FailureKind.unknown => 'Request failed',
  };
}

/// What came back, or why nothing did. Not persisted as such: history stores
/// the parts it needs, so this type never needs a schema version.
class ApiResponse {
  const ApiResponse({
    required this.statusCode,
    required this.reasonPhrase,
    required this.headers,
    required this.body,
    required this.durationMs,
    required this.sizeBytes,
    this.failure,
    this.failureDetail = '',
  });

  /// A response that arrived, whatever its status.
  factory ApiResponse.arrived({
    required int statusCode,
    required String reasonPhrase,
    required Map<String, String> headers,
    required String body,
    required int durationMs,
    required int sizeBytes,
  }) => ApiResponse(
    statusCode: statusCode,
    reasonPhrase: reasonPhrase,
    headers: headers,
    body: body,
    durationMs: durationMs,
    sizeBytes: sizeBytes,
  );

  /// No response: the dock shows the failure and a retry.
  factory ApiResponse.failed({
    required FailureKind kind,
    required String detail,
    required int durationMs,
  }) => ApiResponse(
    statusCode: 0,
    reasonPhrase: 'No response',
    headers: const <String, String>{},
    body: '',
    durationMs: durationMs,
    sizeBytes: 0,
    failure: kind,
    failureDetail: detail,
  );

  final int statusCode;
  final String reasonPhrase;
  final Map<String, String> headers;
  final String body;
  final int durationMs;
  final int sizeBytes;

  /// Null when a response arrived.
  final FailureKind? failure;

  /// "DNS lookup failed", "change the limit in Settings".
  final String failureDetail;

  bool get arrived => failure == null;
  bool get isSuccess => arrived && statusCode >= 200 && statusCode < 300;
  bool get isRedirect => statusCode >= 300 && statusCode < 400;
  bool get isClientError => statusCode >= 400 && statusCode < 500;
  bool get isServerError => statusCode >= 500;

  /// "201 Created", or "No response".
  String get statusLabel =>
      arrived ? '$statusCode $reasonPhrase' : 'No response';

  /// Cookies parsed out of set-cookie, for the response sheet's third tab.
  List<String> get cookies {
    final String? raw = headers['set-cookie'];
    if (raw == null || raw.isEmpty) return const <String>[];
    return raw.split('\n').where((String s) => s.trim().isNotEmpty).toList();
  }

  /// Whether the body parses as JSON, which decides Pretty versus Preview.
  bool get isJson {
    final String type = headers['content-type'] ?? '';
    if (type.contains('json')) return true;
    final String t = body.trimLeft();
    return t.startsWith('{') || t.startsWith('[');
  }

  /// The body re-indented, or the body unchanged when it is not JSON.
  String get pretty {
    if (!isJson) return body;
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(body));
    } on FormatException {
      return body;
    }
  }
}
