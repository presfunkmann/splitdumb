import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitdumb/core/constants/app_constants.dart';
import 'package:splitdumb/features/expenses/domain/expense_model.dart';
import 'package:uuid/uuid.dart';

class ExpenseRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  ExpenseRepository({
    FirebaseFirestore? firestore,
    Uuid? uuid,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = uuid ?? const Uuid();

  CollectionReference<Map<String, dynamic>> get _expensesRef =>
      _firestore.collection(AppConstants.expensesCollection);

  Stream<List<ExpenseModel>> watchGroupExpenses(String groupId) {
    return _expensesRef
        .where('groupId', isEqualTo: groupId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExpenseModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<ExpenseModel?> getExpenseById(String expenseId) async {
    final doc = await _expensesRef.doc(expenseId).get();
    if (!doc.exists) return null;
    return ExpenseModel.fromJson({...doc.data()!, 'id': doc.id});
  }

  Future<List<ExpenseModel>> getGroupExpenses(String groupId) async {
    final snapshot = await _expensesRef
        .where('groupId', isEqualTo: groupId)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ExpenseModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<ExpenseModel> createExpense({
    required String groupId,
    required String description,
    required double amount,
    required String paidBy,
    required SplitType splitType,
    required Map<String, double> splits,
    String? category,
    DateTime? date,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    final expense = ExpenseModel(
      id: id,
      groupId: groupId,
      description: description,
      amount: amount,
      paidBy: paidBy,
      splitType: splitType,
      splits: splits,
      category: category,
      date: date ?? now,
      createdAt: now,
    );

    await _expensesRef.doc(id).set(expense.toJson());
    return expense;
  }

  Future<ExpenseModel> updateExpense({
    required String expenseId,
    String? description,
    double? amount,
    String? paidBy,
    SplitType? splitType,
    Map<String, double>? splits,
    String? category,
    DateTime? date,
  }) async {
    final updates = <String, dynamic>{};
    if (description != null) updates['description'] = description;
    if (amount != null) updates['amount'] = amount;
    if (paidBy != null) updates['paidBy'] = paidBy;
    if (splitType != null) updates['splitType'] = splitType.name;
    if (splits != null) updates['splits'] = splits;
    if (category != null) updates['category'] = category;
    if (date != null) updates['date'] = Timestamp.fromDate(date);

    await _expensesRef.doc(expenseId).update(updates);
    return (await getExpenseById(expenseId))!;
  }

  Future<void> deleteExpense(String expenseId) async {
    await _expensesRef.doc(expenseId).delete();
  }
}
