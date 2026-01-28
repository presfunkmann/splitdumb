import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitdumb/core/constants/app_constants.dart';
import 'package:splitdumb/features/balances/domain/settlement_model.dart';
import 'package:uuid/uuid.dart';

class SettlementRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  SettlementRepository({
    FirebaseFirestore? firestore,
    Uuid? uuid,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = uuid ?? const Uuid();

  CollectionReference<Map<String, dynamic>> get _settlementsRef =>
      _firestore.collection(AppConstants.settlementsCollection);

  Stream<List<SettlementModel>> watchGroupSettlements(String groupId) {
    return _settlementsRef
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                SettlementModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<List<SettlementModel>> getGroupSettlements(String groupId) async {
    final snapshot = await _settlementsRef
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => SettlementModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<SettlementModel> createSettlement({
    required String groupId,
    required String fromUser,
    required String toUser,
    required double amount,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    final settlement = SettlementModel(
      id: id,
      groupId: groupId,
      fromUser: fromUser,
      toUser: toUser,
      amount: amount,
      createdAt: now,
    );

    await _settlementsRef.doc(id).set(settlement.toJson());
    return settlement;
  }

  Future<void> deleteSettlement(String settlementId) async {
    await _settlementsRef.doc(settlementId).delete();
  }
}
