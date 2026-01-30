import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitdumb/features/auth/providers/auth_providers.dart';
import 'package:splitdumb/features/groups/data/group_repository.dart';
import 'package:splitdumb/features/groups/domain/group_member.dart';
import 'package:splitdumb/features/groups/domain/group_model.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository();
});

final userGroupsProvider = StreamProvider<List<GroupModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return ref.watch(groupRepositoryProvider).watchUserGroups(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

final groupByIdProvider =
    FutureProvider.family<GroupModel?, String>((ref, groupId) async {
  return ref.watch(groupRepositoryProvider).getGroupById(groupId);
});

final selectedGroupProvider = StateProvider<GroupModel?>((ref) => null);

/// Get the current user's member record in a specific group
final currentUserMemberProvider =
    Provider.family<GroupMember?, String>((ref, groupId) {
  final groupAsync = ref.watch(groupByIdProvider(groupId));
  final user = ref.watch(authStateProvider).valueOrNull;

  if (user == null) return null;

  final group = groupAsync.valueOrNull;
  if (group == null) return null;

  try {
    return group.members.firstWhere(
      (m) => m.linkedUserId == user.uid,
    );
  } catch (_) {
    return null;
  }
});

/// Lookup a member's display name by their member ID within a group
final memberDisplayNameProvider =
    Provider.family<String, ({String groupId, String memberId})>(
        (ref, params) {
  final groupAsync = ref.watch(groupByIdProvider(params.groupId));
  final group = groupAsync.valueOrNull;

  if (group == null) return 'Member';

  try {
    final member = group.members.firstWhere(
      (m) => m.id == params.memberId,
    );
    return member.displayName;
  } catch (_) {
    return 'Member';
  }
});

class GroupNotifier extends StateNotifier<AsyncValue<GroupModel?>> {
  final GroupRepository _repository;
  final Ref _ref;

  GroupNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  Future<GroupModel?> createGroup({
    required String name,
    String? description,
  }) async {
    state = const AsyncValue.loading();
    final authState = _ref.read(authStateProvider);
    final user = authState.valueOrNull;
    if (user == null) {
      state = AsyncValue.error('Not authenticated', StackTrace.current);
      return null;
    }

    state = await AsyncValue.guard(() async {
      return await _repository.createGroup(
        name: name,
        description: description,
        createdBy: user.uid,
        creatorDisplayName: user.displayName ?? user.email ?? 'User',
      );
    });

    return state.valueOrNull;
  }

  Future<GroupModel?> claimMemberByInviteCode(String inviteCode) async {
    state = const AsyncValue.loading();
    final authState = _ref.read(authStateProvider);
    final user = authState.valueOrNull;
    if (user == null) {
      state = AsyncValue.error('Not authenticated', StackTrace.current);
      return null;
    }

    state = await AsyncValue.guard(() async {
      final result = await _repository.claimMemberByInviteCode(
        inviteCode: inviteCode,
        userId: user.uid,
      );
      if (result == null) {
        throw Exception('Invalid invite code');
      }
      return result.group;
    });

    return state.valueOrNull;
  }

  Future<GroupMember?> addPlaceholderMember({
    required String groupId,
    required String displayName,
  }) async {
    try {
      final member = await _repository.addPlaceholderMember(
        groupId: groupId,
        displayName: displayName,
      );
      _ref.invalidate(groupByIdProvider(groupId));
      return member;
    } catch (e) {
      return null;
    }
  }

  Future<void> leaveGroup({
    required String groupId,
    required String memberId,
  }) async {
    final authState = _ref.read(authStateProvider);
    final user = authState.valueOrNull;
    if (user == null) return;

    await _repository.leaveGroup(
      groupId: groupId,
      memberId: memberId,
      userId: user.uid,
    );
  }

  Future<void> updateGroup({
    required String groupId,
    String? name,
    String? description,
  }) async {
    await _repository.updateGroup(
      groupId: groupId,
      name: name,
      description: description,
    );
  }

  Future<void> deleteGroup(String groupId) async {
    await _repository.deleteGroup(groupId);
  }
}

final groupNotifierProvider =
    StateNotifierProvider<GroupNotifier, AsyncValue<GroupModel?>>((ref) {
  return GroupNotifier(
    ref.watch(groupRepositoryProvider),
    ref,
  );
});
