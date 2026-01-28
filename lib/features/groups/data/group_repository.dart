import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitdumb/core/constants/app_constants.dart';
import 'package:splitdumb/core/utils/invite_code_generator.dart';
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

  Stream<List<GroupModel>> watchUserGroups(String userId) {
    return _groupsRef
        .where('memberIds', arrayContains: userId)
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

  Future<GroupModel?> getGroupByInviteCode(String inviteCode) async {
    final snapshot = await _groupsRef
        .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return GroupModel.fromJson({...doc.data(), 'id': doc.id});
  }

  Future<GroupModel> createGroup({
    required String name,
    String? description,
    required String createdBy,
  }) async {
    final id = _uuid.v4();
    final inviteCode = await _generateUniqueInviteCode();

    final group = GroupModel(
      id: id,
      name: name,
      description: description,
      memberIds: [createdBy],
      createdBy: createdBy,
      inviteCode: inviteCode,
      createdAt: DateTime.now(),
    );

    await _groupsRef.doc(id).set(group.toJson());
    return group;
  }

  Future<GroupModel> joinGroup({
    required String groupId,
    required String userId,
  }) async {
    await _groupsRef.doc(groupId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
    });

    final group = await getGroupById(groupId);
    return group!;
  }

  Future<void> leaveGroup({
    required String groupId,
    required String userId,
  }) async {
    await _groupsRef.doc(groupId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
    });
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
    await _groupsRef.doc(groupId).delete();
  }

  Future<String> _generateUniqueInviteCode() async {
    String code;
    bool exists = true;

    do {
      code = InviteCodeGenerator.generate();
      final snapshot = await _groupsRef
          .where('inviteCode', isEqualTo: code)
          .limit(1)
          .get();
      exists = snapshot.docs.isNotEmpty;
    } while (exists);

    return code;
  }
}
