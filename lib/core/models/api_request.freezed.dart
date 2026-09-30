// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AuthConfig {

 AuthType get type;/// Bearer.
 String get token;/// Basic.
 String get username; String get password;/// API key.
 String get keyName; String get keyValue; ApiKeyLocation get keyIn;
/// Create a copy of AuthConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthConfigCopyWith<AuthConfig> get copyWith => _$AuthConfigCopyWithImpl<AuthConfig>(this as AuthConfig, _$identity);

  /// Serializes this AuthConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AuthConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthConfig&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.token, _this.token) || other.token == _this.token)&&(identical(other.username, _this.username) || other.username == _this.username)&&(identical(other.password, _this.password) || other.password == _this.password)&&(identical(other.keyName, _this.keyName) || other.keyName == _this.keyName)&&(identical(other.keyValue, _this.keyValue) || other.keyValue == _this.keyValue)&&(identical(other.keyIn, _this.keyIn) || other.keyIn == _this.keyIn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AuthConfig;
  return Object.hash(runtimeType,_this.type,_this.token,_this.username,_this.password,_this.keyName,_this.keyValue,_this.keyIn);
}

@override
String toString() {
  final _this = this as AuthConfig;
  return 'AuthConfig(type: ${_this.type}, token: ${_this.token}, username: ${_this.username}, password: ${_this.password}, keyName: ${_this.keyName}, keyValue: ${_this.keyValue}, keyIn: ${_this.keyIn})';
}


}

/// @nodoc
abstract mixin class $AuthConfigCopyWith<$Res>  {
  factory $AuthConfigCopyWith(AuthConfig value, $Res Function(AuthConfig) _then) = _$AuthConfigCopyWithImpl;
@useResult
$Res call({
 AuthType type, String token, String username, String password, String keyName, String keyValue, ApiKeyLocation keyIn
});




}
/// @nodoc
class _$AuthConfigCopyWithImpl<$Res>
    implements $AuthConfigCopyWith<$Res> {
  _$AuthConfigCopyWithImpl(this._self, this._then);

  final AuthConfig _self;
  final $Res Function(AuthConfig) _then;

/// Create a copy of AuthConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? token = null,Object? username = null,Object? password = null,Object? keyName = null,Object? keyValue = null,Object? keyIn = null,}) {
  return _then(AuthConfig(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AuthType,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,keyName: null == keyName ? _self.keyName : keyName // ignore: cast_nullable_to_non_nullable
as String,keyValue: null == keyValue ? _self.keyValue : keyValue // ignore: cast_nullable_to_non_nullable
as String,keyIn: null == keyIn ? _self.keyIn : keyIn // ignore: cast_nullable_to_non_nullable
as ApiKeyLocation,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthConfig].
extension AuthConfigPatterns on AuthConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthConfig value)  $default,){
final _that = this;
switch (_that) {
case _AuthConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthConfig value)?  $default,){
final _that = this;
switch (_that) {
case _AuthConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AuthType type,  String token,  String username,  String password,  String keyName,  String keyValue,  ApiKeyLocation keyIn)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthConfig() when $default != null:
return $default(_that.type,_that.token,_that.username,_that.password,_that.keyName,_that.keyValue,_that.keyIn);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AuthType type,  String token,  String username,  String password,  String keyName,  String keyValue,  ApiKeyLocation keyIn)  $default,) {final _that = this;
switch (_that) {
case _AuthConfig():
return $default(_that.type,_that.token,_that.username,_that.password,_that.keyName,_that.keyValue,_that.keyIn);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AuthType type,  String token,  String username,  String password,  String keyName,  String keyValue,  ApiKeyLocation keyIn)?  $default,) {final _that = this;
switch (_that) {
case _AuthConfig() when $default != null:
return $default(_that.type,_that.token,_that.username,_that.password,_that.keyName,_that.keyValue,_that.keyIn);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuthConfig implements AuthConfig {
  const _AuthConfig({this.type = AuthType.none, this.token = '', this.username = '', this.password = '', this.keyName = '', this.keyValue = '', this.keyIn = ApiKeyLocation.header});
  factory _AuthConfig.fromJson(Map<String, dynamic> json) => _$AuthConfigFromJson(json);

@override@JsonKey() final  AuthType type;
/// Bearer.
@override@JsonKey() final  String token;
/// Basic.
@override@JsonKey() final  String username;
@override@JsonKey() final  String password;
/// API key.
@override@JsonKey() final  String keyName;
@override@JsonKey() final  String keyValue;
@override@JsonKey() final  ApiKeyLocation keyIn;

/// Create a copy of AuthConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthConfigCopyWith<_AuthConfig> get copyWith => __$AuthConfigCopyWithImpl<_AuthConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuthConfigToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthConfig&&(identical(other.type, type) || other.type == type)&&(identical(other.token, token) || other.token == token)&&(identical(other.username, username) || other.username == username)&&(identical(other.password, password) || other.password == password)&&(identical(other.keyName, keyName) || other.keyName == keyName)&&(identical(other.keyValue, keyValue) || other.keyValue == keyValue)&&(identical(other.keyIn, keyIn) || other.keyIn == keyIn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,token,username,password,keyName,keyValue,keyIn);
}

@override
String toString() {
    return 'AuthConfig(type: $type, token: $token, username: $username, password: $password, keyName: $keyName, keyValue: $keyValue, keyIn: $keyIn)';
}


}

/// @nodoc
abstract mixin class _$AuthConfigCopyWith<$Res> implements $AuthConfigCopyWith<$Res> {
  factory _$AuthConfigCopyWith(_AuthConfig value, $Res Function(_AuthConfig) _then) = __$AuthConfigCopyWithImpl;
@override @useResult
$Res call({
 AuthType type, String token, String username, String password, String keyName, String keyValue, ApiKeyLocation keyIn
});




}
/// @nodoc
class __$AuthConfigCopyWithImpl<$Res>
    implements _$AuthConfigCopyWith<$Res> {
  __$AuthConfigCopyWithImpl(this._self, this._then);

  final _AuthConfig _self;
  final $Res Function(_AuthConfig) _then;

/// Create a copy of AuthConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? token = null,Object? username = null,Object? password = null,Object? keyName = null,Object? keyValue = null,Object? keyIn = null,}) {
  return _then(_AuthConfig(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AuthType,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,keyName: null == keyName ? _self.keyName : keyName // ignore: cast_nullable_to_non_nullable
as String,keyValue: null == keyValue ? _self.keyValue : keyValue // ignore: cast_nullable_to_non_nullable
as String,keyIn: null == keyIn ? _self.keyIn : keyIn // ignore: cast_nullable_to_non_nullable
as ApiKeyLocation,
  ));
}


}


/// @nodoc
mixin _$Assertion {

 String get id; AssertTarget get target; AssertComparator get comparator;/// The header name, or the JSON path. Empty for the other targets.
 String get subject; String get expected;
/// Create a copy of Assertion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssertionCopyWith<Assertion> get copyWith => _$AssertionCopyWithImpl<Assertion>(this as Assertion, _$identity);

  /// Serializes this Assertion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Assertion;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Assertion&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.target, _this.target) || other.target == _this.target)&&(identical(other.comparator, _this.comparator) || other.comparator == _this.comparator)&&(identical(other.subject, _this.subject) || other.subject == _this.subject)&&(identical(other.expected, _this.expected) || other.expected == _this.expected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Assertion;
  return Object.hash(runtimeType,_this.id,_this.target,_this.comparator,_this.subject,_this.expected);
}

@override
String toString() {
  final _this = this as Assertion;
  return 'Assertion(id: ${_this.id}, target: ${_this.target}, comparator: ${_this.comparator}, subject: ${_this.subject}, expected: ${_this.expected})';
}


}

/// @nodoc
abstract mixin class $AssertionCopyWith<$Res>  {
  factory $AssertionCopyWith(Assertion value, $Res Function(Assertion) _then) = _$AssertionCopyWithImpl;
@useResult
$Res call({
 String id, AssertTarget target, AssertComparator comparator, String subject, String expected
});




}
/// @nodoc
class _$AssertionCopyWithImpl<$Res>
    implements $AssertionCopyWith<$Res> {
  _$AssertionCopyWithImpl(this._self, this._then);

  final Assertion _self;
  final $Res Function(Assertion) _then;

/// Create a copy of Assertion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? target = null,Object? comparator = null,Object? subject = null,Object? expected = null,}) {
  return _then(Assertion(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as AssertTarget,comparator: null == comparator ? _self.comparator : comparator // ignore: cast_nullable_to_non_nullable
as AssertComparator,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,expected: null == expected ? _self.expected : expected // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Assertion].
extension AssertionPatterns on Assertion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Assertion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Assertion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Assertion value)  $default,){
final _that = this;
switch (_that) {
case _Assertion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Assertion value)?  $default,){
final _that = this;
switch (_that) {
case _Assertion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  AssertTarget target,  AssertComparator comparator,  String subject,  String expected)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Assertion() when $default != null:
return $default(_that.id,_that.target,_that.comparator,_that.subject,_that.expected);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  AssertTarget target,  AssertComparator comparator,  String subject,  String expected)  $default,) {final _that = this;
switch (_that) {
case _Assertion():
return $default(_that.id,_that.target,_that.comparator,_that.subject,_that.expected);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  AssertTarget target,  AssertComparator comparator,  String subject,  String expected)?  $default,) {final _that = this;
switch (_that) {
case _Assertion() when $default != null:
return $default(_that.id,_that.target,_that.comparator,_that.subject,_that.expected);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Assertion implements Assertion {
  const _Assertion({required this.id, this.target = AssertTarget.status, this.comparator = AssertComparator.equals, this.subject = '', this.expected = ''});
  factory _Assertion.fromJson(Map<String, dynamic> json) => _$AssertionFromJson(json);

@override final  String id;
@override@JsonKey() final  AssertTarget target;
@override@JsonKey() final  AssertComparator comparator;
/// The header name, or the JSON path. Empty for the other targets.
@override@JsonKey() final  String subject;
@override@JsonKey() final  String expected;

/// Create a copy of Assertion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssertionCopyWith<_Assertion> get copyWith => __$AssertionCopyWithImpl<_Assertion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AssertionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Assertion&&(identical(other.id, id) || other.id == id)&&(identical(other.target, target) || other.target == target)&&(identical(other.comparator, comparator) || other.comparator == comparator)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.expected, expected) || other.expected == expected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,target,comparator,subject,expected);
}

@override
String toString() {
    return 'Assertion(id: $id, target: $target, comparator: $comparator, subject: $subject, expected: $expected)';
}


}

/// @nodoc
abstract mixin class _$AssertionCopyWith<$Res> implements $AssertionCopyWith<$Res> {
  factory _$AssertionCopyWith(_Assertion value, $Res Function(_Assertion) _then) = __$AssertionCopyWithImpl;
@override @useResult
$Res call({
 String id, AssertTarget target, AssertComparator comparator, String subject, String expected
});




}
/// @nodoc
class __$AssertionCopyWithImpl<$Res>
    implements _$AssertionCopyWith<$Res> {
  __$AssertionCopyWithImpl(this._self, this._then);

  final _Assertion _self;
  final $Res Function(_Assertion) _then;

/// Create a copy of Assertion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? target = null,Object? comparator = null,Object? subject = null,Object? expected = null,}) {
  return _then(_Assertion(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as AssertTarget,comparator: null == comparator ? _self.comparator : comparator // ignore: cast_nullable_to_non_nullable
as AssertComparator,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,expected: null == expected ? _self.expected : expected // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ApiRequest {

 String get id; String get name; String get description; HttpMethod get method; String get url; List<KeyValueRow> get params; List<KeyValueRow> get headers; List<KeyValueRow> get formFields; String get body; BodyType get bodyType; AuthConfig get auth; List<Assertion> get assertions;/// Null means the top level of Collections.
 String? get folderId; DateTime get createdAt; DateTime get updatedAt;/// Order within its folder.
 int get order;/// Bumped whenever this shape changes. On read, an unknown version is
/// migrated or discarded; it never crashes the app.
 int get schemaVersion;
/// Create a copy of ApiRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiRequestCopyWith<ApiRequest> get copyWith => _$ApiRequestCopyWithImpl<ApiRequest>(this as ApiRequest, _$identity);

  /// Serializes this ApiRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ApiRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiRequest&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.method, _this.method) || other.method == _this.method)&&(identical(other.url, _this.url) || other.url == _this.url)&&const DeepCollectionEquality().equals(other.params, _this.params)&&const DeepCollectionEquality().equals(other.headers, _this.headers)&&const DeepCollectionEquality().equals(other.formFields, _this.formFields)&&(identical(other.body, _this.body) || other.body == _this.body)&&(identical(other.bodyType, _this.bodyType) || other.bodyType == _this.bodyType)&&(identical(other.auth, _this.auth) || other.auth == _this.auth)&&const DeepCollectionEquality().equals(other.assertions, _this.assertions)&&(identical(other.folderId, _this.folderId) || other.folderId == _this.folderId)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.order, _this.order) || other.order == _this.order)&&(identical(other.schemaVersion, _this.schemaVersion) || other.schemaVersion == _this.schemaVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ApiRequest;
  return Object.hash(runtimeType,_this.id,_this.name,_this.description,_this.method,_this.url,const DeepCollectionEquality().hash(_this.params),const DeepCollectionEquality().hash(_this.headers),const DeepCollectionEquality().hash(_this.formFields),_this.body,_this.bodyType,_this.auth,const DeepCollectionEquality().hash(_this.assertions),_this.folderId,_this.createdAt,_this.updatedAt,_this.order,_this.schemaVersion);
}

@override
String toString() {
  final _this = this as ApiRequest;
  return 'ApiRequest(id: ${_this.id}, name: ${_this.name}, description: ${_this.description}, method: ${_this.method}, url: ${_this.url}, params: ${_this.params}, headers: ${_this.headers}, formFields: ${_this.formFields}, body: ${_this.body}, bodyType: ${_this.bodyType}, auth: ${_this.auth}, assertions: ${_this.assertions}, folderId: ${_this.folderId}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, order: ${_this.order}, schemaVersion: ${_this.schemaVersion})';
}


}

/// @nodoc
abstract mixin class $ApiRequestCopyWith<$Res>  {
  factory $ApiRequestCopyWith(ApiRequest value, $Res Function(ApiRequest) _then) = _$ApiRequestCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, HttpMethod method, String url, List<KeyValueRow> params, List<KeyValueRow> headers, List<KeyValueRow> formFields, String body, BodyType bodyType, AuthConfig auth, List<Assertion> assertions, String? folderId, DateTime createdAt, DateTime updatedAt, int order, int schemaVersion
});


$AuthConfigCopyWith<$Res> get auth;

}
/// @nodoc
class _$ApiRequestCopyWithImpl<$Res>
    implements $ApiRequestCopyWith<$Res> {
  _$ApiRequestCopyWithImpl(this._self, this._then);

  final ApiRequest _self;
  final $Res Function(ApiRequest) _then;

/// Create a copy of ApiRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? method = null,Object? url = null,Object? params = null,Object? headers = null,Object? formFields = null,Object? body = null,Object? bodyType = null,Object? auth = null,Object? assertions = null,Object? folderId = freezed,Object? createdAt = null,Object? updatedAt = null,Object? order = null,Object? schemaVersion = null,}) {
  return _then(ApiRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as HttpMethod,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,params: null == params ? _self.params : params // ignore: cast_nullable_to_non_nullable
as List<KeyValueRow>,headers: null == headers ? _self.headers : headers // ignore: cast_nullable_to_non_nullable
as List<KeyValueRow>,formFields: null == formFields ? _self.formFields : formFields // ignore: cast_nullable_to_non_nullable
as List<KeyValueRow>,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,bodyType: null == bodyType ? _self.bodyType : bodyType // ignore: cast_nullable_to_non_nullable
as BodyType,auth: null == auth ? _self.auth : auth // ignore: cast_nullable_to_non_nullable
as AuthConfig,assertions: null == assertions ? _self.assertions : assertions // ignore: cast_nullable_to_non_nullable
as List<Assertion>,folderId: freezed == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of ApiRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthConfigCopyWith<$Res> get auth {
  
  return $AuthConfigCopyWith<$Res>(_self.auth, (value) {
    return _then(_self.copyWith(auth: value));
  });
}
}


/// Adds pattern-matching-related methods to [ApiRequest].
extension ApiRequestPatterns on ApiRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ApiRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ApiRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ApiRequest value)  $default,){
final _that = this;
switch (_that) {
case _ApiRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ApiRequest value)?  $default,){
final _that = this;
switch (_that) {
case _ApiRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String description,  HttpMethod method,  String url,  List<KeyValueRow> params,  List<KeyValueRow> headers,  List<KeyValueRow> formFields,  String body,  BodyType bodyType,  AuthConfig auth,  List<Assertion> assertions,  String? folderId,  DateTime createdAt,  DateTime updatedAt,  int order,  int schemaVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApiRequest() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.method,_that.url,_that.params,_that.headers,_that.formFields,_that.body,_that.bodyType,_that.auth,_that.assertions,_that.folderId,_that.createdAt,_that.updatedAt,_that.order,_that.schemaVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String description,  HttpMethod method,  String url,  List<KeyValueRow> params,  List<KeyValueRow> headers,  List<KeyValueRow> formFields,  String body,  BodyType bodyType,  AuthConfig auth,  List<Assertion> assertions,  String? folderId,  DateTime createdAt,  DateTime updatedAt,  int order,  int schemaVersion)  $default,) {final _that = this;
switch (_that) {
case _ApiRequest():
return $default(_that.id,_that.name,_that.description,_that.method,_that.url,_that.params,_that.headers,_that.formFields,_that.body,_that.bodyType,_that.auth,_that.assertions,_that.folderId,_that.createdAt,_that.updatedAt,_that.order,_that.schemaVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String description,  HttpMethod method,  String url,  List<KeyValueRow> params,  List<KeyValueRow> headers,  List<KeyValueRow> formFields,  String body,  BodyType bodyType,  AuthConfig auth,  List<Assertion> assertions,  String? folderId,  DateTime createdAt,  DateTime updatedAt,  int order,  int schemaVersion)?  $default,) {final _that = this;
switch (_that) {
case _ApiRequest() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.method,_that.url,_that.params,_that.headers,_that.formFields,_that.body,_that.bodyType,_that.auth,_that.assertions,_that.folderId,_that.createdAt,_that.updatedAt,_that.order,_that.schemaVersion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ApiRequest implements ApiRequest {
  const _ApiRequest({required this.id, this.name = '', this.description = '', this.method = HttpMethod.get, this.url = '',  List<KeyValueRow> params = const <KeyValueRow>[],  List<KeyValueRow> headers = const <KeyValueRow>[],  List<KeyValueRow> formFields = const <KeyValueRow>[], this.body = '', this.bodyType = BodyType.none, this.auth = const AuthConfig(),  List<Assertion> assertions = const <Assertion>[], this.folderId, required this.createdAt, required this.updatedAt, this.order = 0, this.schemaVersion = 1}): _params = params,_headers = headers,_formFields = formFields,_assertions = assertions;
  factory _ApiRequest.fromJson(Map<String, dynamic> json) => _$ApiRequestFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  String description;
@override@JsonKey() final  HttpMethod method;
@override@JsonKey() final  String url;
 final  List<KeyValueRow> _params;
@override@JsonKey() List<KeyValueRow> get params {
  if (_params is EqualUnmodifiableListView) return _params;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_params);
}

 final  List<KeyValueRow> _headers;
@override@JsonKey() List<KeyValueRow> get headers {
  if (_headers is EqualUnmodifiableListView) return _headers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_headers);
}

 final  List<KeyValueRow> _formFields;
@override@JsonKey() List<KeyValueRow> get formFields {
  if (_formFields is EqualUnmodifiableListView) return _formFields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_formFields);
}

@override@JsonKey() final  String body;
@override@JsonKey() final  BodyType bodyType;
@override@JsonKey() final  AuthConfig auth;
 final  List<Assertion> _assertions;
@override@JsonKey() List<Assertion> get assertions {
  if (_assertions is EqualUnmodifiableListView) return _assertions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_assertions);
}

/// Null means the top level of Collections.
@override final  String? folderId;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
/// Order within its folder.
@override@JsonKey() final  int order;
/// Bumped whenever this shape changes. On read, an unknown version is
/// migrated or discarded; it never crashes the app.
@override@JsonKey() final  int schemaVersion;

/// Create a copy of ApiRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApiRequestCopyWith<_ApiRequest> get copyWith => __$ApiRequestCopyWithImpl<_ApiRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ApiRequestToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApiRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.method, method) || other.method == method)&&(identical(other.url, url) || other.url == url)&&const DeepCollectionEquality().equals(other.params, _params)&&const DeepCollectionEquality().equals(other.headers, _headers)&&const DeepCollectionEquality().equals(other.formFields, _formFields)&&(identical(other.body, body) || other.body == body)&&(identical(other.bodyType, bodyType) || other.bodyType == bodyType)&&(identical(other.auth, auth) || other.auth == auth)&&const DeepCollectionEquality().equals(other.assertions, _assertions)&&(identical(other.folderId, folderId) || other.folderId == folderId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.order, order) || other.order == order)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,description,method,url,const DeepCollectionEquality().hash(_params),const DeepCollectionEquality().hash(_headers),const DeepCollectionEquality().hash(_formFields),body,bodyType,auth,const DeepCollectionEquality().hash(_assertions),folderId,createdAt,updatedAt,order,schemaVersion);
}

@override
String toString() {
    return 'ApiRequest(id: $id, name: $name, description: $description, method: $method, url: $url, params: $params, headers: $headers, formFields: $formFields, body: $body, bodyType: $bodyType, auth: $auth, assertions: $assertions, folderId: $folderId, createdAt: $createdAt, updatedAt: $updatedAt, order: $order, schemaVersion: $schemaVersion)';
}


}

/// @nodoc
abstract mixin class _$ApiRequestCopyWith<$Res> implements $ApiRequestCopyWith<$Res> {
  factory _$ApiRequestCopyWith(_ApiRequest value, $Res Function(_ApiRequest) _then) = __$ApiRequestCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description, HttpMethod method, String url, List<KeyValueRow> params, List<KeyValueRow> headers, List<KeyValueRow> formFields, String body, BodyType bodyType, AuthConfig auth, List<Assertion> assertions, String? folderId, DateTime createdAt, DateTime updatedAt, int order, int schemaVersion
});


@override $AuthConfigCopyWith<$Res> get auth;

}
/// @nodoc
class __$ApiRequestCopyWithImpl<$Res>
    implements _$ApiRequestCopyWith<$Res> {
  __$ApiRequestCopyWithImpl(this._self, this._then);

  final _ApiRequest _self;
  final $Res Function(_ApiRequest) _then;

/// Create a copy of ApiRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? method = null,Object? url = null,Object? params = null,Object? headers = null,Object? formFields = null,Object? body = null,Object? bodyType = null,Object? auth = null,Object? assertions = null,Object? folderId = freezed,Object? createdAt = null,Object? updatedAt = null,Object? order = null,Object? schemaVersion = null,}) {
  return _then(_ApiRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as HttpMethod,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,params: null == params ? _self._params : params // ignore: cast_nullable_to_non_nullable
as List<KeyValueRow>,headers: null == headers ? _self._headers : headers // ignore: cast_nullable_to_non_nullable
as List<KeyValueRow>,formFields: null == formFields ? _self._formFields : formFields // ignore: cast_nullable_to_non_nullable
as List<KeyValueRow>,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,bodyType: null == bodyType ? _self.bodyType : bodyType // ignore: cast_nullable_to_non_nullable
as BodyType,auth: null == auth ? _self.auth : auth // ignore: cast_nullable_to_non_nullable
as AuthConfig,assertions: null == assertions ? _self._assertions : assertions // ignore: cast_nullable_to_non_nullable
as List<Assertion>,folderId: freezed == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of ApiRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthConfigCopyWith<$Res> get auth {
  
  return $AuthConfigCopyWith<$Res>(_self.auth, (value) {
    return _then(_self.copyWith(auth: value));
  });
}
}

// dart format on
