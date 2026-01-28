import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitdumb/features/auth/providers/auth_providers.dart';
import 'package:splitdumb/features/expenses/data/expense_repository.dart';
import 'package:splitdumb/features/expenses/domain/expense_model.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository();
});

final groupExpensesProvider =
    StreamProvider.family<List<ExpenseModel>, String>((ref, groupId) {
  return ref.watch(expenseRepositoryProvider).watchGroupExpenses(groupId);
});

final expenseByIdProvider =
    FutureProvider.family<ExpenseModel?, String>((ref, expenseId) async {
  return ref.watch(expenseRepositoryProvider).getExpenseById(expenseId);
});

class ExpenseNotifier extends StateNotifier<AsyncValue<ExpenseModel?>> {
  final ExpenseRepository _repository;
  final Ref _ref;

  ExpenseNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  Future<ExpenseModel?> createExpense({
    required String groupId,
    required String description,
    required double amount,
    required SplitType splitType,
    required Map<String, double> splits,
    String? category,
    DateTime? date,
  }) async {
    state = const AsyncValue.loading();
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      state = AsyncValue.error('Not authenticated', StackTrace.current);
      return null;
    }

    state = await AsyncValue.guard(() async {
      return await _repository.createExpense(
        groupId: groupId,
        description: description,
        amount: amount,
        paidBy: user.uid,
        splitType: splitType,
        splits: splits,
        category: category,
        date: date,
      );
    });

    return state.valueOrNull;
  }

  Future<ExpenseModel?> createExpenseWithPayer({
    required String groupId,
    required String description,
    required double amount,
    required String paidBy,
    required SplitType splitType,
    required Map<String, double> splits,
    String? category,
    DateTime? date,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      return await _repository.createExpense(
        groupId: groupId,
        description: description,
        amount: amount,
        paidBy: paidBy,
        splitType: splitType,
        splits: splits,
        category: category,
        date: date,
      );
    });

    return state.valueOrNull;
  }

  Future<ExpenseModel?> updateExpense({
    required String expenseId,
    String? description,
    double? amount,
    String? paidBy,
    SplitType? splitType,
    Map<String, double>? splits,
    String? category,
    DateTime? date,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      return await _repository.updateExpense(
        expenseId: expenseId,
        description: description,
        amount: amount,
        paidBy: paidBy,
        splitType: splitType,
        splits: splits,
        category: category,
        date: date,
      );
    });

    return state.valueOrNull;
  }

  Future<void> deleteExpense(String expenseId) async {
    await _repository.deleteExpense(expenseId);
    state = const AsyncValue.data(null);
  }
}

final expenseNotifierProvider =
    StateNotifierProvider<ExpenseNotifier, AsyncValue<ExpenseModel?>>((ref) {
  return ExpenseNotifier(
    ref.watch(expenseRepositoryProvider),
    ref,
  );
});

// Split calculation helpers
class SplitCalculator {
  static Map<String, double> calculateEqualSplit(
    double amount,
    List<String> memberIds,
  ) {
    final perPerson = amount / memberIds.length;
    return {for (final id in memberIds) id: perPerson};
  }

  static Map<String, double> calculatePercentageSplit(
    double amount,
    Map<String, double> percentages,
  ) {
    return percentages.map(
      (id, percentage) => MapEntry(id, amount * (percentage / 100)),
    );
  }

  static bool validateSplits(
    double amount,
    Map<String, double> splits,
    SplitType splitType,
  ) {
    if (splits.isEmpty) return false;

    final total = splits.values.reduce((a, b) => a + b);

    switch (splitType) {
      case SplitType.equal:
      case SplitType.exact:
        return (total - amount).abs() < 0.01;
      case SplitType.percentage:
        return (total - 100).abs() < 0.01;
    }
  }
}
