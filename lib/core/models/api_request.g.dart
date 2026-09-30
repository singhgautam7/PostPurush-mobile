// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuthConfig _$AuthConfigFromJson(Map<String, dynamic> json) => _AuthConfig(
  type: $enumDecodeNullable(_$AuthTypeEnumMap, json['type']) ?? AuthType.none,
  token: json['token'] as String? ?? '',
  username: json['username'] as String? ?? '',
  password: json['password'] as String? ?? '',
  keyName: json['keyName'] as String? ?? '',
  keyValue: json['keyValue'] as String? ?? '',
  keyIn:
      $enumDecodeNullable(_$ApiKeyLocationEnumMap, json['keyIn']) ??
      ApiKeyLocation.header,
);

Map<String, dynamic> _$AuthConfigToJson(_AuthConfig instance) =>
    <String, dynamic>{
      'type': _$AuthTypeEnumMap[instance.type]!,
      'token': instance.token,
      'username': instance.username,
      'password': instance.password,
      'keyName': instance.keyName,
      'keyValue': instance.keyValue,
      'keyIn': _$ApiKeyLocationEnumMap[instance.keyIn]!,
    };

const _$AuthTypeEnumMap = {
  AuthType.none: 'none',
  AuthType.bearer: 'bearer',
  AuthType.basic: 'basic',
  AuthType.apiKey: 'apiKey',
};

const _$ApiKeyLocationEnumMap = {
  ApiKeyLocation.header: 'header',
  ApiKeyLocation.query: 'query',
};

_Assertion _$AssertionFromJson(Map<String, dynamic> json) => _Assertion(
  id: json['id'] as String,
  target:
      $enumDecodeNullable(_$AssertTargetEnumMap, json['target']) ??
      AssertTarget.status,
  comparator:
      $enumDecodeNullable(_$AssertComparatorEnumMap, json['comparator']) ??
      AssertComparator.equals,
  subject: json['subject'] as String? ?? '',
  expected: json['expected'] as String? ?? '',
);

Map<String, dynamic> _$AssertionToJson(_Assertion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'target': _$AssertTargetEnumMap[instance.target]!,
      'comparator': _$AssertComparatorEnumMap[instance.comparator]!,
      'subject': instance.subject,
      'expected': instance.expected,
    };

const _$AssertTargetEnumMap = {
  AssertTarget.status: 'status',
  AssertTarget.responseTime: 'responseTime',
  AssertTarget.header: 'header',
  AssertTarget.body: 'body',
  AssertTarget.jsonPath: 'jsonPath',
};

const _$AssertComparatorEnumMap = {
  AssertComparator.equals: 'equals',
  AssertComparator.notEquals: 'notEquals',
  AssertComparator.contains: 'contains',
  AssertComparator.notContains: 'notContains',
  AssertComparator.under: 'under',
  AssertComparator.over: 'over',
  AssertComparator.exists: 'exists',
};

_ApiRequest _$ApiRequestFromJson(Map<String, dynamic> json) => _ApiRequest(
  id: json['id'] as String,
  name: json['name'] as String? ?? '',
  description: json['description'] as String? ?? '',
  method:
      $enumDecodeNullable(_$HttpMethodEnumMap, json['method']) ??
      HttpMethod.get,
  url: json['url'] as String? ?? '',
  params:
      (json['params'] as List<dynamic>?)
          ?.map((e) => KeyValueRow.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <KeyValueRow>[],
  headers:
      (json['headers'] as List<dynamic>?)
          ?.map((e) => KeyValueRow.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <KeyValueRow>[],
  formFields:
      (json['formFields'] as List<dynamic>?)
          ?.map((e) => KeyValueRow.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <KeyValueRow>[],
  body: json['body'] as String? ?? '',
  bodyType:
      $enumDecodeNullable(_$BodyTypeEnumMap, json['bodyType']) ?? BodyType.none,
  auth: json['auth'] == null
      ? const AuthConfig()
      : AuthConfig.fromJson(json['auth'] as Map<String, dynamic>),
  assertions:
      (json['assertions'] as List<dynamic>?)
          ?.map((e) => Assertion.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Assertion>[],
  folderId: json['folderId'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  order: (json['order'] as num?)?.toInt() ?? 0,
  schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
);

Map<String, dynamic> _$ApiRequestToJson(_ApiRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'method': _$HttpMethodEnumMap[instance.method]!,
      'url': instance.url,
      'params': instance.params,
      'headers': instance.headers,
      'formFields': instance.formFields,
      'body': instance.body,
      'bodyType': _$BodyTypeEnumMap[instance.bodyType]!,
      'auth': instance.auth,
      'assertions': instance.assertions,
      'folderId': instance.folderId,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'order': instance.order,
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

const _$BodyTypeEnumMap = {
  BodyType.none: 'none',
  BodyType.json: 'json',
  BodyType.form: 'form',
  BodyType.raw: 'raw',
};
