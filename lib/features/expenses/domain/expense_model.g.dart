// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExpenseEdit _$ExpenseEditFromJson(Map<String, dynamic> json) => _ExpenseEdit(
  editedBy: json['editedBy'] as String,
  editedAt: const TimestampConverter().fromJson(json['editedAt']),
  description: json['description'] as String,
  amount: (json['amount'] as num).toDouble(),
  paidBy: json['paidBy'] as String,
  splitType: $enumDecode(_$SplitTypeEnumMap, json['splitType']),
  splits: (json['splits'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, (e as num).toDouble()),
  ),
  category: json['category'] as String?,
);

Map<String, dynamic> _$ExpenseEditToJson(_ExpenseEdit instance) =>
    <String, dynamic>{
      'editedBy': instance.editedBy,
      'editedAt': const TimestampConverter().toJson(instance.editedAt),
      'description': instance.description,
      'amount': instance.amount,
      'paidBy': instance.paidBy,
      'splitType': _$SplitTypeEnumMap[instance.splitType]!,
      'splits': instance.splits,
      'category': instance.category,
    };

const _$SplitTypeEnumMap = {
  SplitType.equal: 'equal',
  SplitType.exact: 'exact',
  SplitType.percentage: 'percentage',
};

_ExpenseModel _$ExpenseModelFromJson(Map<String, dynamic> json) =>
    _ExpenseModel(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      paidBy: json['paidBy'] as String,
      splitType: $enumDecode(_$SplitTypeEnumMap, json['splitType']),
      splits: (json['splits'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      category: json['category'] as String?,
      date: const TimestampConverter().fromJson(json['date']),
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      editHistory:
          (json['editHistory'] as List<dynamic>?)
              ?.map((e) => ExpenseEdit.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ExpenseModelToJson(_ExpenseModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'groupId': instance.groupId,
      'description': instance.description,
      'amount': instance.amount,
      'paidBy': instance.paidBy,
      'splitType': _$SplitTypeEnumMap[instance.splitType]!,
      'splits': instance.splits,
      'category': instance.category,
      'date': const TimestampConverter().toJson(instance.date),
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'editHistory': instance.editHistory,
    };
