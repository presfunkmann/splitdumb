import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitdumb/features/auth/providers/auth_providers.dart';
import 'package:splitdumb/features/groups/data/group_repository.dart';
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
      );
    });

    return state.valueOrNull;
  }

  Future<GroupModel?> joinGroupByCode(String inviteCode) async {
    state = const AsyncValue.loading();
    final authState = _ref.read(authStateProvider);
    final user = authState.valueOrNull;
    if (user == null) {
      state = AsyncValue.error('Not authenticated', StackTrace.current);
      return null;
    }

    state = await AsyncValue.guard(() async {
      final group = await _repository.getGroupByInviteCode(inviteCode);
      if (group == null) {
        throw Exception('Invalid invite code');
      }

      if (group.memberIds.contains(user.uid)) {
        return group;
      }

      return await _repository.joinGroup(
        groupId: group.id,
        userId: user.uid,
      );
    });

    return state.valueOrNull;
  }

  Future<void> leaveGroup(String groupId) async {
    final authState = _ref.read(authStateProvider);
    final user = authState.valueOrNull;
    if (user == null) return;

    await _repository.leaveGroup(
      groupId: groupId,
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
