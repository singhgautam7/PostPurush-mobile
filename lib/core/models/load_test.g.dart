// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'load_test.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LoadTestConfig _$LoadTestConfigFromJson(Map<String, dynamic> json) =>
    _LoadTestConfig(
      concurrency: (json['concurrency'] as num?)?.toInt() ?? 10,
      stop:
          $enumDecodeNullable(_$LoadStopEnumMap, json['stop']) ??
          LoadStop.iterations,
      iterations: (json['iterations'] as num?)?.toInt() ?? 500,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 30,
    );

Map<String, dynamic> _$LoadTestConfigToJson(_LoadTestConfig instance) =>
    <String, dynamic>{
      'concurrency': instance.concurrency,
      'stop': _$LoadStopEnumMap[instance.stop]!,
      'iterations': instance.iterations,
      'durationSeconds': instance.durationSeconds,
    };

const _$LoadStopEnumMap = {
  LoadStop.iterations: 'iterations',
  LoadStop.duration: 'duration',
};

_LoadTestResult _$LoadTestResultFromJson(Map<String, dynamic> json) =>
    _LoadTestResult(
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      successes: (json['successes'] as num?)?.toInt() ?? 0,
      errors: (json['errors'] as num?)?.toInt() ?? 0,
      elapsedMs: (json['elapsedMs'] as num?)?.toInt() ?? 0,
      latencies:
          (json['latencies'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      finished: json['finished'] as bool? ?? false,
    );

Map<String, dynamic> _$LoadTestResultToJson(_LoadTestResult instance) =>
    <String, dynamic>{
      'completed': instance.completed,
      'total': instance.total,
      'successes': instance.successes,
      'errors': instance.errors,
      'elapsedMs': instance.elapsedMs,
      'latencies': instance.latencies,
      'finished': instance.finished,
    };
