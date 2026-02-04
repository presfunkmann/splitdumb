import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:splitdumb/core/extensions/context_extensions.dart';
import 'package:splitdumb/features/balances/providers/balance_providers.dart';
import 'package:splitdumb/features/expenses/domain/expense_model.dart';
import 'package:splitdumb/features/expenses/providers/expense_providers.dart';
import 'package:splitdumb/features/groups/domain/group_model.dart';
import 'package:splitdumb/features/groups/providers/group_providers.dart';
import 'package:intl/intl.dart';

class GroupDetailScreen extends ConsumerWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupByIdProvider(groupId));
    final expensesAsync = ref.watch(groupExpensesProvider(groupId));
    final balancesAsync = ref.watch(groupMemberBalancesProvider(groupId));
    final currentMember = ref.watch(currentUserMemberProvider(groupId));

    return groupAsync.when(
      data: (group) {
        if (group == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Group not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(group.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _showInviteCodes(context, group, currentMember?.inviteCode),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'settings',
                    child: ListTile(
                      leading: Icon(Icons.settings),
                      title: Text('Settings'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'balances',
                    child: ListTile(
                      leading: Icon(Icons.account_balance_wallet),
                      title: Text('Balances'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'leave',
                    child: ListTile(
                      leading: Icon(Icons.exit_to_app, color: Colors.red),
                      title: Text('Leave Group',
                          style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'settings':
                      context.push('/groups/$groupId/settings');
                      break;
                    case 'balances':
                      context.push('/groups/$groupId/balances');
                      break;
                    case 'leave':
                      if (currentMember != null) {
                        _confirmLeaveGroup(context, ref, group, currentMember.id);
                      }
                      break;
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: [
              _buildBalancesSummary(context, balancesAsync, group),
              Expanded(
                child: expensesAsync.when(
                  data: (expenses) {
                    if (expenses.isEmpty) {
                      return _buildEmptyState(context);
                    }
                    return _buildExpensesList(context, ref, expenses, group, currentMember?.id);
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('Error: $error')),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/groups/$groupId/expenses/add'),
            icon: const Icon(Icons.add),
            label: const Text('Add Expense'),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildBalancesSummary(
    BuildContext context,
    AsyncValue<Map<String, double>> balancesAsync,
    GroupModel group,
  ) {
    return balancesAsync.when(
      data: (balances) {
        if (balances.isEmpty) return const SizedBox.shrink();

        // Helper to get member display name
        String getMemberName(String memberId) {
          try {
            final member = group.members.firstWhere(
              (m) => m.id == memberId,
            );
            return member.displayName;
          } catch (_) {
            return 'Member';
          }
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerHighest.withAlpha(80),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 18,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Member Balances',
                      style: context.textTheme.titleSmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push('/groups/$groupId/balances'),
                    icon: const Icon(Icons.handshake_outlined, size: 18),
                    label: const Text('Settle Up'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: balances.entries.map((entry) {
                  final isPositive = entry.value >= 0;
                  final memberName = getMemberName(entry.key);
                  final isSettled = entry.value == 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSettled
                          ? context.colorScheme.surface
                          : (isPositive ? Colors.green : Colors.red).withAlpha(15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSettled
                            ? context.colorScheme.outlineVariant.withAlpha(80)
                            : (isPositive ? Colors.green : Colors.red).withAlpha(40),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: context.colorScheme.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              memberName.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: context.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              memberName,
                              style: context.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              isSettled
                                  ? 'Settled'
                                  : '${isPositive ? '+' : ''}\$${entry.value.abs().toStringAsFixed(2)}',
                              style: context.textTheme.labelSmall?.copyWith(
                                color: isSettled
                                    ? context.colorScheme.onSurfaceVariant
                                    : (isPositive ? Colors.green.shade700 : Colors.red.shade700),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No expenses yet',
              style: context.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first expense to start\nsplitting costs with your group',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.push('/groups/$groupId/expenses/add'),
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesList(
    BuildContext context,
    WidgetRef ref,
    List<ExpenseModel> expenses,
    GroupModel group,
    String? currentMemberId,
  ) {
    final dateFormat = DateFormat.yMMMd();
    final groupedExpenses = <String, List<ExpenseModel>>{};

    for (final expense in expenses) {
      final dateKey = dateFormat.format(expense.date);
      groupedExpenses.putIfAbsent(dateKey, () => []).add(expense);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: groupedExpenses.length,
      itemBuilder: (context, index) {
        final date = groupedExpenses.keys.elementAt(index);
        final dayExpenses = groupedExpenses[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                date,
                style: context.textTheme.labelLarge?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ...dayExpenses.map((expense) => _ExpenseCard(
                  expense: expense,
                  groupId: groupId,
                  group: group,
                  currentMemberId: currentMemberId,
                )),
          ],
        );
      },
    );
  }

  void _showInviteCodes(BuildContext context, GroupModel group, String? myInviteCode) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Share Invite Codes',
                  style: context.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Each member has their own invite code. Go to Settings to see all member codes or add new members.',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (myInviteCode != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Your Invite Code',
                    style: context.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: context.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      myInviteCode,
                      style: context.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: context.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: myInviteCode));
                      Navigator.pop(context);
                      context.showSnackBar('Your invite code copied!');
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy My Code'),
                  ),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/groups/${group.id}/settings');
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Manage Members'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmLeaveGroup(
      BuildContext context, WidgetRef ref, GroupModel group, String memberId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Leave Group?'),
          content: Text('Are you sure you want to leave ${group.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: context.colorScheme.error,
              ),
              onPressed: () async {
                Navigator.pop(context);
                await ref
                    .read(groupNotifierProvider.notifier)
                    .leaveGroup(groupId: group.id, memberId: memberId);
                if (context.mounted) {
                  context.go('/');
                }
              },
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final String groupId;
  final GroupModel group;
  final String? currentMemberId;

  const _ExpenseCard({
    required this.expense,
    required this.groupId,
    required this.group,
    required this.currentMemberId,
  });

  @override
  Widget build(BuildContext context) {
    final userPaid = expense.paidBy[currentMemberId] ?? 0.0;
    final userShare = expense.splits[currentMemberId] ?? 0.0;
    final userNetBalance = userPaid - userShare;
    final isPayer = userPaid > 0;

    // Get payer text for display
    String getPayerText() {
      if (expense.hasMultiplePayers) {
        if (isPayer) {
          final otherCount = expense.paidBy.length - 1;
          return otherCount > 0 ? 'You + $otherCount others paid' : 'You paid';
        } else {
          return '${expense.paidBy.length} people paid';
        }
      } else {
        if (isPayer) {
          return 'You paid';
        }
        try {
          final member = group.members.firstWhere(
            (m) => m.id == expense.primaryPayer,
          );
          return 'Paid by ${member.displayName}';
        } catch (_) {
          return 'Paid by someone';
        }
      }
    }

    final categoryColor = _getCategoryColor(expense.category);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => context.push('/groups/$groupId/expenses/${expense.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: categoryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(expense.category),
                  color: categoryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.description,
                      style: context.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      getPayerText(),
                      style: context.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${expense.amount.toStringAsFixed(2)}',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (userNetBalance >= 0 ? Colors.green : Colors.red).withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      userNetBalance >= 0
                          ? '+\$${userNetBalance.toStringAsFixed(2)}'
                          : '-\$${userNetBalance.abs().toStringAsFixed(2)}',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: userNetBalance >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'shopping':
        return Icons.shopping_bag;
      case 'utilities':
        return Icons.bolt;
      case 'rent':
        return Icons.home;
      default:
        return Icons.receipt_long;
    }
  }

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'food':
        return const Color(0xFFF97316); // Orange
      case 'transport':
        return const Color(0xFF3B82F6); // Blue
      case 'entertainment':
        return const Color(0xFF8B5CF6); // Violet
      case 'shopping':
        return const Color(0xFFEC4899); // Pink
      case 'utilities':
        return const Color(0xFFF59E0B); // Amber
      case 'rent':
        return const Color(0xFF0D9488); // Teal
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }
}
