// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Folder _$FolderFromJson(Map<String, dynamic> json) => _Folder(
  id: json['id'] as String,
  name: json['name'] as String? ?? '',
  description: json['description'] as String? ?? '',
  parentId: json['parentId'] as String?,
  order: (json['order'] as num?)?.toInt() ?? 0,
  schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
);

Map<String, dynamic> _$FolderToJson(_Folder instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'parentId': instance.parentId,
  'order': instance.order,
  'schemaVersion': instance.schemaVersion,
};
