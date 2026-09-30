// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'key_value.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_KeyValueRow _$KeyValueRowFromJson(Map<String, dynamic> json) => _KeyValueRow(
  id: json['id'] as String,
  key: json['key'] as String? ?? '',
  value: json['value'] as String? ?? '',
  description: json['description'] as String?,
  enabled: json['enabled'] as bool? ?? true,
  secret: json['secret'] as bool? ?? false,
  type: $enumDecodeNullable(_$VarTypeEnumMap, json['type']) ?? VarType.string,
);

Map<String, dynamic> _$KeyValueRowToJson(_KeyValueRow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'key': instance.key,
      'value': instance.value,
      'description': instance.description,
      'enabled': instance.enabled,
      'secret': instance.secret,
      'type': _$VarTypeEnumMap[instance.type]!,
    };

const _$VarTypeEnumMap = {
  VarType.string: 'string',
  VarType.number: 'number',
  VarType.boolean: 'boolean',
  VarType.json: 'json',
};
