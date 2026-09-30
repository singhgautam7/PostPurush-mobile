import 'package:freezed_annotation/freezed_annotation.dart';

import 'http_method.dart';

part 'key_value.freezed.dart';
part 'key_value.g.dart';

/// One row of a key/value editor: a query parameter, a header, a form field or
/// an environment variable. The board draws all four with the same row (13,
/// "Key/value row"), so they are all this model.
@freezed
abstract class KeyValueRow with _$KeyValueRow {
  const factory KeyValueRow({
    required String id,
    @Default('') String key,
    @Default('') String value,
    String? description,
    @Default(true) bool enabled,

    /// Environment variables only: masked in the UI and left out of exports.
    @Default(false) bool secret,

    /// Environment variables only: decides how the value is inserted.
    @Default(VarType.string) VarType type,
  }) = _KeyValueRow;

  factory KeyValueRow.fromJson(Map<String, dynamic> json) =>
      _$KeyValueRowFromJson(json);
}

extension KeyValueRowList on List<KeyValueRow> {
  /// The rows that actually go on the wire: enabled, with a key.
  Iterable<KeyValueRow> get active =>
      where((KeyValueRow r) => r.enabled && r.key.trim().isNotEmpty);

  /// How the tab badge counts: enabled out of total, or just the total when
  /// they agree.
  String? get badge {
    final int total = where((KeyValueRow r) => r.key.trim().isNotEmpty).length;
    if (total == 0) return null;
    final int on = active.length;
    return on == total ? '$total' : '$on/$total';
  }
}
