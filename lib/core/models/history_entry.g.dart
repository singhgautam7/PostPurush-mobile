// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HistoryEntry _$HistoryEntryFromJson(Map<String, dynamic> json) =>
    _HistoryEntry(
      id: json['id'] as String,
      requestSnapshot: ApiRequest.fromJson(
        json['requestSnapshot'] as Map<String, dynamic>,
      ),
      status: (json['status'] as num?)?.toInt() ?? 0,
      reasonPhrase: json['reasonPhrase'] as String? ?? '',
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      sentAt: DateTime.parse(json['sentAt'] as String),
      method:
          $enumDecodeNullable(_$HttpMethodEnumMap, json['method']) ??
          HttpMethod.get,
      host: json['host'] as String? ?? '',
      path: json['path'] as String? ?? '',
      name: json['name'] as String? ?? '',
      folderId: json['folderId'] as String?,
      failure: $enumDecodeNullable(_$FailureKindEnumMap, json['failure']),
      body: json['body'] as String? ?? '',
      headers:
          (json['headers'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const <String, String>{},
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$HistoryEntryToJson(_HistoryEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'requestSnapshot': instance.requestSnapshot,
      'status': instance.status,
      'reasonPhrase': instance.reasonPhrase,
      'durationMs': instance.durationMs,
      'sizeBytes': instance.sizeBytes,
      'sentAt': instance.sentAt.toIso8601String(),
      'method': _$HttpMethodEnumMap[instance.method]!,
      'host': instance.host,
      'path': instance.path,
      'name': instance.name,
      'folderId': instance.folderId,
      'failure': _$FailureKindEnumMap[instance.failure],
      'body': instance.body,
      'headers': instance.headers,
      'schemaVersion': instance.schemaVersion,
    };

const _$HttpMethodEnumMap = {
  HttpMethod.get: 'get',
  HttpMethod.post: 'post',
  HttpMethod.put: 'put',
  HttpMethod.patch: 'patch',
  HttpMethod.delete: 'delete',
  HttpMethod.head: 'head',
  HttpMethod.options: 'options',
  HttpMethod.query: 'query',
  HttpMethod.trace: 'trace',
  HttpMethod.connect: 'connect',
};

const _$FailureKindEnumMap = {
  FailureKind.network: 'network',
  FailureKind.timeout: 'timeout',
  FailureKind.cancelled: 'cancelled',
  FailureKind.unknown: 'unknown',
};
