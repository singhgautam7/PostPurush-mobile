// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'history_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HistoryEntry {

 String get id; ApiRequest get requestSnapshot;/// 0 when nothing came back.
 int get status; String get reasonPhrase; int get durationMs; int get sizeBytes; DateTime get sentAt;/// Denormalised so the list and the analytics queries never have to decode
/// the snapshot to draw a row or group by host.
 HttpMethod get method; String get host; String get path; String get name; String? get folderId;/// Set when there was no response at all.
 FailureKind? get failure;/// The response body, so a reopened entry shows what came back. Bodies
/// past [maxStoredBody] are dropped rather than growing the database.
 String get body; Map<String, String> get headers; int get schemaVersion;
/// Create a copy of HistoryEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HistoryEntryCopyWith<HistoryEntry> get copyWith => _$HistoryEntryCopyWithImpl<HistoryEntry>(this as HistoryEntry, _$identity);

  /// Serializes this HistoryEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as HistoryEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HistoryEntry&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.requestSnapshot, _this.requestSnapshot) || other.requestSnapshot == _this.requestSnapshot)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.reasonPhrase, _this.reasonPhrase) || other.reasonPhrase == _this.reasonPhrase)&&(identical(other.durationMs, _this.durationMs) || other.durationMs == _this.durationMs)&&(identical(other.sizeBytes, _this.sizeBytes) || other.sizeBytes == _this.sizeBytes)&&(identical(other.sentAt, _this.sentAt) || other.sentAt == _this.sentAt)&&(identical(other.method, _this.method) || other.method == _this.method)&&(identical(other.host, _this.host) || other.host == _this.host)&&(identical(other.path, _this.path) || other.path == _this.path)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.folderId, _this.folderId) || other.folderId == _this.folderId)&&(identical(other.failure, _this.failure) || other.failure == _this.failure)&&(identical(other.body, _this.body) || other.body == _this.body)&&const DeepCollectionEquality().equals(other.headers, _this.headers)&&(identical(other.schemaVersion, _this.schemaVersion) || other.schemaVersion == _this.schemaVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as HistoryEntry;
  return Object.hash(runtimeType,_this.id,_this.requestSnapshot,_this.status,_this.reasonPhrase,_this.durationMs,_this.sizeBytes,_this.sentAt,_this.method,_this.host,_this.path,_this.name,_this.folderId,_this.failure,_this.body,const DeepCollectionEquality().hash(_this.headers),_this.schemaVersion);
}

@override
String toString() {
  final _this = this as HistoryEntry;
  return 'HistoryEntry(id: ${_this.id}, requestSnapshot: ${_this.requestSnapshot}, status: ${_this.status}, reasonPhrase: ${_this.reasonPhrase}, durationMs: ${_this.durationMs}, sizeBytes: ${_this.sizeBytes}, sentAt: ${_this.sentAt}, method: ${_this.method}, host: ${_this.host}, path: ${_this.path}, name: ${_this.name}, folderId: ${_this.folderId}, failure: ${_this.failure}, body: ${_this.body}, headers: ${_this.headers}, schemaVersion: ${_this.schemaVersion})';
}


}

/// @nodoc
abstract mixin class $HistoryEntryCopyWith<$Res>  {
  factory $HistoryEntryCopyWith(HistoryEntry value, $Res Function(HistoryEntry) _then) = _$HistoryEntryCopyWithImpl;
@useResult
$Res call({
 String id, ApiRequest requestSnapshot, int status, String reasonPhrase, int durationMs, int sizeBytes, DateTime sentAt, HttpMethod method, String host, String path, String name, String? folderId, FailureKind? failure, String body, Map<String, String> headers, int schemaVersion
});


$ApiRequestCopyWith<$Res> get requestSnapshot;

}
/// @nodoc
class _$HistoryEntryCopyWithImpl<$Res>
    implements $HistoryEntryCopyWith<$Res> {
  _$HistoryEntryCopyWithImpl(this._self, this._then);

  final HistoryEntry _self;
  final $Res Function(HistoryEntry) _then;

/// Create a copy of HistoryEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? requestSnapshot = null,Object? status = null,Object? reasonPhrase = null,Object? durationMs = null,Object? sizeBytes = null,Object? sentAt = null,Object? method = null,Object? host = null,Object? path = null,Object? name = null,Object? folderId = freezed,Object? failure = freezed,Object? body = null,Object? headers = null,Object? schemaVersion = null,}) {
  return _then(HistoryEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,requestSnapshot: null == requestSnapshot ? _self.requestSnapshot : requestSnapshot // ignore: cast_nullable_to_non_nullable
as ApiRequest,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as int,reasonPhrase: null == reasonPhrase ? _self.reasonPhrase : reasonPhrase // ignore: cast_nullable_to_non_nullable
as String,durationMs: null == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,sentAt: null == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as HttpMethod,host: null == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,folderId: freezed == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as String?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as FailureKind?,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,headers: null == headers ? _self.headers : headers // ignore: cast_nullable_to_non_nullable
as Map<String, String>,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of HistoryEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApiRequestCopyWith<$Res> get requestSnapshot {
  
  return $ApiRequestCopyWith<$Res>(_self.requestSnapshot, (value) {
    return _then(_self.copyWith(requestSnapshot: value));
  });
}
}


/// Adds pattern-matching-related methods to [HistoryEntry].
extension HistoryEntryPatterns on HistoryEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HistoryEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HistoryEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HistoryEntry value)  $default,){
final _that = this;
switch (_that) {
case _HistoryEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HistoryEntry value)?  $default,){
final _that = this;
switch (_that) {
case _HistoryEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  ApiRequest requestSnapshot,  int status,  String reasonPhrase,  int durationMs,  int sizeBytes,  DateTime sentAt,  HttpMethod method,  String host,  String path,  String name,  String? folderId,  FailureKind? failure,  String body,  Map<String, String> headers,  int schemaVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HistoryEntry() when $default != null:
return $default(_that.id,_that.requestSnapshot,_that.status,_that.reasonPhrase,_that.durationMs,_that.sizeBytes,_that.sentAt,_that.method,_that.host,_that.path,_that.name,_that.folderId,_that.failure,_that.body,_that.headers,_that.schemaVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  ApiRequest requestSnapshot,  int status,  String reasonPhrase,  int durationMs,  int sizeBytes,  DateTime sentAt,  HttpMethod method,  String host,  String path,  String name,  String? folderId,  FailureKind? failure,  String body,  Map<String, String> headers,  int schemaVersion)  $default,) {final _that = this;
switch (_that) {
case _HistoryEntry():
return $default(_that.id,_that.requestSnapshot,_that.status,_that.reasonPhrase,_that.durationMs,_that.sizeBytes,_that.sentAt,_that.method,_that.host,_that.path,_that.name,_that.folderId,_that.failure,_that.body,_that.headers,_that.schemaVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  ApiRequest requestSnapshot,  int status,  String reasonPhrase,  int durationMs,  int sizeBytes,  DateTime sentAt,  HttpMethod method,  String host,  String path,  String name,  String? folderId,  FailureKind? failure,  String body,  Map<String, String> headers,  int schemaVersion)?  $default,) {final _that = this;
switch (_that) {
case _HistoryEntry() when $default != null:
return $default(_that.id,_that.requestSnapshot,_that.status,_that.reasonPhrase,_that.durationMs,_that.sizeBytes,_that.sentAt,_that.method,_that.host,_that.path,_that.name,_that.folderId,_that.failure,_that.body,_that.headers,_that.schemaVersion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HistoryEntry implements HistoryEntry {
  const _HistoryEntry({required this.id, required this.requestSnapshot, this.status = 0, this.reasonPhrase = '', this.durationMs = 0, this.sizeBytes = 0, required this.sentAt, this.method = HttpMethod.get, this.host = '', this.path = '', this.name = '', this.folderId, this.failure, this.body = '',  Map<String, String> headers = const <String, String>{}, this.schemaVersion = 1}): _headers = headers;
  factory _HistoryEntry.fromJson(Map<String, dynamic> json) => _$HistoryEntryFromJson(json);

@override final  String id;
@override final  ApiRequest requestSnapshot;
/// 0 when nothing came back.
@override@JsonKey() final  int status;
@override@JsonKey() final  String reasonPhrase;
@override@JsonKey() final  int durationMs;
@override@JsonKey() final  int sizeBytes;
@override final  DateTime sentAt;
/// Denormalised so the list and the analytics queries never have to decode
/// the snapshot to draw a row or group by host.
@override@JsonKey() final  HttpMethod method;
@override@JsonKey() final  String host;
@override@JsonKey() final  String path;
@override@JsonKey() final  String name;
@override final  String? folderId;
/// Set when there was no response at all.
@override final  FailureKind? failure;
/// The response body, so a reopened entry shows what came back. Bodies
/// past [maxStoredBody] are dropped rather than growing the database.
@override@JsonKey() final  String body;
 final  Map<String, String> _headers;
@override@JsonKey() Map<String, String> get headers {
  if (_headers is EqualUnmodifiableMapView) return _headers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_headers);
}

@override@JsonKey() final  int schemaVersion;

/// Create a copy of HistoryEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HistoryEntryCopyWith<_HistoryEntry> get copyWith => __$HistoryEntryCopyWithImpl<_HistoryEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HistoryEntryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HistoryEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.requestSnapshot, requestSnapshot) || other.requestSnapshot == requestSnapshot)&&(identical(other.status, status) || other.status == status)&&(identical(other.reasonPhrase, reasonPhrase) || other.reasonPhrase == reasonPhrase)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.method, method) || other.method == method)&&(identical(other.host, host) || other.host == host)&&(identical(other.path, path) || other.path == path)&&(identical(other.name, name) || other.name == name)&&(identical(other.folderId, folderId) || other.folderId == folderId)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.body, body) || other.body == body)&&const DeepCollectionEquality().equals(other.headers, _headers)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,requestSnapshot,status,reasonPhrase,durationMs,sizeBytes,sentAt,method,host,path,name,folderId,failure,body,const DeepCollectionEquality().hash(_headers),schemaVersion);
}

@override
String toString() {
    return 'HistoryEntry(id: $id, requestSnapshot: $requestSnapshot, status: $status, reasonPhrase: $reasonPhrase, durationMs: $durationMs, sizeBytes: $sizeBytes, sentAt: $sentAt, method: $method, host: $host, path: $path, name: $name, folderId: $folderId, failure: $failure, body: $body, headers: $headers, schemaVersion: $schemaVersion)';
}


}

/// @nodoc
abstract mixin class _$HistoryEntryCopyWith<$Res> implements $HistoryEntryCopyWith<$Res> {
  factory _$HistoryEntryCopyWith(_HistoryEntry value, $Res Function(_HistoryEntry) _then) = __$HistoryEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, ApiRequest requestSnapshot, int status, String reasonPhrase, int durationMs, int sizeBytes, DateTime sentAt, HttpMethod method, String host, String path, String name, String? folderId, FailureKind? failure, String body, Map<String, String> headers, int schemaVersion
});


@override $ApiRequestCopyWith<$Res> get requestSnapshot;

}
/// @nodoc
class __$HistoryEntryCopyWithImpl<$Res>
    implements _$HistoryEntryCopyWith<$Res> {
  __$HistoryEntryCopyWithImpl(this._self, this._then);

  final _HistoryEntry _self;
  final $Res Function(_HistoryEntry) _then;

/// Create a copy of HistoryEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? requestSnapshot = null,Object? status = null,Object? reasonPhrase = null,Object? durationMs = null,Object? sizeBytes = null,Object? sentAt = null,Object? method = null,Object? host = null,Object? path = null,Object? name = null,Object? folderId = freezed,Object? failure = freezed,Object? body = null,Object? headers = null,Object? schemaVersion = null,}) {
  return _then(_HistoryEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,requestSnapshot: null == requestSnapshot ? _self.requestSnapshot : requestSnapshot // ignore: cast_nullable_to_non_nullable
as ApiRequest,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as int,reasonPhrase: null == reasonPhrase ? _self.reasonPhrase : reasonPhrase // ignore: cast_nullable_to_non_nullable
as String,durationMs: null == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,sentAt: null == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as HttpMethod,host: null == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,folderId: freezed == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as String?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as FailureKind?,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,headers: null == headers ? _self._headers : headers // ignore: cast_nullable_to_non_nullable
as Map<String, String>,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of HistoryEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApiRequestCopyWith<$Res> get requestSnapshot {
  
  return $ApiRequestCopyWith<$Res>(_self.requestSnapshot, (value) {
    return _then(_self.copyWith(requestSnapshot: value));
  });
}
}

// dart format on
