import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../models/api_response.dart';
import 'request_builder.dart';

/// Settings that change what goes on the wire, from the Settings screen.
class SendOptions {
  const SendOptions({
    this.timeout = const Duration(seconds: 30),
    this.followRedirects = true,
    this.verifySsl = true,
    this.defaultHeaders = const <String, String>{},
  });

  final Duration timeout;
  final bool followRedirects;

  /// Off for a self-signed local server, and that is the only reason to.
  final bool verifySsl;

  /// Added to every request, unless the request sets the same name itself.
  final Map<String, String> defaultHeaders;
}

/// The send engine.
///
/// PostPurush's HTTP client is the product, so this is the one place that
/// touches the network. Nothing here reports, phones home or retries on its
/// own: one send per [send] call, and the caller can cancel it.
class ApiClient {
  ApiClient({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options
      ..followRedirects = true
      ..responseType = ResponseType.bytes
      // A 500 is a response, not an error: the sheet shows it like any other.
      ..validateStatus = (int? _) => true;
  }

  final Dio _dio;

  /// Applied lazily so a Settings change takes effect on the next send without
  /// rebuilding the client or dropping a keep-alive connection.
  SendOptions _options = const SendOptions();

  void configure(SendOptions options) {
    final bool sslChanged = _options.verifySsl != options.verifySsl;
    _options = options;
    _dio.options
      ..connectTimeout = options.timeout
      ..sendTimeout = options.timeout
      ..receiveTimeout = options.timeout
      ..followRedirects = options.followRedirects
      ..maxRedirects = options.followRedirects ? 5 : 1;
    if (sslChanged) _applySsl(verify: options.verifySsl);
  }

  void _applySsl({required bool verify}) {
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final HttpClient client = HttpClient();
        if (!verify) {
          // Only reachable through the Settings switch, which says in so many
          // words that it is for self-signed local servers.
          client.badCertificateCallback =
              (X509Certificate _, String _, int _) => true;
        }
        return client;
      },
    );
  }

  /// Sends [wire] and always answers with an [ApiResponse]: a status, or a
  /// named failure. It never throws, so no caller has to guard a send.
  Future<ApiResponse> send(
    WireRequest wire, {
    CancelToken? cancelToken,
  }) async {
    final Stopwatch clock = Stopwatch()..start();
    try {
      final Map<String, String> headers = <String, String>{
        ..._options.defaultHeaders,
        ...wire.headers,
      };
      if (wire.contentType != null &&
          !headers.keys.any(
            (String k) => k.toLowerCase() == 'content-type',
          )) {
        headers['Content-Type'] = wire.contentType!;
      }

      final Response<List<int>> response = await _dio.request<List<int>>(
        wire.url,
        data: wire.body,
        cancelToken: cancelToken,
        options: Options(
          method: wire.method.label,
          headers: headers,
          responseType: ResponseType.bytes,
          followRedirects: _options.followRedirects,
        ),
      );
      clock.stop();

      final List<int> bytes = response.data ?? const <int>[];
      return ApiResponse.arrived(
        statusCode: response.statusCode ?? 0,
        reasonPhrase: _reason(response),
        headers: _flatten(response.headers),
        body: _decodeBody(bytes),
        durationMs: clock.elapsedMilliseconds,
        sizeBytes: bytes.length,
      );
    } on DioException catch (error) {
      clock.stop();
      return ApiResponse.failed(
        kind: _kindOf(error),
        detail: _detailOf(error),
        durationMs: clock.elapsedMilliseconds,
      );
    } catch (error) {
      clock.stop();
      return ApiResponse.failed(
        kind: FailureKind.unknown,
        detail: error.toString(),
        durationMs: clock.elapsedMilliseconds,
      );
    }
  }

  /// A body that is not valid UTF-8 is still worth showing, so it falls back
  /// to a lossy decode rather than failing the whole send.
  static String _decodeBody(List<int> bytes) {
    if (bytes.isEmpty) return '';
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return utf8.decode(bytes, allowMalformed: true);
    }
  }

  static String _reason(Response<Object?> response) {
    final String? phrase = response.statusMessage;
    if (phrase != null && phrase.trim().isNotEmpty) return phrase.trim();
    return reasonFor(response.statusCode ?? 0);
  }

  static Map<String, String> _flatten(Headers headers) {
    final Map<String, String> out = <String, String>{};
    headers.forEach((String name, List<String> values) {
      out[name.toLowerCase()] = values.join('\n');
    });
    return out;
  }

  static FailureKind _kindOf(DioException error) => switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => FailureKind.timeout,
    DioExceptionType.cancel => FailureKind.cancelled,
    DioExceptionType.connectionError ||
    DioExceptionType.badCertificate => FailureKind.network,
    _ => FailureKind.unknown,
  };

  static String _detailOf(DioException error) {
    final Object? cause = error.error;
    if (cause is SocketException) {
      return cause.osError?.message.isNotEmpty ?? false
          ? cause.osError!.message
          : 'DNS lookup failed';
    }
    if (cause is HandshakeException) return 'TLS handshake failed';
    return switch (error.type) {
      DioExceptionType.connectionTimeout => 'Could not connect in time',
      DioExceptionType.sendTimeout => 'Sending took too long',
      DioExceptionType.receiveTimeout => 'change the limit in Settings',
      DioExceptionType.badCertificate =>
        'Certificate rejected. Turn off SSL verification for a local server',
      DioExceptionType.cancel => 'Cancelled',
      _ => error.message ?? 'Request failed',
    };
  }

  void close() => _dio.close(force: true);

  /// The reason phrase for a status, so a chip is never a bare number
  /// (board 13, "Status chips").
  static String reasonFor(int status) => switch (status) {
    0 => 'No response',
    200 => 'OK',
    201 => 'Created',
    202 => 'Accepted',
    204 => 'No Content',
    301 => 'Moved Permanently',
    302 => 'Found',
    304 => 'Not Modified',
    307 => 'Temporary Redirect',
    308 => 'Permanent Redirect',
    400 => 'Bad Request',
    401 => 'Unauthorized',
    403 => 'Forbidden',
    404 => 'Not Found',
    405 => 'Method Not Allowed',
    409 => 'Conflict',
    410 => 'Gone',
    415 => 'Unsupported Media Type',
    418 => "I'm a Teapot",
    422 => 'Unprocessable Content',
    429 => 'Too Many Requests',
    500 => 'Server Error',
    501 => 'Not Implemented',
    502 => 'Bad Gateway',
    503 => 'Service Unavailable',
    504 => 'Gateway Timeout',
    _ => _band(status),
  };

  static String _band(int status) {
    if (status >= 200 && status < 300) return 'Success';
    if (status >= 300 && status < 400) return 'Redirect';
    if (status >= 400 && status < 500) return 'Client Error';
    if (status >= 500) return 'Server Error';
    return 'Unknown';
  }
}
