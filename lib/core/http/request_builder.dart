import 'dart:convert';

import '../models/api_request.dart';
import '../models/environment.dart';
import '../models/http_method.dart';
import '../models/key_value.dart';
import 'variable_resolver.dart';

/// A request with every `{{variable}}` filled in, ready for the wire or for a
/// code snippet. Built at send time and thrown away afterwards.
class WireRequest {
  const WireRequest({
    required this.method,
    required this.url,
    required this.headers,
    required this.body,
    required this.contentType,
    required this.secretHeaderNames,
    required this.missing,
  });

  final HttpMethod method;

  /// Absolute, with the query already folded in.
  final String url;
  final Map<String, String> headers;

  /// Null when there is nothing to send.
  final String? body;

  /// Null when the body decides its own, or there is no body.
  final String? contentType;

  /// Headers whose value came from a secret variable, so a code export knows
  /// what to mask without re-resolving anything.
  final Set<String> secretHeaderNames;

  /// Variables the active environment could not fill in. The request is still
  /// built: the braces go out as typed and the server's answer is the truth.
  final List<String> missing;

  Uri get uri => Uri.parse(url);
}

/// Composes a [WireRequest] out of a saved request and the active environment.
abstract final class RequestBuilder {
  /// [maskSecrets] replaces secret values with dots, for the code-export sheet
  /// and the PDF. The wire never uses it.
  static WireRequest build(
    ApiRequest request,
    Environment? env, {
    bool maskSecrets = false,
  }) {
    String fill(String input) {
      final String resolved = VariableResolver.resolve(input, env);
      if (!maskSecrets || env == null) return resolved;
      // Re-walk the template so only the spans that were secret get masked,
      // and an ordinary value that happens to look like one does not.
      String out = input;
      for (final VariableSpan span in VariableResolver.scan(input, env)) {
        if (!span.resolved) continue;
        out = out.replaceAll(
          '{{${span.name}}}',
          span.secret ? VariableResolver.mask(span.value!) : span.value!,
        );
      }
      return out;
    }

    final String rawUrl = fill(request.url).trim();
    final String url = _withQuery(rawUrl, request.params, fill);

    final Map<String, String> headers = <String, String>{};
    final Set<String> secretHeaders = <String>{};
    for (final KeyValueRow h in request.headers.active) {
      final String name = fill(h.key).trim();
      headers[name] = fill(h.value);
      if (_touchesSecret(h.value, env)) secretHeaders.add(name);
    }

    final _Payload payload = _body(request, fill);

    // Auth last, so an explicit header the user typed is not silently
    // overwritten by a half-filled auth tab.
    // An API key that rides in the query joins the URL instead; see below.
    _applyAuth(request.auth, fill, headers, secretHeaders, env);
    final String finalUrl = _authQuery(url, request.auth, fill);

    return WireRequest(
      method: request.method,
      url: finalUrl,
      headers: headers,
      body: payload.body,
      contentType: payload.contentType,
      secretHeaderNames: secretHeaders,
      missing: VariableResolver.missingAcross(templateStrings(request), env),
    );
  }

  /// Every string in a request that can carry a variable. One list, so the
  /// missing-variable count on the switcher and the banner in the URL bar can
  /// never disagree about what was checked.
  static List<String> templateStrings(ApiRequest r) => <String>[
    r.url,
    for (final KeyValueRow p in r.params.active) ...<String>[p.key, p.value],
    for (final KeyValueRow h in r.headers.active) ...<String>[h.key, h.value],
    if (r.bodyType == BodyType.form)
      for (final KeyValueRow f in r.formFields.active) ...<String>[f.key, f.value]
    else
      r.body,
    r.auth.token,
    r.auth.username,
    r.auth.password,
    r.auth.keyValue,
  ];

  static bool _touchesSecret(String template, Environment? env) =>
      VariableResolver.scan(template, env).any((VariableSpan s) => s.secret);

  /// Params typed in the tab are merged into whatever the URL already carries.
  /// The URL wins on a duplicate key, because that is what the user can see.
  static String _withQuery(
    String url,
    List<KeyValueRow> params,
    String Function(String) fill,
  ) {
    final Iterable<KeyValueRow> rows = params.active;
    if (rows.isEmpty) return url;
    final Uri? parsed = Uri.tryParse(url);
    if (parsed == null) return url;
    final Map<String, String> query = Map<String, String>.of(
      parsed.queryParameters,
    );
    for (final KeyValueRow p in rows) {
      query.putIfAbsent(fill(p.key).trim(), () => fill(p.value));
    }
    return parsed.replace(queryParameters: query).toString();
  }

  static _Payload _body(ApiRequest r, String Function(String) fill) {
    if (!r.method.sendsBody) return const _Payload(null, null);
    return switch (r.bodyType) {
      BodyType.none => const _Payload(null, null),
      BodyType.json => _Payload(
        fill(r.body).trim().isEmpty ? null : fill(r.body),
        'application/json',
      ),
      BodyType.raw => _Payload(
        fill(r.body).isEmpty ? null : fill(r.body),
        'text/plain',
      ),
      BodyType.form => _Payload(
        r.formFields.active.isEmpty
            ? null
            : r.formFields.active
                  .map(
                    (KeyValueRow f) =>
                        '${Uri.encodeQueryComponent(fill(f.key))}='
                        '${Uri.encodeQueryComponent(fill(f.value))}',
                  )
                  .join('&'),
        'application/x-www-form-urlencoded',
      ),
    };
  }

  static void _applyAuth(
    AuthConfig auth,
    String Function(String) fill,
    Map<String, String> headers,
    Set<String> secretHeaders,
    Environment? env,
  ) {
    switch (auth.type) {
      case AuthType.none:
        return;
      case AuthType.bearer:
        if (auth.token.isEmpty) return;
        headers.putIfAbsent('Authorization', () => 'Bearer ${fill(auth.token)}');
        if (_touchesSecret(auth.token, env)) secretHeaders.add('Authorization');
      case AuthType.basic:
        if (auth.username.isEmpty && auth.password.isEmpty) return;
        final String pair =
            '${fill(auth.username)}:${fill(auth.password)}';
        headers.putIfAbsent(
          'Authorization',
          () => 'Basic ${base64Encode(utf8.encode(pair))}',
        );
        secretHeaders.add('Authorization');
      case AuthType.apiKey:
        if (auth.keyName.isEmpty) return;
        if (auth.keyIn == ApiKeyLocation.header) {
          final String name = fill(auth.keyName);
          headers.putIfAbsent(name, () => fill(auth.keyValue));
          if (_touchesSecret(auth.keyValue, env)) secretHeaders.add(name);
        }
    }
  }

  static String _authQuery(
    String url,
    AuthConfig auth,
    String Function(String) fill,
  ) {
    if (auth.type != AuthType.apiKey ||
        auth.keyIn != ApiKeyLocation.query ||
        auth.keyName.isEmpty) {
      return url;
    }
    final Uri? parsed = Uri.tryParse(url);
    if (parsed == null) return url;
    return parsed
        .replace(
          queryParameters: <String, String>{
            ...parsed.queryParameters,
            fill(auth.keyName): fill(auth.keyValue),
          },
        )
        .toString();
  }

  /// Whether a URL can be sent. Send and Save stay disabled until this is true
  /// (board 2.1). A URL with an unresolved variable in the host still counts:
  /// the template is well formed, and the environment is the user's problem.
  static bool isSendable(String url) {
    final String trimmed = url.trim();
    if (trimmed.isEmpty) return false;
    final String probe = trimmed.replaceAll(VariableResolver.pattern, 'x');
    final Uri? uri = Uri.tryParse(probe);
    if (uri == null) return false;
    if (!uri.hasScheme) return false;
    if (uri.scheme != 'http' && uri.scheme != 'https') return false;
    return uri.host.isNotEmpty;
  }

  /// The inline error the board shows for a URL that will not parse.
  static String? urlError(String url) {
    if (url.trim().isEmpty) return null;
    if (isSendable(url)) return null;
    return 'Not a valid URL. Add http:// or https://';
  }
}

class _Payload {
  const _Payload(this.body, this.contentType);

  final String? body;
  final String? contentType;
}
