import '../models/environment.dart';
import '../models/http_method.dart';
import '../models/key_value.dart';

/// One `{{name}}` found in a string, and what it resolved to.
class VariableSpan {
  const VariableSpan({
    required this.start,
    required this.end,
    required this.name,
    required this.value,
    required this.secret,
  });

  /// Offsets of the whole `{{name}}`, braces included.
  final int start;
  final int end;
  final String name;

  /// Null when the active environment does not carry it.
  final String? value;

  /// True when the variable is marked secret, so a preview must mask it.
  final bool secret;

  bool get resolved => value != null;
}

/// Turns `{{variable}}` into values, and says which ones are missing.
///
/// Resolution happens at send time and nowhere else. A resolved string is
/// never written back to a request, to history or to a code export without the
/// user asking, which is the one rule that keeps a token out of the database.
abstract final class VariableResolver {
  /// `{{ name }}` with any surrounding space, and a name of word characters,
  /// dots and dashes. Anything else is left alone: a literal `{{` in a body is
  /// not a variable.
  static final RegExp pattern = RegExp(r'\{\{\s*([A-Za-z0-9_.\-]+)\s*\}\}');

  /// Every placeholder in [input], in order, against [env]. A null environment
  /// resolves nothing, which is what "No environment" means.
  static List<VariableSpan> scan(String input, Environment? env) {
    final List<VariableSpan> spans = <VariableSpan>[];
    for (final RegExpMatch m in pattern.allMatches(input)) {
      final String name = m.group(1)!;
      spans.add(
        VariableSpan(
          start: m.start,
          end: m.end,
          name: name,
          value: env?.lookup(name),
          secret: env?.isSecret(name) ?? false,
        ),
      );
    }
    return spans;
  }

  /// The names [input] refers to, deduplicated, in order of first appearance.
  static List<String> namesIn(String input) {
    final Set<String> seen = <String>{};
    for (final RegExpMatch m in pattern.allMatches(input)) {
      seen.add(m.group(1)!);
    }
    return seen.toList(growable: false);
  }

  /// Substitutes what [env] carries and leaves the rest as typed.
  ///
  /// Leaving a missing variable in place is deliberate: the request still goes
  /// out, the server sees the literal braces, and the error it returns tells
  /// the truth about what was sent. Silently dropping it would not.
  static String resolve(String input, Environment? env) {
    if (env == null || !input.contains('{{')) return input;
    return input.replaceAllMapped(pattern, (Match m) {
      final String name = m.group(1)!;
      return env.lookup(name) ?? m.group(0)!;
    });
  }

  /// The names [input] refers to that [env] cannot fill in.
  static List<String> missingIn(String input, Environment? env) {
    final List<String> missing = <String>[];
    for (final String name in namesIn(input)) {
      if (env?.lookup(name) == null) missing.add(name);
    }
    return missing;
  }

  /// Across a whole request: url, params, headers, form fields, body and auth.
  static List<String> missingAcross(Iterable<String> inputs, Environment? env) {
    final Set<String> missing = <String>{};
    for (final String input in inputs) {
      missing.addAll(missingIn(input, env));
    }
    return missing.toList(growable: false);
  }

  /// How many of [names] an environment resolves, for the switcher's
  /// "2 / 2 resolved" line (board 2.7).
  static int resolvedCount(List<String> names, Environment? env) =>
      names.where((String n) => env?.lookup(n) != null).length;

  /// What the autocomplete inserts. A string variable lands inside quotes in a
  /// JSON body, because that is where it has to be valid; a number, boolean or
  /// JSON value lands bare (board 4.6).
  static String insertion(KeyValueRow variable, {required bool intoJsonBody}) {
    final String ref = '{{${variable.key}}}';
    final bool quote = intoJsonBody && variable.type == VarType.string;
    return quote ? '"$ref"' : ref;
  }

  /// Masks a secret for a preview or a code export.
  static String mask(String value) => '•' * value.length.clamp(6, 12);
}
