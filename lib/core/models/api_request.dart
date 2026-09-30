import 'package:freezed_annotation/freezed_annotation.dart';

import 'http_method.dart';
import 'key_value.dart';

part 'api_request.freezed.dart';
part 'api_request.g.dart';

/// The auth tab. Whatever is chosen here is folded into the headers or the
/// query at send time, never stored resolved.
@freezed
abstract class AuthConfig with _$AuthConfig {
  const factory AuthConfig({
    @Default(AuthType.none) AuthType type,

    /// Bearer.
    @Default('') String token,

    /// Basic.
    @Default('') String username,
    @Default('') String password,

    /// API key.
    @Default('') String keyName,
    @Default('') String keyValue,
    @Default(ApiKeyLocation.header) ApiKeyLocation keyIn,
  }) = _AuthConfig;

  factory AuthConfig.fromJson(Map<String, dynamic> json) =>
      _$AuthConfigFromJson(json);

  static const AuthConfig none = AuthConfig();
}

/// What an assertion looks at.
enum AssertTarget {
  status('Status'),
  responseTime('Response time'),
  header('Header'),
  body('Body'),
  jsonPath('JSON path');

  const AssertTarget(this.label);

  final String label;

  /// Whether the assertion needs a subject (a header name, a JSON path).
  bool get hasSubject => this == header || this == jsonPath;
}

/// How the actual is compared against the expected.
enum AssertComparator {
  equals('equals'),
  notEquals('does not equal'),
  contains('contains'),
  notContains('does not contain'),
  under('under'),
  over('over'),
  exists('exists');

  const AssertComparator(this.label);

  final String label;
}

/// One line of "what must be true" (board 11.1). Assertions are saved with the
/// request, so they run from Testing and from the workspace alike.
@freezed
abstract class Assertion with _$Assertion {
  const factory Assertion({
    required String id,
    @Default(AssertTarget.status) AssertTarget target,
    @Default(AssertComparator.equals) AssertComparator comparator,

    /// The header name, or the JSON path. Empty for the other targets.
    @Default('') String subject,
    @Default('') String expected,
  }) = _Assertion;

  factory Assertion.fromJson(Map<String, dynamic> json) =>
      _$AssertionFromJson(json);

  /// "Content-Type contains" · "$.userId equals" · "equals".
  static String expressionOf(Assertion a) => <String>[
    if (a.subject.isNotEmpty) a.subject,
    a.comparator.label,
  ].join(' ');
}

/// A request as the user composed it. `{{variable}}` placeholders are stored
/// exactly as typed; resolution happens at send time and never comes back here.
@freezed
abstract class ApiRequest with _$ApiRequest {
  const factory ApiRequest({
    required String id,
    @Default('') String name,
    @Default('') String description,
    @Default(HttpMethod.get) HttpMethod method,
    @Default('') String url,
    @Default(<KeyValueRow>[]) List<KeyValueRow> params,
    @Default(<KeyValueRow>[]) List<KeyValueRow> headers,
    @Default(<KeyValueRow>[]) List<KeyValueRow> formFields,
    @Default('') String body,
    @Default(BodyType.none) BodyType bodyType,
    @Default(AuthConfig()) AuthConfig auth,
    @Default(<Assertion>[]) List<Assertion> assertions,

    /// Null means the top level of Collections.
    String? folderId,
    required DateTime createdAt,
    required DateTime updatedAt,

    /// Order within its folder.
    @Default(0) int order,

    /// Bumped whenever this shape changes. On read, an unknown version is
    /// migrated or discarded; it never crashes the app.
    @Default(1) int schemaVersion,
  }) = _ApiRequest;

  factory ApiRequest.fromJson(Map<String, dynamic> json) =>
      _$ApiRequestFromJson(json);

  /// The current shape of a persisted request.
  /// The current shape. Keep this and the `@Default` above in step: the
  /// generated code copies that annotation verbatim, where a static on this
  /// class is not in scope, so the literal cannot be replaced by the constant.
  static const int schema = 1;

  /// A blank unsaved request, ready for the workspace.
  static ApiRequest blank(String id) {
    final DateTime now = DateTime.now();
    return ApiRequest(id: id, createdAt: now, updatedAt: now);
  }
}

extension ApiRequestX on ApiRequest {
  /// What the title line shows before the request has a name.
  String get displayName => name.trim().isEmpty ? 'Untitled request' : name;

  /// The host, for the dock's subtitle. Empty while the URL does not parse.
  String get host => Uri.tryParse(url)?.host ?? '';

  /// Everything a send needs, minus the variables. Used to tell an edited
  /// request from a saved one without comparing timestamps.
  bool sameWireAs(ApiRequest other) =>
      method == other.method &&
      url == other.url &&
      body == other.body &&
      bodyType == other.bodyType &&
      auth == other.auth &&
      _sameRows(params, other.params) &&
      _sameRows(headers, other.headers) &&
      _sameRows(formFields, other.formFields);

  /// Everything a user could have edited. Used to decide whether the Save
  /// icon carries its unsaved dot.
  bool sameAs(ApiRequest other) =>
      sameWireAs(other) &&
      name == other.name &&
      description == other.description &&
      folderId == other.folderId &&
      _sameAssertions(assertions, other.assertions);

  static bool _sameAssertions(List<Assertion> a, List<Assertion> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _sameRows(List<KeyValueRow> a, List<KeyValueRow> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
