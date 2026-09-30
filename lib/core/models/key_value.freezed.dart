// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'key_value.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$KeyValueRow {

 String get id; String get key; String get value; String? get description; bool get enabled;/// Environment variables only: masked in the UI and left out of exports.
 bool get secret;/// Environment variables only: decides how the value is inserted.
 VarType get type;
/// Create a copy of KeyValueRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KeyValueRowCopyWith<KeyValueRow> get copyWith => _$KeyValueRowCopyWithImpl<KeyValueRow>(this as KeyValueRow, _$identity);

  /// Serializes this KeyValueRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as KeyValueRow;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KeyValueRow&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.value, _this.value) || other.value == _this.value)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.secret, _this.secret) || other.secret == _this.secret)&&(identical(other.type, _this.type) || other.type == _this.type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as KeyValueRow;
  return Object.hash(runtimeType,_this.id,_this.key,_this.value,_this.description,_this.enabled,_this.secret,_this.type);
}

@override
String toString() {
  final _this = this as KeyValueRow;
  return 'KeyValueRow(id: ${_this.id}, key: ${_this.key}, value: ${_this.value}, description: ${_this.description}, enabled: ${_this.enabled}, secret: ${_this.secret}, type: ${_this.type})';
}


}

/// @nodoc
abstract mixin class $KeyValueRowCopyWith<$Res>  {
  factory $KeyValueRowCopyWith(KeyValueRow value, $Res Function(KeyValueRow) _then) = _$KeyValueRowCopyWithImpl;
@useResult
$Res call({
 String id, String key, String value, String? description, bool enabled, bool secret, VarType type
});




}
/// @nodoc
class _$KeyValueRowCopyWithImpl<$Res>
    implements $KeyValueRowCopyWith<$Res> {
  _$KeyValueRowCopyWithImpl(this._self, this._then);

  final KeyValueRow _self;
  final $Res Function(KeyValueRow) _then;

/// Create a copy of KeyValueRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? key = null,Object? value = null,Object? description = freezed,Object? enabled = null,Object? secret = null,Object? type = null,}) {
  return _then(KeyValueRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,secret: null == secret ? _self.secret : secret // ignore: cast_nullable_to_non_nullable
as bool,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as VarType,
  ));
}

}


/// Adds pattern-matching-related methods to [KeyValueRow].
extension KeyValueRowPatterns on KeyValueRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KeyValueRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KeyValueRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KeyValueRow value)  $default,){
final _that = this;
switch (_that) {
case _KeyValueRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KeyValueRow value)?  $default,){
final _that = this;
switch (_that) {
case _KeyValueRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String key,  String value,  String? description,  bool enabled,  bool secret,  VarType type)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KeyValueRow() when $default != null:
return $default(_that.id,_that.key,_that.value,_that.description,_that.enabled,_that.secret,_that.type);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String key,  String value,  String? description,  bool enabled,  bool secret,  VarType type)  $default,) {final _that = this;
switch (_that) {
case _KeyValueRow():
return $default(_that.id,_that.key,_that.value,_that.description,_that.enabled,_that.secret,_that.type);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String key,  String value,  String? description,  bool enabled,  bool secret,  VarType type)?  $default,) {final _that = this;
switch (_that) {
case _KeyValueRow() when $default != null:
return $default(_that.id,_that.key,_that.value,_that.description,_that.enabled,_that.secret,_that.type);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _KeyValueRow implements KeyValueRow {
  const _KeyValueRow({required this.id, this.key = '', this.value = '', this.description, this.enabled = true, this.secret = false, this.type = VarType.string});
  factory _KeyValueRow.fromJson(Map<String, dynamic> json) => _$KeyValueRowFromJson(json);

@override final  String id;
@override@JsonKey() final  String key;
@override@JsonKey() final  String value;
@override final  String? description;
@override@JsonKey() final  bool enabled;
/// Environment variables only: masked in the UI and left out of exports.
@override@JsonKey() final  bool secret;
/// Environment variables only: decides how the value is inserted.
@override@JsonKey() final  VarType type;

/// Create a copy of KeyValueRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KeyValueRowCopyWith<_KeyValueRow> get copyWith => __$KeyValueRowCopyWithImpl<_KeyValueRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KeyValueRowToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _KeyValueRow&&(identical(other.id, id) || other.id == id)&&(identical(other.key, key) || other.key == key)&&(identical(other.value, value) || other.value == value)&&(identical(other.description, description) || other.description == description)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.secret, secret) || other.secret == secret)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,key,value,description,enabled,secret,type);
}

@override
String toString() {
    return 'KeyValueRow(id: $id, key: $key, value: $value, description: $description, enabled: $enabled, secret: $secret, type: $type)';
}


}

/// @nodoc
abstract mixin class _$KeyValueRowCopyWith<$Res> implements $KeyValueRowCopyWith<$Res> {
  factory _$KeyValueRowCopyWith(_KeyValueRow value, $Res Function(_KeyValueRow) _then) = __$KeyValueRowCopyWithImpl;
@override @useResult
$Res call({
 String id, String key, String value, String? description, bool enabled, bool secret, VarType type
});




}
/// @nodoc
class __$KeyValueRowCopyWithImpl<$Res>
    implements _$KeyValueRowCopyWith<$Res> {
  __$KeyValueRowCopyWithImpl(this._self, this._then);

  final _KeyValueRow _self;
  final $Res Function(_KeyValueRow) _then;

/// Create a copy of KeyValueRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? key = null,Object? value = null,Object? description = freezed,Object? enabled = null,Object? secret = null,Object? type = null,}) {
  return _then(_KeyValueRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,secret: null == secret ? _self.secret : secret // ignore: cast_nullable_to_non_nullable
as bool,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as VarType,
  ));
}


}

// dart format on
