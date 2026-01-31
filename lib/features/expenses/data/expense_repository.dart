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
      editHistory: [],
    );

    await _expensesRef.doc(id).set(_expenseToFirestore(expense));
    return expense;
  }

  Future<ExpenseModel> updateExpense({
    required String expenseId,
    required String editedBy,
    String? description,
    double? amount,
    String? paidBy,
    SplitType? splitType,
    Map<String, double>? splits,
    String? category,
    DateTime? date,
  }) async {
    // Fetch current expense to save history
    final currentExpense = await getExpenseById(expenseId);
    if (currentExpense == null) {
      throw Exception('Expense not found');
    }

    // Create history entry with current values
    final historyEntry = ExpenseEdit(
      editedBy: editedBy,
      editedAt: DateTime.now(),
      description: currentExpense.description,
      amount: currentExpense.amount,
      paidBy: currentExpense.paidBy,
      splitType: currentExpense.splitType,
      splits: currentExpense.splits,
      category: currentExpense.category,
    );

    // Build updated expense
    final updatedExpense = currentExpense.copyWith(
      description: description ?? currentExpense.description,
      amount: amount ?? currentExpense.amount,
      paidBy: paidBy ?? currentExpense.paidBy,
      splitType: splitType ?? currentExpense.splitType,
      splits: splits ?? currentExpense.splits,
      category: category ?? currentExpense.category,
      date: date ?? currentExpense.date,
      editHistory: [...currentExpense.editHistory, historyEntry],
    );

    await _expensesRef.doc(expenseId).set(_expenseToFirestore(updatedExpense));
    return updatedExpense;
  }

  Future<void> deleteExpense(String expenseId) async {
    await _expensesRef.doc(expenseId).delete();
  }

  /// Convert ExpenseEdit to Firestore-compatible map
  Map<String, dynamic> _expenseEditToFirestore(ExpenseEdit edit) {
    return {
      'editedBy': edit.editedBy,
      'editedAt': Timestamp.fromDate(edit.editedAt),
      'description': edit.description,
      'amount': edit.amount,
      'paidBy': edit.paidBy,
      'splitType': edit.splitType.name,
      'splits': edit.splits,
      'category': edit.category,
    };
  }

  /// Convert ExpenseModel to Firestore-compatible map
  Map<String, dynamic> _expenseToFirestore(ExpenseModel expense) {
    return {
      'id': expense.id,
      'groupId': expense.groupId,
      'description': expense.description,
      'amount': expense.amount,
      'paidBy': expense.paidBy,
      'splitType': expense.splitType.name,
      'splits': expense.splits,
      'category': expense.category,
      'date': Timestamp.fromDate(expense.date),
      'createdAt': Timestamp.fromDate(expense.createdAt),
      'editHistory': expense.editHistory
          .map((e) => _expenseEditToFirestore(e))
          .toList(),
    };
  }
}
