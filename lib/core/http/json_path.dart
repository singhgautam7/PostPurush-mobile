import 'dart:convert';

/// The subset of JSON path an assertion needs: `$.a.b`, `$.list[0].name`,
/// and bare `a.b` for a path written without the root.
///
/// A full JSON path engine would bring filters, wildcards and recursion the
/// assertion row has nowhere to show. This reads a path, which is what the
/// board asks for, and answers null when the path does not lead anywhere.
abstract final class JsonPath {
  /// Null means "no value at that path", which an assertion reports as such
  /// rather than as a failure to parse.
  static Object? read(String source, String path) {
    final Object? root = _decode(source);
    if (root == null) return null;
    return readValue(root, path);
  }

  static Object? readValue(Object? root, String path) {
    Object? current = root;
    for (final _Step step in _parse(path)) {
      if (current == null) return null;
      switch (step) {
        case _Key(:final String name):
          if (current is! Map) return null;
          if (!current.containsKey(name)) return null;
          current = current[name];
        case _Index(:final int at):
          if (current is! List || at < 0 || at >= current.length) return null;
          current = current[at];
      }
    }
    return current;
  }

  /// How an assertion prints the value it found.
  static String describe(Object? value) {
    if (value == null) return 'nothing';
    if (value is String) return value;
    return jsonEncode(value);
  }

  static Object? _decode(String source) {
    try {
      return jsonDecode(source);
    } on FormatException {
      return null;
    }
  }

  static List<_Step> _parse(String path) {
    final List<_Step> steps = <_Step>[];
    final StringBuffer name = StringBuffer();

    void flushName() {
      final String key = name.toString();
      if (key.isNotEmpty) steps.add(_Key(key));
      name.clear();
    }

    final String trimmed = path.trim();
    final String rest =
        trimmed.startsWith(r'$') ? trimmed.substring(1) : trimmed;
    for (int i = 0; i < rest.length; i++) {
      final String ch = rest[i];
      if (ch == '.') {
        flushName();
      } else if (ch == '[') {
        flushName();
        final int close = rest.indexOf(']', i);
        if (close < 0) break;
        final String inner = rest.substring(i + 1, close).trim();
        final String unquoted = inner.length >= 2 &&
                ((inner.startsWith("'") && inner.endsWith("'")) ||
                    (inner.startsWith('"') && inner.endsWith('"')))
            ? inner.substring(1, inner.length - 1)
            : inner;
        final int? index = int.tryParse(unquoted);
        steps.add(index == null ? _Key(unquoted) : _Index(index));
        i = close;
      } else {
        name.write(ch);
      }
    }
    flushName();
    return steps;
  }
}

sealed class _Step {
  const _Step();
}

class _Key extends _Step {
  const _Key(this.name);

  final String name;
}

class _Index extends _Step {
  const _Index(this.at);

  final int at;
}
