import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'key_value.dart';

part 'environment.freezed.dart';
part 'environment.g.dart';

/// The twelve environment icons from the board's icon sheet (4.3), in its
/// order. The glyph is held here so there is one lookup, not a switch in every
/// widget that draws an environment.
enum EnvIcon {
  public(Icons.public_rounded),
  dns(Icons.dns_rounded),
  database(Icons.storage_rounded),
  cloud(Icons.cloud_rounded),
  science(Icons.science_rounded),
  laptop(Icons.laptop_mac_rounded),
  rocket(Icons.rocket_launch_rounded),
  bug(Icons.bug_report_rounded),
  terminal(Icons.terminal_rounded),
  lan(Icons.lan_rounded),
  shield(Icons.shield_rounded),
  key(Icons.key_rounded);

  const EnvIcon(this.glyph);

  final IconData glyph;

  static EnvIcon parse(String? value) => EnvIcon.values.firstWhere(
    (EnvIcon i) => i.name == value,
    orElse: () => EnvIcon.public,
  );
}

/// One stage of work: a name, an icon, a colour and its variables. The colour
/// is an index into `AppColors.catHues`, never an ARGB value, so it is
/// re-derived per theme and stays legible in light, dark and true black.
@freezed
abstract class Environment with _$Environment {
  const factory Environment({
    required String id,
    @Default('') String name,
    @Default(EnvIcon.public) EnvIcon icon,
    @Default(0) int colour,
    @Default(<KeyValueRow>[]) List<KeyValueRow> variables,
    @Default(0) int order,
    @Default(1) int schemaVersion,
  }) = _Environment;

  factory Environment.fromJson(Map<String, dynamic> json) =>
      _$EnvironmentFromJson(json);

  /// The current shape. Keep this and the `@Default` above in step: the
  /// generated code copies that annotation verbatim, where a static on this
  /// class is not in scope, so the literal cannot be replaced by the constant.
  static const int schema = 1;
}

extension EnvironmentX on Environment {
  /// "5 variables · 2 secret", as the list draws it.
  String get summary {
    final int n = variables.length;
    final int secret = variables.where((KeyValueRow v) => v.secret).length;
    final String head = n == 1 ? '1 variable' : '$n variables';
    return secret == 0 ? head : '$head · $secret secret';
  }

  /// The value for a key, or null if this environment does not carry it.
  /// Disabled rows count as absent, so a row can be parked without deleting it.
  String? lookup(String key) {
    for (final KeyValueRow v in variables) {
      if (v.enabled && v.key == key) return v.value;
    }
    return null;
  }

  bool isSecret(String key) => variables.any(
    (KeyValueRow v) => v.key == key && v.secret,
  );
}
