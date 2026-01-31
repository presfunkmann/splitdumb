// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'expense_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExpenseEdit {

 String get editedBy;@TimestampConverter() DateTime get editedAt; String get description; double get amount; String get paidBy; SplitType get splitType; Map<String, double> get splits; String? get category;
/// Create a copy of ExpenseEdit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExpenseEditCopyWith<ExpenseEdit> get copyWith => _$ExpenseEditCopyWithImpl<ExpenseEdit>(this as ExpenseEdit, _$identity);

  /// Serializes this ExpenseEdit to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExpenseEdit&&(identical(other.editedBy, editedBy) || other.editedBy == editedBy)&&(identical(other.editedAt, editedAt) || other.editedAt == editedAt)&&(identical(other.description, description) || other.description == description)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.paidBy, paidBy) || other.paidBy == paidBy)&&(identical(other.splitType, splitType) || other.splitType == splitType)&&const DeepCollectionEquality().equals(other.splits, splits)&&(identical(other.category, category) || other.category == category));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,editedBy,editedAt,description,amount,paidBy,splitType,const DeepCollectionEquality().hash(splits),category);

@override
String toString() {
  return 'ExpenseEdit(editedBy: $editedBy, editedAt: $editedAt, description: $description, amount: $amount, paidBy: $paidBy, splitType: $splitType, splits: $splits, category: $category)';
}


}

/// @nodoc
abstract mixin class $ExpenseEditCopyWith<$Res>  {
  factory $ExpenseEditCopyWith(ExpenseEdit value, $Res Function(ExpenseEdit) _then) = _$ExpenseEditCopyWithImpl;
@useResult
$Res call({
 String editedBy,@TimestampConverter() DateTime editedAt, String description, double amount, String paidBy, SplitType splitType, Map<String, double> splits, String? category
});




}
/// @nodoc
class _$ExpenseEditCopyWithImpl<$Res>
    implements $ExpenseEditCopyWith<$Res> {
  _$ExpenseEditCopyWithImpl(this._self, this._then);

  final ExpenseEdit _self;
  final $Res Function(ExpenseEdit) _then;

/// Create a copy of ExpenseEdit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? editedBy = null,Object? editedAt = null,Object? description = null,Object? amount = null,Object? paidBy = null,Object? splitType = null,Object? splits = null,Object? category = freezed,}) {
  return _then(_self.copyWith(
editedBy: null == editedBy ? _self.editedBy : editedBy // ignore: cast_nullable_to_non_nullable
as String,editedAt: null == editedAt ? _self.editedAt : editedAt // ignore: cast_nullable_to_non_nullable
as DateTime,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,paidBy: null == paidBy ? _self.paidBy : paidBy // ignore: cast_nullable_to_non_nullable
as String,splitType: null == splitType ? _self.splitType : splitType // ignore: cast_nullable_to_non_nullable
as SplitType,splits: null == splits ? _self.splits : splits // ignore: cast_nullable_to_non_nullable
as Map<String, double>,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ExpenseEdit].
extension ExpenseEditPatterns on ExpenseEdit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExpenseEdit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExpenseEdit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExpenseEdit value)  $default,){
final _that = this;
switch (_that) {
case _ExpenseEdit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExpenseEdit value)?  $default,){
final _that = this;
switch (_that) {
case _ExpenseEdit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String editedBy, @TimestampConverter()  DateTime editedAt,  String description,  double amount,  String paidBy,  SplitType splitType,  Map<String, double> splits,  String? category)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExpenseEdit() when $default != null:
return $default(_that.editedBy,_that.editedAt,_that.description,_that.amount,_that.paidBy,_that.splitType,_that.splits,_that.category);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String editedBy, @TimestampConverter()  DateTime editedAt,  String description,  double amount,  String paidBy,  SplitType splitType,  Map<String, double> splits,  String? category)  $default,) {final _that = this;
switch (_that) {
case _ExpenseEdit():
return $default(_that.editedBy,_that.editedAt,_that.description,_that.amount,_that.paidBy,_that.splitType,_that.splits,_that.category);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String editedBy, @TimestampConverter()  DateTime editedAt,  String description,  double amount,  String paidBy,  SplitType splitType,  Map<String, double> splits,  String? category)?  $default,) {final _that = this;
switch (_that) {
case _ExpenseEdit() when $default != null:
return $default(_that.editedBy,_that.editedAt,_that.description,_that.amount,_that.paidBy,_that.splitType,_that.splits,_that.category);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExpenseEdit implements ExpenseEdit {
  const _ExpenseEdit({required this.editedBy, @TimestampConverter() required this.editedAt, required this.description, required this.amount, required this.paidBy, required this.splitType, required final  Map<String, double> splits, this.category}): _splits = splits;
  factory _ExpenseEdit.fromJson(Map<String, dynamic> json) => _$ExpenseEditFromJson(json);

@override final  String editedBy;
@override@TimestampConverter() final  DateTime editedAt;
@override final  String description;
@override final  double amount;
@override final  String paidBy;
@override final  SplitType splitType;
 final  Map<String, double> _splits;
@override Map<String, double> get splits {
  if (_splits is EqualUnmodifiableMapView) return _splits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_splits);
}

@override final  String? category;

/// Create a copy of ExpenseEdit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExpenseEditCopyWith<_ExpenseEdit> get copyWith => __$ExpenseEditCopyWithImpl<_ExpenseEdit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExpenseEditToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExpenseEdit&&(identical(other.editedBy, editedBy) || other.editedBy == editedBy)&&(identical(other.editedAt, editedAt) || other.editedAt == editedAt)&&(identical(other.description, description) || other.description == description)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.paidBy, paidBy) || other.paidBy == paidBy)&&(identical(other.splitType, splitType) || other.splitType == splitType)&&const DeepCollectionEquality().equals(other._splits, _splits)&&(identical(other.category, category) || other.category == category));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,editedBy,editedAt,description,amount,paidBy,splitType,const DeepCollectionEquality().hash(_splits),category);

@override
String toString() {
  return 'ExpenseEdit(editedBy: $editedBy, editedAt: $editedAt, description: $description, amount: $amount, paidBy: $paidBy, splitType: $splitType, splits: $splits, category: $category)';
}


}

/// @nodoc
abstract mixin class _$ExpenseEditCopyWith<$Res> implements $ExpenseEditCopyWith<$Res> {
  factory _$ExpenseEditCopyWith(_ExpenseEdit value, $Res Function(_ExpenseEdit) _then) = __$ExpenseEditCopyWithImpl;
@override @useResult
$Res call({
 String editedBy,@TimestampConverter() DateTime editedAt, String description, double amount, String paidBy, SplitType splitType, Map<String, double> splits, String? category
});




}
/// @nodoc
class __$ExpenseEditCopyWithImpl<$Res>
    implements _$ExpenseEditCopyWith<$Res> {
  __$ExpenseEditCopyWithImpl(this._self, this._then);

  final _ExpenseEdit _self;
  final $Res Function(_ExpenseEdit) _then;

/// Create a copy of ExpenseEdit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? editedBy = null,Object? editedAt = null,Object? description = null,Object? amount = null,Object? paidBy = null,Object? splitType = null,Object? splits = null,Object? category = freezed,}) {
  return _then(_ExpenseEdit(
editedBy: null == editedBy ? _self.editedBy : editedBy // ignore: cast_nullable_to_non_nullable
as String,editedAt: null == editedAt ? _self.editedAt : editedAt // ignore: cast_nullable_to_non_nullable
as DateTime,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,paidBy: null == paidBy ? _self.paidBy : paidBy // ignore: cast_nullable_to_non_nullable
as String,splitType: null == splitType ? _self.splitType : splitType // ignore: cast_nullable_to_non_nullable
as SplitType,splits: null == splits ? _self._splits : splits // ignore: cast_nullable_to_non_nullable
as Map<String, double>,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ExpenseModel {

 String get id; String get groupId; String get description; double get amount; String get paidBy; SplitType get splitType; Map<String, double> get splits; String? get category;@TimestampConverter() DateTime get date;@TimestampConverter() DateTime get createdAt; List<ExpenseEdit> get editHistory;
/// Create a copy of ExpenseModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExpenseModelCopyWith<ExpenseModel> get copyWith => _$ExpenseModelCopyWithImpl<ExpenseModel>(this as ExpenseModel, _$identity);

  /// Serializes this ExpenseModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExpenseModel&&(identical(other.id, id) || other.id == id)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.description, description) || other.description == description)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.paidBy, paidBy) || other.paidBy == paidBy)&&(identical(other.splitType, splitType) || other.splitType == splitType)&&const DeepCollectionEquality().equals(other.splits, splits)&&(identical(other.category, category) || other.category == category)&&(identical(other.date, date) || other.date == date)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.editHistory, editHistory));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,groupId,description,amount,paidBy,splitType,const DeepCollectionEquality().hash(splits),category,date,createdAt,const DeepCollectionEquality().hash(editHistory));

@override
String toString() {
  return 'ExpenseModel(id: $id, groupId: $groupId, description: $description, amount: $amount, paidBy: $paidBy, splitType: $splitType, splits: $splits, category: $category, date: $date, createdAt: $createdAt, editHistory: $editHistory)';
}


}

/// @nodoc
abstract mixin class $ExpenseModelCopyWith<$Res>  {
  factory $ExpenseModelCopyWith(ExpenseModel value, $Res Function(ExpenseModel) _then) = _$ExpenseModelCopyWithImpl;
@useResult
$Res call({
 String id, String groupId, String description, double amount, String paidBy, SplitType splitType, Map<String, double> splits, String? category,@TimestampConverter() DateTime date,@TimestampConverter() DateTime createdAt, List<ExpenseEdit> editHistory
});




}
/// @nodoc
class _$ExpenseModelCopyWithImpl<$Res>
    implements $ExpenseModelCopyWith<$Res> {
  _$ExpenseModelCopyWithImpl(this._self, this._then);

  final ExpenseModel _self;
  final $Res Function(ExpenseModel) _then;

/// Create a copy of ExpenseModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? groupId = null,Object? description = null,Object? amount = null,Object? paidBy = null,Object? splitType = null,Object? splits = null,Object? category = freezed,Object? date = null,Object? createdAt = null,Object? editHistory = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,paidBy: null == paidBy ? _self.paidBy : paidBy // ignore: cast_nullable_to_non_nullable
as String,splitType: null == splitType ? _self.splitType : splitType // ignore: cast_nullable_to_non_nullable
as SplitType,splits: null == splits ? _self.splits : splits // ignore: cast_nullable_to_non_nullable
as Map<String, double>,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,editHistory: null == editHistory ? _self.editHistory : editHistory // ignore: cast_nullable_to_non_nullable
as List<ExpenseEdit>,
  ));
}

}


/// Adds pattern-matching-related methods to [ExpenseModel].
extension ExpenseModelPatterns on ExpenseModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExpenseModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExpenseModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExpenseModel value)  $default,){
final _that = this;
switch (_that) {
case _ExpenseModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExpenseModel value)?  $default,){
final _that = this;
switch (_that) {
case _ExpenseModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String groupId,  String description,  double amount,  String paidBy,  SplitType splitType,  Map<String, double> splits,  String? category, @TimestampConverter()  DateTime date, @TimestampConverter()  DateTime createdAt,  List<ExpenseEdit> editHistory)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExpenseModel() when $default != null:
return $default(_that.id,_that.groupId,_that.description,_that.amount,_that.paidBy,_that.splitType,_that.splits,_that.category,_that.date,_that.createdAt,_that.editHistory);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String groupId,  String description,  double amount,  String paidBy,  SplitType splitType,  Map<String, double> splits,  String? category, @TimestampConverter()  DateTime date, @TimestampConverter()  DateTime createdAt,  List<ExpenseEdit> editHistory)  $default,) {final _that = this;
switch (_that) {
case _ExpenseModel():
return $default(_that.id,_that.groupId,_that.description,_that.amount,_that.paidBy,_that.splitType,_that.splits,_that.category,_that.date,_that.createdAt,_that.editHistory);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String groupId,  String description,  double amount,  String paidBy,  SplitType splitType,  Map<String, double> splits,  String? category, @TimestampConverter()  DateTime date, @TimestampConverter()  DateTime createdAt,  List<ExpenseEdit> editHistory)?  $default,) {final _that = this;
switch (_that) {
case _ExpenseModel() when $default != null:
return $default(_that.id,_that.groupId,_that.description,_that.amount,_that.paidBy,_that.splitType,_that.splits,_that.category,_that.date,_that.createdAt,_that.editHistory);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExpenseModel implements ExpenseModel {
  const _ExpenseModel({required this.id, required this.groupId, required this.description, required this.amount, required this.paidBy, required this.splitType, required final  Map<String, double> splits, this.category, @TimestampConverter() required this.date, @TimestampConverter() required this.createdAt, final  List<ExpenseEdit> editHistory = const []}): _splits = splits,_editHistory = editHistory;
  factory _ExpenseModel.fromJson(Map<String, dynamic> json) => _$ExpenseModelFromJson(json);

@override final  String id;
@override final  String groupId;
@override final  String description;
@override final  double amount;
@override final  String paidBy;
@override final  SplitType splitType;
 final  Map<String, double> _splits;
@override Map<String, double> get splits {
  if (_splits is EqualUnmodifiableMapView) return _splits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_splits);
}

@override final  String? category;
@override@TimestampConverter() final  DateTime date;
@override@TimestampConverter() final  DateTime createdAt;
 final  List<ExpenseEdit> _editHistory;
@override@JsonKey() List<ExpenseEdit> get editHistory {
  if (_editHistory is EqualUnmodifiableListView) return _editHistory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_editHistory);
}


/// Create a copy of ExpenseModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExpenseModelCopyWith<_ExpenseModel> get copyWith => __$ExpenseModelCopyWithImpl<_ExpenseModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExpenseModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExpenseModel&&(identical(other.id, id) || other.id == id)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.description, description) || other.description == description)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.paidBy, paidBy) || other.paidBy == paidBy)&&(identical(other.splitType, splitType) || other.splitType == splitType)&&const DeepCollectionEquality().equals(other._splits, _splits)&&(identical(other.category, category) || other.category == category)&&(identical(other.date, date) || other.date == date)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other._editHistory, _editHistory));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,groupId,description,amount,paidBy,splitType,const DeepCollectionEquality().hash(_splits),category,date,createdAt,const DeepCollectionEquality().hash(_editHistory));

@override
String toString() {
  return 'ExpenseModel(id: $id, groupId: $groupId, description: $description, amount: $amount, paidBy: $paidBy, splitType: $splitType, splits: $splits, category: $category, date: $date, createdAt: $createdAt, editHistory: $editHistory)';
}


}

/// @nodoc
abstract mixin class _$ExpenseModelCopyWith<$Res> implements $ExpenseModelCopyWith<$Res> {
  factory _$ExpenseModelCopyWith(_ExpenseModel value, $Res Function(_ExpenseModel) _then) = __$ExpenseModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String groupId, String description, double amount, String paidBy, SplitType splitType, Map<String, double> splits, String? category,@TimestampConverter() DateTime date,@TimestampConverter() DateTime createdAt, List<ExpenseEdit> editHistory
});




}
/// @nodoc
class __$ExpenseModelCopyWithImpl<$Res>
    implements _$ExpenseModelCopyWith<$Res> {
  __$ExpenseModelCopyWithImpl(this._self, this._then);

  final _ExpenseModel _self;
  final $Res Function(_ExpenseModel) _then;

/// Create a copy of ExpenseModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? groupId = null,Object? description = null,Object? amount = null,Object? paidBy = null,Object? splitType = null,Object? splits = null,Object? category = freezed,Object? date = null,Object? createdAt = null,Object? editHistory = null,}) {
  return _then(_ExpenseModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,paidBy: null == paidBy ? _self.paidBy : paidBy // ignore: cast_nullable_to_non_nullable
as String,splitType: null == splitType ? _self.splitType : splitType // ignore: cast_nullable_to_non_nullable
as SplitType,splits: null == splits ? _self._splits : splits // ignore: cast_nullable_to_non_nullable
as Map<String, double>,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,editHistory: null == editHistory ? _self._editHistory : editHistory // ignore: cast_nullable_to_non_nullable
as List<ExpenseEdit>,
  ));
}


}

// dart format on
