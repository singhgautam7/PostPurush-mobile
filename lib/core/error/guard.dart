import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Reading a stored row must never take the app down.
///
/// A payload can be older than this build, newer than this build, or plain
/// corrupt. All three are the same problem from the list's point of view: this
/// row cannot be drawn. [decodeOrNull] answers null and the caller drops it,
/// which is the board's "migrate or safely discard" rule in one place.
T? decodeOrNull<T>(
  String payload,
  T Function(Map<String, dynamic>) fromJson, {
  required String what,
  int maxSchemaVersion = 1,
}) {
  try {
    final Object? raw = jsonDecode(payload);
    if (raw is! Map<String, dynamic>) return null;
    // A row written by a newer build may carry fields this one cannot honour.
    // Skipping it is safe; guessing at it is not.
    final Object? version = raw['schemaVersion'];
    if (version is int && version > maxSchemaVersion) {
      debugPrint('Skipped a $what at schema $version (this build reads $maxSchemaVersion)');
      return null;
    }
    return fromJson(raw);
  } catch (error, stack) {
    debugPrint('Discarded an unreadable $what: $error');
    assert(() {
      debugPrintStack(stackTrace: stack, label: 'decodeOrNull<$T>');
      return true;
    }());
    return null;
  }
}

/// Decodes a list of payloads, dropping the ones that cannot be read.
List<T> decodeAll<T>(
  Iterable<String> payloads,
  T Function(Map<String, dynamic>) fromJson, {
  required String what,
  int maxSchemaVersion = 1,
}) {
  final List<T> out = <T>[];
  for (final String payload in payloads) {
    final T? value = decodeOrNull<T>(
      payload,
      fromJson,
      what: what,
      maxSchemaVersion: maxSchemaVersion,
    );
    if (value != null) out.add(value);
  }
  return out;
}
