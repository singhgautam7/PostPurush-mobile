// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'load_test.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LoadTestConfig {

 int get concurrency; LoadStop get stop; int get iterations; int get durationSeconds;
/// Create a copy of LoadTestConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoadTestConfigCopyWith<LoadTestConfig> get copyWith => _$LoadTestConfigCopyWithImpl<LoadTestConfig>(this as LoadTestConfig, _$identity);

  /// Serializes this LoadTestConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LoadTestConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoadTestConfig&&(identical(other.concurrency, _this.concurrency) || other.concurrency == _this.concurrency)&&(identical(other.stop, _this.stop) || other.stop == _this.stop)&&(identical(other.iterations, _this.iterations) || other.iterations == _this.iterations)&&(identical(other.durationSeconds, _this.durationSeconds) || other.durationSeconds == _this.durationSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LoadTestConfig;
  return Object.hash(runtimeType,_this.concurrency,_this.stop,_this.iterations,_this.durationSeconds);
}

@override
String toString() {
  final _this = this as LoadTestConfig;
  return 'LoadTestConfig(concurrency: ${_this.concurrency}, stop: ${_this.stop}, iterations: ${_this.iterations}, durationSeconds: ${_this.durationSeconds})';
}


}

/// @nodoc
abstract mixin class $LoadTestConfigCopyWith<$Res>  {
  factory $LoadTestConfigCopyWith(LoadTestConfig value, $Res Function(LoadTestConfig) _then) = _$LoadTestConfigCopyWithImpl;
@useResult
$Res call({
 int concurrency, LoadStop stop, int iterations, int durationSeconds
});




}
/// @nodoc
class _$LoadTestConfigCopyWithImpl<$Res>
    implements $LoadTestConfigCopyWith<$Res> {
  _$LoadTestConfigCopyWithImpl(this._self, this._then);

  final LoadTestConfig _self;
  final $Res Function(LoadTestConfig) _then;

/// Create a copy of LoadTestConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? concurrency = null,Object? stop = null,Object? iterations = null,Object? durationSeconds = null,}) {
  return _then(LoadTestConfig(
concurrency: null == concurrency ? _self.concurrency : concurrency // ignore: cast_nullable_to_non_nullable
as int,stop: null == stop ? _self.stop : stop // ignore: cast_nullable_to_non_nullable
as LoadStop,iterations: null == iterations ? _self.iterations : iterations // ignore: cast_nullable_to_non_nullable
as int,durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LoadTestConfig].
extension LoadTestConfigPatterns on LoadTestConfig {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LoadTestConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LoadTestConfig() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LoadTestConfig value)  $default,){
final _that = this;
switch (_that) {
case _LoadTestConfig():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LoadTestConfig value)?  $default,){
final _that = this;
switch (_that) {
case _LoadTestConfig() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int concurrency,  LoadStop stop,  int iterations,  int durationSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LoadTestConfig() when $default != null:
return $default(_that.concurrency,_that.stop,_that.iterations,_that.durationSeconds);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int concurrency,  LoadStop stop,  int iterations,  int durationSeconds)  $default,) {final _that = this;
switch (_that) {
case _LoadTestConfig():
return $default(_that.concurrency,_that.stop,_that.iterations,_that.durationSeconds);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int concurrency,  LoadStop stop,  int iterations,  int durationSeconds)?  $default,) {final _that = this;
switch (_that) {
case _LoadTestConfig() when $default != null:
return $default(_that.concurrency,_that.stop,_that.iterations,_that.durationSeconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LoadTestConfig implements LoadTestConfig {
  const _LoadTestConfig({this.concurrency = 10, this.stop = LoadStop.iterations, this.iterations = 500, this.durationSeconds = 30});
  factory _LoadTestConfig.fromJson(Map<String, dynamic> json) => _$LoadTestConfigFromJson(json);

@override@JsonKey() final  int concurrency;
@override@JsonKey() final  LoadStop stop;
@override@JsonKey() final  int iterations;
@override@JsonKey() final  int durationSeconds;

/// Create a copy of LoadTestConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadTestConfigCopyWith<_LoadTestConfig> get copyWith => __$LoadTestConfigCopyWithImpl<_LoadTestConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LoadTestConfigToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadTestConfig&&(identical(other.concurrency, concurrency) || other.concurrency == concurrency)&&(identical(other.stop, stop) || other.stop == stop)&&(identical(other.iterations, iterations) || other.iterations == iterations)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,concurrency,stop,iterations,durationSeconds);
}

@override
String toString() {
    return 'LoadTestConfig(concurrency: $concurrency, stop: $stop, iterations: $iterations, durationSeconds: $durationSeconds)';
}


}

/// @nodoc
abstract mixin class _$LoadTestConfigCopyWith<$Res> implements $LoadTestConfigCopyWith<$Res> {
  factory _$LoadTestConfigCopyWith(_LoadTestConfig value, $Res Function(_LoadTestConfig) _then) = __$LoadTestConfigCopyWithImpl;
@override @useResult
$Res call({
 int concurrency, LoadStop stop, int iterations, int durationSeconds
});




}
/// @nodoc
class __$LoadTestConfigCopyWithImpl<$Res>
    implements _$LoadTestConfigCopyWith<$Res> {
  __$LoadTestConfigCopyWithImpl(this._self, this._then);

  final _LoadTestConfig _self;
  final $Res Function(_LoadTestConfig) _then;

/// Create a copy of LoadTestConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? concurrency = null,Object? stop = null,Object? iterations = null,Object? durationSeconds = null,}) {
  return _then(_LoadTestConfig(
concurrency: null == concurrency ? _self.concurrency : concurrency // ignore: cast_nullable_to_non_nullable
as int,stop: null == stop ? _self.stop : stop // ignore: cast_nullable_to_non_nullable
as LoadStop,iterations: null == iterations ? _self.iterations : iterations // ignore: cast_nullable_to_non_nullable
as int,durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$LoadTestResult {

 int get completed; int get total; int get successes; int get errors; int get elapsedMs; List<int> get latencies; bool get finished;
/// Create a copy of LoadTestResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoadTestResultCopyWith<LoadTestResult> get copyWith => _$LoadTestResultCopyWithImpl<LoadTestResult>(this as LoadTestResult, _$identity);

  /// Serializes this LoadTestResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LoadTestResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoadTestResult&&(identical(other.completed, _this.completed) || other.completed == _this.completed)&&(identical(other.total, _this.total) || other.total == _this.total)&&(identical(other.successes, _this.successes) || other.successes == _this.successes)&&(identical(other.errors, _this.errors) || other.errors == _this.errors)&&(identical(other.elapsedMs, _this.elapsedMs) || other.elapsedMs == _this.elapsedMs)&&const DeepCollectionEquality().equals(other.latencies, _this.latencies)&&(identical(other.finished, _this.finished) || other.finished == _this.finished));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LoadTestResult;
  return Object.hash(runtimeType,_this.completed,_this.total,_this.successes,_this.errors,_this.elapsedMs,const DeepCollectionEquality().hash(_this.latencies),_this.finished);
}

@override
String toString() {
  final _this = this as LoadTestResult;
  return 'LoadTestResult(completed: ${_this.completed}, total: ${_this.total}, successes: ${_this.successes}, errors: ${_this.errors}, elapsedMs: ${_this.elapsedMs}, latencies: ${_this.latencies}, finished: ${_this.finished})';
}


}

/// @nodoc
abstract mixin class $LoadTestResultCopyWith<$Res>  {
  factory $LoadTestResultCopyWith(LoadTestResult value, $Res Function(LoadTestResult) _then) = _$LoadTestResultCopyWithImpl;
@useResult
$Res call({
 int completed, int total, int successes, int errors, int elapsedMs, List<int> latencies, bool finished
});




}
/// @nodoc
class _$LoadTestResultCopyWithImpl<$Res>
    implements $LoadTestResultCopyWith<$Res> {
  _$LoadTestResultCopyWithImpl(this._self, this._then);

  final LoadTestResult _self;
  final $Res Function(LoadTestResult) _then;

/// Create a copy of LoadTestResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? completed = null,Object? total = null,Object? successes = null,Object? errors = null,Object? elapsedMs = null,Object? latencies = null,Object? finished = null,}) {
  return _then(LoadTestResult(
completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,successes: null == successes ? _self.successes : successes // ignore: cast_nullable_to_non_nullable
as int,errors: null == errors ? _self.errors : errors // ignore: cast_nullable_to_non_nullable
as int,elapsedMs: null == elapsedMs ? _self.elapsedMs : elapsedMs // ignore: cast_nullable_to_non_nullable
as int,latencies: null == latencies ? _self.latencies : latencies // ignore: cast_nullable_to_non_nullable
as List<int>,finished: null == finished ? _self.finished : finished // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LoadTestResult].
extension LoadTestResultPatterns on LoadTestResult {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LoadTestResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LoadTestResult() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LoadTestResult value)  $default,){
final _that = this;
switch (_that) {
case _LoadTestResult():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LoadTestResult value)?  $default,){
final _that = this;
switch (_that) {
case _LoadTestResult() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int completed,  int total,  int successes,  int errors,  int elapsedMs,  List<int> latencies,  bool finished)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LoadTestResult() when $default != null:
return $default(_that.completed,_that.total,_that.successes,_that.errors,_that.elapsedMs,_that.latencies,_that.finished);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int completed,  int total,  int successes,  int errors,  int elapsedMs,  List<int> latencies,  bool finished)  $default,) {final _that = this;
switch (_that) {
case _LoadTestResult():
return $default(_that.completed,_that.total,_that.successes,_that.errors,_that.elapsedMs,_that.latencies,_that.finished);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int completed,  int total,  int successes,  int errors,  int elapsedMs,  List<int> latencies,  bool finished)?  $default,) {final _that = this;
switch (_that) {
case _LoadTestResult() when $default != null:
return $default(_that.completed,_that.total,_that.successes,_that.errors,_that.elapsedMs,_that.latencies,_that.finished);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LoadTestResult implements LoadTestResult {
  const _LoadTestResult({this.completed = 0, this.total = 0, this.successes = 0, this.errors = 0, this.elapsedMs = 0,  List<int> latencies = const <int>[], this.finished = false}): _latencies = latencies;
  factory _LoadTestResult.fromJson(Map<String, dynamic> json) => _$LoadTestResultFromJson(json);

@override@JsonKey() final  int completed;
@override@JsonKey() final  int total;
@override@JsonKey() final  int successes;
@override@JsonKey() final  int errors;
@override@JsonKey() final  int elapsedMs;
 final  List<int> _latencies;
@override@JsonKey() List<int> get latencies {
  if (_latencies is EqualUnmodifiableListView) return _latencies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_latencies);
}

@override@JsonKey() final  bool finished;

/// Create a copy of LoadTestResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadTestResultCopyWith<_LoadTestResult> get copyWith => __$LoadTestResultCopyWithImpl<_LoadTestResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LoadTestResultToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadTestResult&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.total, total) || other.total == total)&&(identical(other.successes, successes) || other.successes == successes)&&(identical(other.errors, errors) || other.errors == errors)&&(identical(other.elapsedMs, elapsedMs) || other.elapsedMs == elapsedMs)&&const DeepCollectionEquality().equals(other.latencies, _latencies)&&(identical(other.finished, finished) || other.finished == finished));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,completed,total,successes,errors,elapsedMs,const DeepCollectionEquality().hash(_latencies),finished);
}

@override
String toString() {
    return 'LoadTestResult(completed: $completed, total: $total, successes: $successes, errors: $errors, elapsedMs: $elapsedMs, latencies: $latencies, finished: $finished)';
}


}

/// @nodoc
abstract mixin class _$LoadTestResultCopyWith<$Res> implements $LoadTestResultCopyWith<$Res> {
  factory _$LoadTestResultCopyWith(_LoadTestResult value, $Res Function(_LoadTestResult) _then) = __$LoadTestResultCopyWithImpl;
@override @useResult
$Res call({
 int completed, int total, int successes, int errors, int elapsedMs, List<int> latencies, bool finished
});




}
/// @nodoc
class __$LoadTestResultCopyWithImpl<$Res>
    implements _$LoadTestResultCopyWith<$Res> {
  __$LoadTestResultCopyWithImpl(this._self, this._then);

  final _LoadTestResult _self;
  final $Res Function(_LoadTestResult) _then;

/// Create a copy of LoadTestResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? completed = null,Object? total = null,Object? successes = null,Object? errors = null,Object? elapsedMs = null,Object? latencies = null,Object? finished = null,}) {
  return _then(_LoadTestResult(
completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,successes: null == successes ? _self.successes : successes // ignore: cast_nullable_to_non_nullable
as int,errors: null == errors ? _self.errors : errors // ignore: cast_nullable_to_non_nullable
as int,elapsedMs: null == elapsedMs ? _self.elapsedMs : elapsedMs // ignore: cast_nullable_to_non_nullable
as int,latencies: null == latencies ? _self._latencies : latencies // ignore: cast_nullable_to_non_nullable
as List<int>,finished: null == finished ? _self.finished : finished // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
