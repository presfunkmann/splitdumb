import 'package:flutter_riverpod/flutter_riverpod.dart';
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

// Calculate what a user owes/is owed in a specific group (using member IDs)
final groupBalanceProvider =
    FutureProvider.family<double, String>((ref, groupId) async {
  final currentMember = ref.watch(currentUserMemberProvider(groupId));
  if (currentMember == null) return 0;

  final expensesAsync = ref.watch(groupExpensesProvider(groupId));
  final settlementsAsync = ref.watch(groupSettlementsProvider(groupId));

  final expenses = expensesAsync.valueOrNull ?? [];
  final settlements = settlementsAsync.valueOrNull ?? [];

  double balance = 0;
  final memberId = currentMember.id;

  // Calculate from expenses
  for (final expense in expenses) {
    // How much did this user pay?
    final amountPaid = expense.paidBy[memberId] ?? 0.0;
    // How much does this user owe (their split)?
    final amountOwed = expense.splits[memberId] ?? 0.0;
    // Net contribution: paid - owed
    // Positive means they're owed by others, negative means they owe
    balance += (amountPaid - amountOwed);
  }

  // Adjust for settlements
  for (final settlement in settlements) {
    if (settlement.fromUser == memberId) {
      // User paid someone
      balance += settlement.amount;
    } else if (settlement.toUser == memberId) {
      // User received payment
      balance -= settlement.amount;
    }
  }

  return balance;
});

// Calculate detailed balances between all members in a group
final groupMemberBalancesProvider =
    FutureProvider.family<Map<String, double>, String>((ref, groupId) async {
  final currentMember = ref.watch(currentUserMemberProvider(groupId));
  if (currentMember == null) return {};

  final groupAsync = ref.watch(groupByIdProvider(groupId));
  final group = groupAsync.valueOrNull;
  if (group == null) return {};

  final expensesAsync = ref.watch(groupExpensesProvider(groupId));
  final settlementsAsync = ref.watch(groupSettlementsProvider(groupId));

  final expenses = expensesAsync.valueOrNull ?? [];
  final settlements = settlementsAsync.valueOrNull ?? [];

  final memberId = currentMember.id;

  // Track balance between current user and each member
  // Positive = they owe you, Negative = you owe them
  final balances = <String, double>{};

  for (final member in group.members) {
    if (member.id != memberId) {
      balances[member.id] = 0;
    }
  }

  // Calculate from expenses
  for (final expense in expenses) {
    // For each payer in this expense
    for (final payerEntry in expense.paidBy.entries) {
      final payerId = payerEntry.key;
      final amountPaid = payerEntry.value;
      final payerShare = expense.splits[payerId] ?? 0.0;
      final netContribution = amountPaid - payerShare;

      if (payerId == memberId) {
        // Current user paid more than their share - others owe them proportionally
        if (netContribution > 0.01) {
          final othersTotal = expense.splits.entries
              .where((e) => e.key != memberId)
              .fold(0.0, (sum, e) => sum + e.value);

          for (final splitEntry in expense.splits.entries) {
            if (splitEntry.key != memberId &&
                balances.containsKey(splitEntry.key)) {
              final proportion =
                  othersTotal > 0 ? splitEntry.value / othersTotal : 0.0;
              balances[splitEntry.key] =
                  (balances[splitEntry.key] ?? 0) + (netContribution * proportion);
            }
          }
        }
      } else if (balances.containsKey(payerId)) {
        // Someone else paid more than their share - current user may owe them
        if (netContribution > 0.01) {
          final userShare = expense.splits[memberId] ?? 0.0;
          final othersTotal = expense.splits.entries
              .where((e) => e.key != payerId)
              .fold(0.0, (sum, e) => sum + e.value);

          if (userShare > 0 && othersTotal > 0) {
            final proportion = userShare / othersTotal;
            balances[payerId] =
                (balances[payerId] ?? 0) - (netContribution * proportion);
          }
        }
      }
    }
  }

  // Adjust for settlements
  for (final settlement in settlements) {
    if (settlement.fromUser == memberId &&
        balances.containsKey(settlement.toUser)) {
      // User paid this person
      balances[settlement.toUser] =
          (balances[settlement.toUser] ?? 0) + settlement.amount;
    } else if (settlement.toUser == memberId &&
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

// Simplified debts - who owes whom and how much (using member IDs)
class DebtInfo {
  final String fromUserId; // This is actually member ID now
  final String toUserId; // This is actually member ID now
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

  final memberIds = group.members.map((m) => m.id).toList();

  // Build a balance matrix
  // balances[from][to] = amount that 'from' owes 'to'
  final balances = <String, Map<String, double>>{};

  for (final memberId in memberIds) {
    balances[memberId] = {};
    for (final otherId in memberIds) {
      if (memberId != otherId) {
        balances[memberId]![otherId] = 0;
      }
    }
  }

  // Calculate from expenses
  for (final expense in expenses) {
    // For each payer in this expense
    for (final payerEntry in expense.paidBy.entries) {
      final payerId = payerEntry.key;
      final amountPaid = payerEntry.value;
      final payerShare = expense.splits[payerId] ?? 0.0;
      final netContribution = amountPaid - payerShare;

      if (netContribution > 0.01) {
        // This payer covered more than their share - others owe them
        final othersTotal = expense.splits.entries
            .where((e) => e.key != payerId)
            .fold(0.0, (sum, e) => sum + e.value);

        for (final splitEntry in expense.splits.entries) {
          if (splitEntry.key != payerId &&
              balances.containsKey(splitEntry.key)) {
            final proportion =
                othersTotal > 0 ? splitEntry.value / othersTotal : 0.0;
            final owedAmount = netContribution * proportion;
            balances[splitEntry.key]![payerId] =
                (balances[splitEntry.key]![payerId] ?? 0) + owedAmount;
          }
        }
      }
    }
  }

  // Adjust for settlements
  for (final settlement in settlements) {
    if (balances.containsKey(settlement.fromUser) &&
        balances[settlement.fromUser]!.containsKey(settlement.toUser)) {
      // fromUser paid toUser, so reduce what fromUser owes toUser
      balances[settlement.fromUser]![settlement.toUser] =
          (balances[settlement.fromUser]![settlement.toUser] ?? 0) -
              settlement.amount;
    }
  }

  // Simplify debts - net out mutual debts
  final debts = <DebtInfo>[];

  for (final from in memberIds) {
    for (final to in memberIds) {
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
