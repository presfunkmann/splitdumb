// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GroupMember _$GroupMemberFromJson(Map<String, dynamic> json) => _GroupMember(
  id: json['id'] as String,
  displayName: json['displayName'] as String,
  inviteCode: json['inviteCode'] as String,
  linkedUserId: json['linkedUserId'] as String?,
  createdAt: const TimestampConverter().fromJson(json['createdAt']),
);

Map<String, dynamic> _$GroupMemberToJson(_GroupMember instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'inviteCode': instance.inviteCode,
      'linkedUserId': instance.linkedUserId,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
    };
