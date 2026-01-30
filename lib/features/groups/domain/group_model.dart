import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:splitdumb/features/auth/domain/user_model.dart';
import 'package:splitdumb/features/groups/domain/group_member.dart';

part 'group_model.freezed.dart';
part 'group_model.g.dart';

@freezed
abstract class GroupModel with _$GroupModel {
  const factory GroupModel({
    required String id,
    required String name,
    String? description,
    required List<GroupMember> members,
    required List<String> linkedUserIds,
    required String createdBy,
    @TimestampConverter() required DateTime createdAt,
  }) = _GroupModel;

  factory GroupModel.fromJson(Map<String, dynamic> json) =>
      _$GroupModelFromJson(json);
}
