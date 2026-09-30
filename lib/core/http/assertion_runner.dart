import 'dart:convert';

import '../models/api_request.dart';
import '../models/api_response.dart';
import '../util/format.dart';
import 'json_path.dart';

/// One assertion's verdict. A failure always prints expected against actual,
/// so colour is never the only signal (board 11.3).
class AssertionResult {
  const AssertionResult({
    required this.assertion,
    required this.passed,
    required this.actual,
    this.note = '',
  });

  final Assertion assertion;
  final bool passed;

  /// "201", "1,391 ms", "application/json; charset=utf-8", "nothing".
  final String actual;

  /// "found at $.title" on a pass, or why it could not be checked.
  final String note;
}

/// Evaluates assertions against one response.
///
/// Pure: no clock, no network, no storage. That is what makes it testable, and
/// what lets the same code run from Testing and from the workspace.
abstract final class AssertionRunner {
  static List<AssertionResult> runAll(
    List<Assertion> assertions,
    ApiResponse response,
  ) => <AssertionResult>[
    for (final Assertion a in assertions) run(a, response),
  ];

  static AssertionResult run(Assertion a, ApiResponse response) {
    return switch (a.target) {
      AssertTarget.status => _compare(
        a,
        actual: '${response.statusCode}',
        numericActual: response.statusCode.toDouble(),
      ),
      AssertTarget.responseTime => _compare(
        a,
        actual: Fmt.duration(response.durationMs),
        numericActual: response.durationMs.toDouble(),
      ),
      AssertTarget.header => _header(a, response),
      AssertTarget.body => _body(a, response),
      AssertTarget.jsonPath => _jsonPath(a, response),
    };
  }

  static AssertionResult _header(Assertion a, ApiResponse response) {
    final String name = a.subject.trim().toLowerCase();
    final String? value = response.headers[name];
    if (value == null) {
      return AssertionResult(
        assertion: a,
        passed: a.comparator == AssertComparator.notContains ||
            a.comparator == AssertComparator.notEquals,
        actual: 'nothing',
        note: 'no $name header',
      );
    }
    if (a.comparator == AssertComparator.exists) {
      return AssertionResult(assertion: a, passed: true, actual: value);
    }
    return _compare(a, actual: value, numericActual: double.tryParse(value));
  }

  static AssertionResult _body(Assertion a, ApiResponse response) {
    final bool found = response.body.contains(a.expected);
    final bool passed = switch (a.comparator) {
      AssertComparator.contains => found,
      AssertComparator.notContains => !found,
      AssertComparator.equals => response.body.trim() == a.expected.trim(),
      AssertComparator.notEquals => response.body.trim() != a.expected.trim(),
      AssertComparator.exists => response.body.isNotEmpty,
      _ => false,
    };
    return AssertionResult(
      assertion: a,
      passed: passed,
      actual: found ? 'found' : 'not found',
      note: passed && found ? _whereIn(response.body, a.expected) : '',
    );
  }

  /// "found at $.title", which is more use than "found".
  static String _whereIn(String body, String needle) {
    try {
      final Object? root = jsonDecode(body);
      final String? path = _search(root, needle, r'$');
      return path == null ? '' : 'found at $path';
    } on FormatException {
      return '';
    }
  }

  /// A bounded walk: deep enough for an ordinary response, shallow enough that
  /// a pathological one cannot stall the results screen.
  static String? _search(Object? node, String needle, String path, [int depth = 0]) {
    if (depth > 8) return null;
    if (node is Map) {
      for (final Object? key in node.keys) {
        final String child = '$path.$key';
        final Object? value = node[key];
        if (value is String && value.contains(needle)) return child;
        final String? found = _search(value, needle, child, depth + 1);
        if (found != null) return found;
      }
    } else if (node is List) {
      for (int i = 0; i < node.length && i < 50; i++) {
        final String child = '$path[$i]';
        final Object? value = node[i];
        if (value is String && value.contains(needle)) return child;
        final String? found = _search(value, needle, child, depth + 1);
        if (found != null) return found;
      }
    }
    return null;
  }

  static AssertionResult _jsonPath(Assertion a, ApiResponse response) {
    final Object? value = JsonPath.read(response.body, a.subject);
    final String actual = JsonPath.describe(value);
    if (a.comparator == AssertComparator.exists) {
      return AssertionResult(
        assertion: a,
        passed: value != null,
        actual: actual,
      );
    }
    return _compare(
      a,
      actual: actual,
      numericActual: value is num ? value.toDouble() : double.tryParse(actual),
    );
  }

  static AssertionResult _compare(
    Assertion a, {
    required String actual,
    double? numericActual,
  }) {
    final double? expectedNumber = double.tryParse(a.expected.trim());
    final bool passed = switch (a.comparator) {
      AssertComparator.equals => _looseEquals(actual, a.expected),
      AssertComparator.notEquals => !_looseEquals(actual, a.expected),
      AssertComparator.contains =>
        actual.toLowerCase().contains(a.expected.trim().toLowerCase()),
      AssertComparator.notContains =>
        !actual.toLowerCase().contains(a.expected.trim().toLowerCase()),
      AssertComparator.under => numericActual != null &&
          expectedNumber != null &&
          numericActual < expectedNumber,
      AssertComparator.over => numericActual != null &&
          expectedNumber != null &&
          numericActual > expectedNumber,
      AssertComparator.exists => actual != 'nothing',
    };
    return AssertionResult(assertion: a, passed: passed, actual: actual);
  }

  /// `201` equals `201`, and `"Test post"` equals `Test post`: an expected
  /// value typed with or without its JSON quoting means the same thing.
  static bool _looseEquals(String actual, String expected) {
    final String a = _unquote(actual.trim());
    final String b = _unquote(expected.trim());
    if (a == b) return true;
    final double? na = double.tryParse(a);
    final double? nb = double.tryParse(b);
    return na != null && nb != null && na == nb;
  }

  static String _unquote(String value) =>
      value.length >= 2 &&
              ((value.startsWith('"') && value.endsWith('"')) ||
                  (value.startsWith("'") && value.endsWith("'")))
          ? value.substring(1, value.length - 1)
          : value;

  /// The summary line: "4 of 5 passed".
  static String summary(List<AssertionResult> results) {
    final int passed = results.where((AssertionResult r) => r.passed).length;
    return '$passed of ${results.length} passed';
  }

  static bool allPassed(List<AssertionResult> results) =>
      results.isNotEmpty && results.every((AssertionResult r) => r.passed);
}
