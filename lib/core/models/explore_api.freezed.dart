// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'explore_api.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ApiSample {

 HttpMethod get method; String get path; String get description;
/// Create a copy of ApiSample
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiSampleCopyWith<ApiSample> get copyWith => _$ApiSampleCopyWithImpl<ApiSample>(this as ApiSample, _$identity);

  /// Serializes this ApiSample to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ApiSample;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiSample&&(identical(other.method, _this.method) || other.method == _this.method)&&(identical(other.path, _this.path) || other.path == _this.path)&&(identical(other.description, _this.description) || other.description == _this.description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ApiSample;
  return Object.hash(runtimeType,_this.method,_this.path,_this.description);
}

@override
String toString() {
  final _this = this as ApiSample;
  return 'ApiSample(method: ${_this.method}, path: ${_this.path}, description: ${_this.description})';
}


}

/// @nodoc
abstract mixin class $ApiSampleCopyWith<$Res>  {
  factory $ApiSampleCopyWith(ApiSample value, $Res Function(ApiSample) _then) = _$ApiSampleCopyWithImpl;
@useResult
$Res call({
 HttpMethod method, String path, String description
});




}
/// @nodoc
class _$ApiSampleCopyWithImpl<$Res>
    implements $ApiSampleCopyWith<$Res> {
  _$ApiSampleCopyWithImpl(this._self, this._then);

  final ApiSample _self;
  final $Res Function(ApiSample) _then;

/// Create a copy of ApiSample
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? method = null,Object? path = null,Object? description = null,}) {
  return _then(ApiSample(
method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as HttpMethod,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ApiSample].
extension ApiSamplePatterns on ApiSample {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ApiSample value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ApiSample() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ApiSample value)  $default,){
final _that = this;
switch (_that) {
case _ApiSample():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ApiSample value)?  $default,){
final _that = this;
switch (_that) {
case _ApiSample() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( HttpMethod method,  String path,  String description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApiSample() when $default != null:
return $default(_that.method,_that.path,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( HttpMethod method,  String path,  String description)  $default,) {final _that = this;
switch (_that) {
case _ApiSample():
return $default(_that.method,_that.path,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( HttpMethod method,  String path,  String description)?  $default,) {final _that = this;
switch (_that) {
case _ApiSample() when $default != null:
return $default(_that.method,_that.path,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ApiSample implements ApiSample {
  const _ApiSample({this.method = HttpMethod.get, this.path = '', this.description = ''});
  factory _ApiSample.fromJson(Map<String, dynamic> json) => _$ApiSampleFromJson(json);

@override@JsonKey() final  HttpMethod method;
@override@JsonKey() final  String path;
@override@JsonKey() final  String description;

/// Create a copy of ApiSample
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApiSampleCopyWith<_ApiSample> get copyWith => __$ApiSampleCopyWithImpl<_ApiSample>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ApiSampleToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApiSample&&(identical(other.method, method) || other.method == method)&&(identical(other.path, path) || other.path == path)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,method,path,description);
}

@override
String toString() {
    return 'ApiSample(method: $method, path: $path, description: $description)';
}


}

/// @nodoc
abstract mixin class _$ApiSampleCopyWith<$Res> implements $ApiSampleCopyWith<$Res> {
  factory _$ApiSampleCopyWith(_ApiSample value, $Res Function(_ApiSample) _then) = __$ApiSampleCopyWithImpl;
@override @useResult
$Res call({
 HttpMethod method, String path, String description
});




}
/// @nodoc
class __$ApiSampleCopyWithImpl<$Res>
    implements _$ApiSampleCopyWith<$Res> {
  __$ApiSampleCopyWithImpl(this._self, this._then);

  final _ApiSample _self;
  final $Res Function(_ApiSample) _then;

/// Create a copy of ApiSample
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? method = null,Object? path = null,Object? description = null,}) {
  return _then(_ApiSample(
method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as HttpMethod,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ExploreApi {

 String get name; String get description; String get category; ApiAuth get auth; bool get https; String get baseUrl; String get docsUrl; List<ApiSample> get samples;
/// Create a copy of ExploreApi
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExploreApiCopyWith<ExploreApi> get copyWith => _$ExploreApiCopyWithImpl<ExploreApi>(this as ExploreApi, _$identity);

  /// Serializes this ExploreApi to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ExploreApi;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExploreApi&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.auth, _this.auth) || other.auth == _this.auth)&&(identical(other.https, _this.https) || other.https == _this.https)&&(identical(other.baseUrl, _this.baseUrl) || other.baseUrl == _this.baseUrl)&&(identical(other.docsUrl, _this.docsUrl) || other.docsUrl == _this.docsUrl)&&const DeepCollectionEquality().equals(other.samples, _this.samples));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ExploreApi;
  return Object.hash(runtimeType,_this.name,_this.description,_this.category,_this.auth,_this.https,_this.baseUrl,_this.docsUrl,const DeepCollectionEquality().hash(_this.samples));
}

@override
String toString() {
  final _this = this as ExploreApi;
  return 'ExploreApi(name: ${_this.name}, description: ${_this.description}, category: ${_this.category}, auth: ${_this.auth}, https: ${_this.https}, baseUrl: ${_this.baseUrl}, docsUrl: ${_this.docsUrl}, samples: ${_this.samples})';
}


}

/// @nodoc
abstract mixin class $ExploreApiCopyWith<$Res>  {
  factory $ExploreApiCopyWith(ExploreApi value, $Res Function(ExploreApi) _then) = _$ExploreApiCopyWithImpl;
@useResult
$Res call({
 String name, String description, String category, ApiAuth auth, bool https, String baseUrl, String docsUrl, List<ApiSample> samples
});




}
/// @nodoc
class _$ExploreApiCopyWithImpl<$Res>
    implements $ExploreApiCopyWith<$Res> {
  _$ExploreApiCopyWithImpl(this._self, this._then);

  final ExploreApi _self;
  final $Res Function(ExploreApi) _then;

/// Create a copy of ExploreApi
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? description = null,Object? category = null,Object? auth = null,Object? https = null,Object? baseUrl = null,Object? docsUrl = null,Object? samples = null,}) {
  return _then(ExploreApi(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,auth: null == auth ? _self.auth : auth // ignore: cast_nullable_to_non_nullable
as ApiAuth,https: null == https ? _self.https : https // ignore: cast_nullable_to_non_nullable
as bool,baseUrl: null == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as String,docsUrl: null == docsUrl ? _self.docsUrl : docsUrl // ignore: cast_nullable_to_non_nullable
as String,samples: null == samples ? _self.samples : samples // ignore: cast_nullable_to_non_nullable
as List<ApiSample>,
  ));
}

}


/// Adds pattern-matching-related methods to [ExploreApi].
extension ExploreApiPatterns on ExploreApi {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExploreApi value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExploreApi() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExploreApi value)  $default,){
final _that = this;
switch (_that) {
case _ExploreApi():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExploreApi value)?  $default,){
final _that = this;
switch (_that) {
case _ExploreApi() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String description,  String category,  ApiAuth auth,  bool https,  String baseUrl,  String docsUrl,  List<ApiSample> samples)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExploreApi() when $default != null:
return $default(_that.name,_that.description,_that.category,_that.auth,_that.https,_that.baseUrl,_that.docsUrl,_that.samples);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String description,  String category,  ApiAuth auth,  bool https,  String baseUrl,  String docsUrl,  List<ApiSample> samples)  $default,) {final _that = this;
switch (_that) {
case _ExploreApi():
return $default(_that.name,_that.description,_that.category,_that.auth,_that.https,_that.baseUrl,_that.docsUrl,_that.samples);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String description,  String category,  ApiAuth auth,  bool https,  String baseUrl,  String docsUrl,  List<ApiSample> samples)?  $default,) {final _that = this;
switch (_that) {
case _ExploreApi() when $default != null:
return $default(_that.name,_that.description,_that.category,_that.auth,_that.https,_that.baseUrl,_that.docsUrl,_that.samples);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExploreApi implements ExploreApi {
  const _ExploreApi({required this.name, this.description = '', this.category = '', this.auth = ApiAuth.none, this.https = true, this.baseUrl = '', this.docsUrl = '',  List<ApiSample> samples = const <ApiSample>[]}): _samples = samples;
  factory _ExploreApi.fromJson(Map<String, dynamic> json) => _$ExploreApiFromJson(json);

@override final  String name;
@override@JsonKey() final  String description;
@override@JsonKey() final  String category;
@override@JsonKey() final  ApiAuth auth;
@override@JsonKey() final  bool https;
@override@JsonKey() final  String baseUrl;
@override@JsonKey() final  String docsUrl;
 final  List<ApiSample> _samples;
@override@JsonKey() List<ApiSample> get samples {
  if (_samples is EqualUnmodifiableListView) return _samples;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_samples);
}


/// Create a copy of ExploreApi
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExploreApiCopyWith<_ExploreApi> get copyWith => __$ExploreApiCopyWithImpl<_ExploreApi>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExploreApiToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExploreApi&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.auth, auth) || other.auth == auth)&&(identical(other.https, https) || other.https == https)&&(identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl)&&(identical(other.docsUrl, docsUrl) || other.docsUrl == docsUrl)&&const DeepCollectionEquality().equals(other.samples, _samples));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,description,category,auth,https,baseUrl,docsUrl,const DeepCollectionEquality().hash(_samples));
}

@override
String toString() {
    return 'ExploreApi(name: $name, description: $description, category: $category, auth: $auth, https: $https, baseUrl: $baseUrl, docsUrl: $docsUrl, samples: $samples)';
}


}

/// @nodoc
abstract mixin class _$ExploreApiCopyWith<$Res> implements $ExploreApiCopyWith<$Res> {
  factory _$ExploreApiCopyWith(_ExploreApi value, $Res Function(_ExploreApi) _then) = __$ExploreApiCopyWithImpl;
@override @useResult
$Res call({
 String name, String description, String category, ApiAuth auth, bool https, String baseUrl, String docsUrl, List<ApiSample> samples
});




}
/// @nodoc
class __$ExploreApiCopyWithImpl<$Res>
    implements _$ExploreApiCopyWith<$Res> {
  __$ExploreApiCopyWithImpl(this._self, this._then);

  final _ExploreApi _self;
  final $Res Function(_ExploreApi) _then;

/// Create a copy of ExploreApi
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? description = null,Object? category = null,Object? auth = null,Object? https = null,Object? baseUrl = null,Object? docsUrl = null,Object? samples = null,}) {
  return _then(_ExploreApi(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,auth: null == auth ? _self.auth : auth // ignore: cast_nullable_to_non_nullable
as ApiAuth,https: null == https ? _self.https : https // ignore: cast_nullable_to_non_nullable
as bool,baseUrl: null == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as String,docsUrl: null == docsUrl ? _self.docsUrl : docsUrl // ignore: cast_nullable_to_non_nullable
as String,samples: null == samples ? _self._samples : samples // ignore: cast_nullable_to_non_nullable
as List<ApiSample>,
  ));
}


}

// dart format on
