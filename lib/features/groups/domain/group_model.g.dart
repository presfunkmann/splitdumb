// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GroupModel _$GroupModelFromJson(Map<String, dynamic> json) => _GroupModel(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  members: (json['members'] as List<dynamic>)
      .map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
      .toList(),
  linkedUserIds: (json['linkedUserIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  createdBy: json['createdBy'] as String,
  createdAt: const TimestampConverter().fromJson(json['createdAt']),
);

Map<String, dynamic> _$GroupModelToJson(_GroupModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'members': instance.members,
      'linkedUserIds': instance.linkedUserIds,
      'createdBy': instance.createdBy,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
    };
