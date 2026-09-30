// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'explore_api.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ApiSample _$ApiSampleFromJson(Map<String, dynamic> json) => _ApiSample(
  method:
      $enumDecodeNullable(_$HttpMethodEnumMap, json['method']) ??
      HttpMethod.get,
  path: json['path'] as String? ?? '',
  description: json['description'] as String? ?? '',
);

Map<String, dynamic> _$ApiSampleToJson(_ApiSample instance) =>
    <String, dynamic>{
      'method': _$HttpMethodEnumMap[instance.method]!,
      'path': instance.path,
      'description': instance.description,
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

_ExploreApi _$ExploreApiFromJson(Map<String, dynamic> json) => _ExploreApi(
  name: json['name'] as String,
  description: json['description'] as String? ?? '',
  category: json['category'] as String? ?? '',
  auth: $enumDecodeNullable(_$ApiAuthEnumMap, json['auth']) ?? ApiAuth.none,
  https: json['https'] as bool? ?? true,
  baseUrl: json['baseUrl'] as String? ?? '',
  docsUrl: json['docsUrl'] as String? ?? '',
  samples:
      (json['samples'] as List<dynamic>?)
          ?.map((e) => ApiSample.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ApiSample>[],
);

Map<String, dynamic> _$ExploreApiToJson(_ExploreApi instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'category': instance.category,
      'auth': _$ApiAuthEnumMap[instance.auth]!,
      'https': instance.https,
      'baseUrl': instance.baseUrl,
      'docsUrl': instance.docsUrl,
      'samples': instance.samples,
    };

const _$ApiAuthEnumMap = {
  ApiAuth.none: 'none',
  ApiAuth.apiKey: 'apiKey',
  ApiAuth.oauth: 'oauth',
  ApiAuth.other: 'other',
};
