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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerHighest.withAlpha(50),
            border: Border(
              bottom: BorderSide(
                color: context.colorScheme.outlineVariant,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Member Balances',
                style: context.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: balances.entries.map((entry) {
                  final isPositive = entry.value >= 0;
                  final memberName = getMemberName(entry.key);
                  return Chip(
                    label: Text(
                      '${isPositive ? '+' : ''}\$${entry.value.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                        color: entry.value == 0
                            ? null
                            : (isPositive ? Colors.green : Colors.red),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    avatar: CircleAvatar(
                      backgroundColor: context.colorScheme.primaryContainer,
                      child: Text(
                        memberName.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
      loading: () => const LinearProgressIndicator(),
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
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: context.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No expenses yet',
              style: context.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first expense to start splitting',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
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
    final isPayer = expense.paidBy == currentMemberId;
    final userShare = expense.splits[currentMemberId] ?? 0;

    // Get payer's display name
    String getPayerName() {
      try {
        final member = group.members.firstWhere(
          (m) => m.id == expense.paidBy,
        );
        return member.displayName;
      } catch (_) {
        return 'Someone';
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => context.push('/groups/$groupId/expenses/${expense.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    _getCategoryColor(expense.category).withAlpha(50),
                child: Icon(
                  _getCategoryIcon(expense.category),
                  color: _getCategoryColor(expense.category),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.description,
                      style: context.textTheme.titleMedium,
                    ),
                    Text(
                      isPayer ? 'You paid' : 'Paid by ${getPayerName()}',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${expense.amount.toStringAsFixed(2)}',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isPayer)
                    Text(
                      'You get \$${(expense.amount - userShare).toStringAsFixed(2)}',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                      ),
                    )
                  else
                    Text(
                      'You owe \$${userShare.toStringAsFixed(2)}',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: Colors.red,
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
        return Colors.orange;
      case 'transport':
        return Colors.blue;
      case 'entertainment':
        return Colors.purple;
      case 'shopping':
        return Colors.pink;
      case 'utilities':
        return Colors.yellow.shade700;
      case 'rent':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
