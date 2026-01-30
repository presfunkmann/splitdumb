import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:splitdumb/features/auth/domain/user_model.dart';

part 'group_member.freezed.dart';
part 'group_member.g.dart';

@freezed
abstract class GroupMember with _$GroupMember {
  const factory GroupMember({
    required String id,
    required String displayName,
    required String inviteCode,
    String? linkedUserId,
    @TimestampConverter() required DateTime createdAt,
  }) = _GroupMember;

  factory GroupMember.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberFromJson(json);
}
