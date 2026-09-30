// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'environment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Environment _$EnvironmentFromJson(Map<String, dynamic> json) => _Environment(
  id: json['id'] as String,
  name: json['name'] as String? ?? '',
  icon: $enumDecodeNullable(_$EnvIconEnumMap, json['icon']) ?? EnvIcon.public,
  colour: (json['colour'] as num?)?.toInt() ?? 0,
  variables:
      (json['variables'] as List<dynamic>?)
          ?.map((e) => KeyValueRow.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <KeyValueRow>[],
  order: (json['order'] as num?)?.toInt() ?? 0,
  schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
);

Map<String, dynamic> _$EnvironmentToJson(_Environment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'icon': _$EnvIconEnumMap[instance.icon]!,
      'colour': instance.colour,
      'variables': instance.variables,
      'order': instance.order,
      'schemaVersion': instance.schemaVersion,
    };

const _$EnvIconEnumMap = {
  EnvIcon.public: 'public',
  EnvIcon.dns: 'dns',
  EnvIcon.database: 'database',
  EnvIcon.cloud: 'cloud',
  EnvIcon.science: 'science',
  EnvIcon.laptop: 'laptop',
  EnvIcon.rocket: 'rocket',
  EnvIcon.bug: 'bug',
  EnvIcon.terminal: 'terminal',
  EnvIcon.lan: 'lan',
  EnvIcon.shield: 'shield',
  EnvIcon.key: 'key',
};
