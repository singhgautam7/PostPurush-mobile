import '../models/api_request.dart';
import '../models/http_method.dart';
import '../models/key_value.dart';
import '../util/ids.dart';

/// Fills a request in from a pasted cURL command (board 2.1).
///
/// This handles what people actually copy out of a browser's network tab:
/// `-X`, `-H`, `-d`/`--data`/`--data-raw`, `-u`, `--url`, line continuations
/// and either quote style. Anything it does not understand is ignored rather
/// than guessed at, and a paste that carries no URL returns null so the
/// workspace can say so.
abstract final class CurlParser {
  static bool looksLikeCurl(String text) =>
      text.trimLeft().toLowerCase().startsWith('curl');

  static ApiRequest? parse(String text, {required String id}) {
    final List<String> tokens = _tokenise(text);
    // Without this, an ordinary sentence parses: its first word becomes the
    // URL. A paste that is not a cURL command is not a request.
    if (tokens.isEmpty || tokens.first.toLowerCase() != 'curl') return null;

    String? url;
    HttpMethod? method;
    String body = '';
    final List<KeyValueRow> headers = <KeyValueRow>[];
    AuthConfig auth = AuthConfig.none;

    for (int i = 0; i < tokens.length; i++) {
      final String token = tokens[i];
      String? next() => i + 1 < tokens.length ? tokens[++i] : null;
      switch (token) {
        case 'curl':
          continue;
        case '-X':
        case '--request':
          final String? value = next();
          if (value != null) method = HttpMethod.parse(value);
        case '-H':
        case '--header':
          final String? value = next();
          final int colon = value?.indexOf(':') ?? -1;
          if (value != null && colon > 0) {
            headers.add(
              KeyValueRow(
                id: newId(),
                key: value.substring(0, colon).trim(),
                value: value.substring(colon + 1).trim(),
              ),
            );
          }
        case '-d':
        case '--data':
        case '--data-raw':
        case '--data-binary':
        case '--data-urlencode':
          body = next() ?? body;
        case '-u':
        case '--user':
          final String? value = next();
          final int colon = value?.indexOf(':') ?? -1;
          if (value != null) {
            auth = AuthConfig(
              type: AuthType.basic,
              username: colon >= 0 ? value.substring(0, colon) : value,
              password: colon >= 0 ? value.substring(colon + 1) : '',
            );
          }
        case '--url':
          url = next();
        case '-G':
        case '--get':
          method = HttpMethod.get;
        default:
          // A bare word that looks like a URL is the URL; every other flag we
          // do not know about is dropped, along with its value if it has one.
          if (token.startsWith('-')) {
            if (_flagsWithValue.contains(token)) next();
            continue;
          }
          url ??= token;
      }
    }

    if (url == null || url.trim().isEmpty) return null;
    final String normalised = url.startsWith('http') ? url : 'https://$url';

    // A bearer token in a pasted Authorization header belongs on the auth tab,
    // where it can be swapped for a variable.
    final int bearerAt = headers.indexWhere(
      (KeyValueRow h) =>
          h.key.toLowerCase() == 'authorization' &&
          h.value.toLowerCase().startsWith('bearer '),
    );
    if (bearerAt >= 0) {
      final KeyValueRow bearer = headers.removeAt(bearerAt);
      auth = AuthConfig(
        type: AuthType.bearer,
        token: bearer.value.substring(7).trim(),
      );
    }

    final bool json = _looksLikeJson(body, headers);
    final DateTime now = DateTime.now();
    return ApiRequest(
      id: id,
      method: method ?? (body.isEmpty ? HttpMethod.get : HttpMethod.post),
      url: normalised,
      headers: headers,
      body: body,
      bodyType: body.isEmpty
          ? BodyType.none
          : json
              ? BodyType.json
              : BodyType.raw,
      auth: auth,
      params: _paramsOf(normalised),
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Flags that take a value we do not use. Skipping the value too stops it
  /// being mistaken for the URL.
  static const Set<String> _flagsWithValue = <String>{
    '-A',
    '--user-agent',
    '-b',
    '--cookie',
    '-e',
    '--referer',
    '-o',
    '--output',
    '--connect-timeout',
    '--max-time',
    '--proxy',
    '-x',
  };

  static bool _looksLikeJson(String body, List<KeyValueRow> headers) {
    if (headers.any(
      (KeyValueRow h) =>
          h.key.toLowerCase() == 'content-type' &&
          h.value.toLowerCase().contains('json'),
    )) {
      return true;
    }
    final String t = body.trimLeft();
    return t.startsWith('{') || t.startsWith('[');
  }

  static List<KeyValueRow> _paramsOf(String url) {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null || uri.queryParameters.isEmpty) return const <KeyValueRow>[];
    return <KeyValueRow>[
      for (final MapEntry<String, String> e in uri.queryParameters.entries)
        KeyValueRow(id: newId(), key: e.key, value: e.value),
    ];
  }

  /// Splits a shell-ish command into words, honouring single and double quotes
  /// and backslash line continuations.
  static List<String> _tokenise(String input) {
    final List<String> out = <String>[];
    final StringBuffer current = StringBuffer();
    String? quote;
    bool any = false;

    void flush() {
      if (any) {
        out.add(current.toString());
        current.clear();
        any = false;
      }
    }

    for (int i = 0; i < input.length; i++) {
      final String ch = input[i];
      if (quote != null) {
        if (ch == quote) {
          quote = null;
        } else if (ch == r'\' && quote == '"' && i + 1 < input.length) {
          current.write(input[++i]);
          any = true;
        } else {
          current.write(ch);
          any = true;
        }
        continue;
      }
      switch (ch) {
        case "'":
        case '"':
          quote = ch;
          any = true;
        case r'\':
          // A continuation: swallow the backslash and the newline after it.
          if (i + 1 < input.length && input[i + 1] == '\n') {
            i++;
          } else if (i + 1 < input.length) {
            current.write(input[++i]);
            any = true;
          }
        case ' ':
        case '\t':
        case '\n':
        case '\r':
          flush();
        default:
          current.write(ch);
          any = true;
      }
    }
    flush();
    return out;
  }
}
