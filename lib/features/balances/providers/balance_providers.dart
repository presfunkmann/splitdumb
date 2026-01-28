import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitdumb/features/auth/providers/auth_providers.dart';
import 'package:splitdumb/features/balances/data/settlement_repository.dart';
import 'package:splitdumb/features/balances/domain/settlement_model.dart';
import 'package:splitdumb/features/expenses/providers/expense_providers.dart';
import 'package:splitdumb/features/groups/providers/group_providers.dart';

final settlementRepositoryProvider = Provider<SettlementRepository>((ref) {
  return SettlementRepository();
});

final groupSettlementsProvider =
    StreamProvider.family<List<SettlementModel>, String>((ref, groupId) {
  return ref.watch(settlementRepositoryProvider).watchGroupSettlements(groupId);
});

// Calculate what a user owes/is owed in a specific group
final groupBalanceProvider =
    FutureProvider.family<double, String>((ref, groupId) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return 0;

  final expensesAsync = ref.watch(groupExpensesProvider(groupId));
  final settlementsAsync = ref.watch(groupSettlementsProvider(groupId));

  final expenses = expensesAsync.valueOrNull ?? [];
  final settlements = settlementsAsync.valueOrNull ?? [];

  double balance = 0;

  // Calculate from expenses
  for (final expense in expenses) {
    if (expense.paidBy == user.uid) {
      // User paid, they are owed by others
      final totalOwed = expense.splits.entries
          .where((e) => e.key != user.uid)
          .fold(0.0, (sum, e) => sum + e.value);
      balance += totalOwed;
    } else {
      // User owes the payer
      final userShare = expense.splits[user.uid] ?? 0;
      balance -= userShare;
    }
  }

  // Adjust for settlements
  for (final settlement in settlements) {
    if (settlement.fromUser == user.uid) {
      // User paid someone
      balance += settlement.amount;
    } else if (settlement.toUser == user.uid) {
      // User received payment
      balance -= settlement.amount;
    }
  }

  return balance;
});

// Calculate detailed balances between all members in a group
final groupMemberBalancesProvider =
    FutureProvider.family<Map<String, double>, String>((ref, groupId) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return {};

  final groupAsync = ref.watch(groupByIdProvider(groupId));
  final group = groupAsync.valueOrNull;
  if (group == null) return {};

  final expensesAsync = ref.watch(groupExpensesProvider(groupId));
  final settlementsAsync = ref.watch(groupSettlementsProvider(groupId));

  final expenses = expensesAsync.valueOrNull ?? [];
  final settlements = settlementsAsync.valueOrNull ?? [];

  // Track balance between current user and each member
  // Positive = they owe you, Negative = you owe them
  final balances = <String, double>{};

  for (final memberId in group.memberIds) {
    if (memberId != user.uid) {
      balances[memberId] = 0;
    }
  }

  // Calculate from expenses
  for (final expense in expenses) {
    if (expense.paidBy == user.uid) {
      // User paid - each member owes their share
      for (final entry in expense.splits.entries) {
        if (entry.key != user.uid && balances.containsKey(entry.key)) {
          balances[entry.key] = (balances[entry.key] ?? 0) + entry.value;
        }
      }
    } else if (balances.containsKey(expense.paidBy)) {
      // Someone else paid - user owes their share
      final userShare = expense.splits[user.uid] ?? 0;
      balances[expense.paidBy] = (balances[expense.paidBy] ?? 0) - userShare;
    }
  }

  // Adjust for settlements
  for (final settlement in settlements) {
    if (settlement.fromUser == user.uid &&
        balances.containsKey(settlement.toUser)) {
      // User paid this person
      balances[settlement.toUser] =
          (balances[settlement.toUser] ?? 0) + settlement.amount;
    } else if (settlement.toUser == user.uid &&
        balances.containsKey(settlement.fromUser)) {
      // This person paid user
      balances[settlement.fromUser] =
          (balances[settlement.fromUser] ?? 0) - settlement.amount;
    }
  }

  return balances;
});

// Overall balance across all groups
final overallBalanceProvider = FutureProvider<double>((ref) async {
  final groupsAsync = ref.watch(userGroupsProvider);
  final groups = groupsAsync.valueOrNull ?? [];

  double totalBalance = 0;

  for (final group in groups) {
    final groupBalance = await ref.watch(groupBalanceProvider(group.id).future);
    totalBalance += groupBalance;
  }

  return totalBalance;
});

// Simplified debts - who owes whom and how much
class DebtInfo {
  final String fromUserId;
  final String toUserId;
  final double amount;

  DebtInfo({
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
  });
}

final groupDebtsProvider =
    FutureProvider.family<List<DebtInfo>, String>((ref, groupId) async {
  final groupAsync = ref.watch(groupByIdProvider(groupId));
  final group = groupAsync.valueOrNull;
  if (group == null) return [];

  final expensesAsync = ref.watch(groupExpensesProvider(groupId));
  final settlementsAsync = ref.watch(groupSettlementsProvider(groupId));

  final expenses = expensesAsync.valueOrNull ?? [];
  final settlements = settlementsAsync.valueOrNull ?? [];

  // Build a balance matrix
  // balances[from][to] = amount that 'from' owes 'to'
  final balances = <String, Map<String, double>>{};

  for (final memberId in group.memberIds) {
    balances[memberId] = {};
    for (final otherId in group.memberIds) {
      if (memberId != otherId) {
        balances[memberId]![otherId] = 0;
      }
    }
  }

  // Calculate from expenses
  for (final expense in expenses) {
    final payer = expense.paidBy;
    for (final entry in expense.splits.entries) {
      if (entry.key != payer) {
        // entry.key owes payer entry.value
        balances[entry.key]![payer] =
            (balances[entry.key]![payer] ?? 0) + entry.value;
      }
    }
  }

  // Adjust for settlements
  for (final settlement in settlements) {
    // fromUser paid toUser, so reduce what fromUser owes toUser
    balances[settlement.fromUser]![settlement.toUser] =
        (balances[settlement.fromUser]![settlement.toUser] ?? 0) -
            settlement.amount;
  }

  // Simplify debts - net out mutual debts
  final debts = <DebtInfo>[];

  for (final from in group.memberIds) {
    for (final to in group.memberIds) {
      if (from.compareTo(to) < 0) {
        final fromOwesTo = balances[from]![to] ?? 0;
        final toOwesFrom = balances[to]![from] ?? 0;
        final netDebt = fromOwesTo - toOwesFrom;

        if (netDebt > 0.01) {
          debts.add(DebtInfo(fromUserId: from, toUserId: to, amount: netDebt));
        } else if (netDebt < -0.01) {
          debts.add(
              DebtInfo(fromUserId: to, toUserId: from, amount: netDebt.abs()));
        }
      }
    }
  }

  return debts;
});

class SettlementNotifier extends StateNotifier<AsyncValue<SettlementModel?>> {
  final SettlementRepository _repository;

  SettlementNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<SettlementModel?> createSettlement({
    required String groupId,
    required String fromUser,
    required String toUser,
    required double amount,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      return await _repository.createSettlement(
        groupId: groupId,
        fromUser: fromUser,
        toUser: toUser,
        amount: amount,
      );
    });

    return state.valueOrNull;
  }

  Future<void> deleteSettlement(String settlementId) async {
    await _repository.deleteSettlement(settlementId);
    state = const AsyncValue.data(null);
  }
}

final settlementNotifierProvider =
    StateNotifierProvider<SettlementNotifier, AsyncValue<SettlementModel?>>(
        (ref) {
  return SettlementNotifier(ref.watch(settlementRepositoryProvider));
});
