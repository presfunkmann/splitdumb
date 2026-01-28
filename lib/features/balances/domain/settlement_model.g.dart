// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settlement_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SettlementModel _$SettlementModelFromJson(Map<String, dynamic> json) =>
    _SettlementModel(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      fromUser: json['fromUser'] as String,
      toUser: json['toUser'] as String,
      amount: (json['amount'] as num).toDouble(),
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
    );

Map<String, dynamic> _$SettlementModelToJson(_SettlementModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'groupId': instance.groupId,
      'fromUser': instance.fromUser,
      'toUser': instance.toUser,
      'amount': instance.amount,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
    };
