import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitdumb/core/constants/app_constants.dart';
import 'package:splitdumb/core/utils/invite_code_generator.dart';
import 'package:splitdumb/features/groups/domain/group_member.dart';
import 'package:splitdumb/features/groups/domain/group_model.dart';
import 'package:uuid/uuid.dart';

class GroupRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  GroupRepository({
    FirebaseFirestore? firestore,
    Uuid? uuid,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = uuid ?? const Uuid();

  CollectionReference<Map<String, dynamic>> get _groupsRef =>
      _firestore.collection(AppConstants.groupsCollection);

  CollectionReference<Map<String, dynamic>> get _inviteCodesRef =>
      _firestore.collection(AppConstants.inviteCodesCollection);

  Stream<List<GroupModel>> watchUserGroups(String userId) {
    return _groupsRef
        .where('linkedUserIds', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<GroupModel?> getGroupById(String groupId) async {
    final doc = await _groupsRef.doc(groupId).get();
    if (!doc.exists) return null;
    return GroupModel.fromJson({...doc.data()!, 'id': doc.id});
  }

  Future<GroupModel> createGroup({
    required String name,
    String? description,
    required String createdBy,
    required String creatorDisplayName,
  }) async {
    final groupId = _uuid.v4();
    final memberId = _uuid.v4();
    final inviteCode = await _generateUniqueMemberInviteCode();
    final now = DateTime.now();

    final creatorMember = GroupMember(
      id: memberId,
      displayName: creatorDisplayName,
      inviteCode: inviteCode,
      linkedUserId: createdBy,
      createdAt: now,
    );

    final group = GroupModel(
      id: groupId,
      name: name,
      description: description,
      members: [creatorMember],
      linkedUserIds: [createdBy],
      createdBy: createdBy,
      createdAt: now,
    );

    final batch = _firestore.batch();

    batch.set(_groupsRef.doc(groupId), _groupToFirestore(group));

    batch.set(_inviteCodesRef.doc(inviteCode), {
      'groupId': groupId,
      'memberId': memberId,
    });

    await batch.commit();

    return group;
  }

  Future<GroupMember> addPlaceholderMember({
    required String groupId,
    required String displayName,
  }) async {
    final memberId = _uuid.v4();
    final inviteCode = await _generateUniqueMemberInviteCode();
    final now = DateTime.now();

    final member = GroupMember(
      id: memberId,
      displayName: displayName,
      inviteCode: inviteCode,
      linkedUserId: null,
      createdAt: now,
    );

    final batch = _firestore.batch();

    batch.update(_groupsRef.doc(groupId), {
      'members': FieldValue.arrayUnion([_memberToFirestore(member)]),
    });

    batch.set(_inviteCodesRef.doc(inviteCode), {
      'groupId': groupId,
      'memberId': memberId,
    });

    await batch.commit();

    return member;
  }

  Future<({GroupModel group, GroupMember member})?> claimMemberByInviteCode({
    required String inviteCode,
    required String userId,
  }) async {
    final codeDoc = await _inviteCodesRef.doc(inviteCode.toUpperCase()).get();
    if (!codeDoc.exists) return null;

    final data = codeDoc.data()!;
    final groupId = data['groupId'] as String;
    final memberId = data['memberId'] as String;

    final group = await getGroupById(groupId);
    if (group == null) return null;

    if (group.linkedUserIds.contains(userId)) {
      final existingMember = group.members.firstWhere(
        (m) => m.linkedUserId == userId,
      );
      return (group: group, member: existingMember);
    }

    final memberIndex = group.members.indexWhere((m) => m.id == memberId);
    if (memberIndex == -1) return null;

    final member = group.members[memberIndex];

    if (member.linkedUserId != null) {
      throw Exception('This invite code has already been claimed');
    }

    final updatedMember = member.copyWith(linkedUserId: userId);

    final updatedMembers = List<GroupMember>.from(group.members);
    updatedMembers[memberIndex] = updatedMember;

    await _groupsRef.doc(groupId).update({
      'members': updatedMembers.map((m) => _memberToFirestore(m)).toList(),
      'linkedUserIds': FieldValue.arrayUnion([userId]),
    });

    final updatedGroup = group.copyWith(
      members: updatedMembers,
      linkedUserIds: [...group.linkedUserIds, userId],
    );

    return (group: updatedGroup, member: updatedMember);
  }

  Future<void> leaveGroup({
    required String groupId,
    required String memberId,
    required String userId,
  }) async {
    final group = await getGroupById(groupId);
    if (group == null) return;

    final updatedMembers =
        group.members.where((m) => m.id != memberId).toList();

    final member = group.members.firstWhere(
      (m) => m.id == memberId,
      orElse: () => throw Exception('Member not found'),
    );

    final batch = _firestore.batch();

    batch.update(_groupsRef.doc(groupId), {
      'members': updatedMembers.map((m) => _memberToFirestore(m)).toList(),
      'linkedUserIds': FieldValue.arrayRemove([userId]),
    });

    batch.delete(_inviteCodesRef.doc(member.inviteCode));

    await batch.commit();
  }

  Future<void> updateGroup({
    required String groupId,
    String? name,
    String? description,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;

    if (updates.isNotEmpty) {
      await _groupsRef.doc(groupId).update(updates);
    }
  }

  Future<void> deleteGroup(String groupId) async {
    final group = await getGroupById(groupId);
    if (group == null) return;

    final batch = _firestore.batch();

    batch.delete(_groupsRef.doc(groupId));

    for (final member in group.members) {
      batch.delete(_inviteCodesRef.doc(member.inviteCode));
    }

    await batch.commit();
  }

  Future<String> _generateUniqueMemberInviteCode() async {
    String code;
    bool exists = true;

    do {
      code = InviteCodeGenerator.generate();
      final doc = await _inviteCodesRef.doc(code).get();
      exists = doc.exists;
    } while (exists);

    return code;
  }

  /// Convert GroupMember to Firestore-compatible map
  Map<String, dynamic> _memberToFirestore(GroupMember member) {
    return {
      'id': member.id,
      'displayName': member.displayName,
      'inviteCode': member.inviteCode,
      'linkedUserId': member.linkedUserId,
      'createdAt': Timestamp.fromDate(member.createdAt),
    };
  }

  /// Convert GroupModel to Firestore-compatible map with properly serialized members
  Map<String, dynamic> _groupToFirestore(GroupModel group) {
    return {
      'id': group.id,
      'name': group.name,
      'description': group.description,
      'members': group.members.map((m) => _memberToFirestore(m)).toList(),
      'linkedUserIds': group.linkedUserIds,
      'createdBy': group.createdBy,
      'createdAt': Timestamp.fromDate(group.createdAt),
    };
  }
}
