import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:splitdumb/core/extensions/context_extensions.dart';
import 'package:splitdumb/features/expenses/domain/expense_model.dart';
import 'package:splitdumb/features/expenses/providers/expense_providers.dart';
import 'package:splitdumb/features/groups/providers/group_providers.dart';

class ExpenseDetailScreen extends ConsumerWidget {
  final String groupId;
  final String expenseId;

  const ExpenseDetailScreen({
    super.key,
    required this.groupId,
    required this.expenseId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseAsync = ref.watch(expenseByIdProvider(expenseId));
    final groupAsync = ref.watch(groupByIdProvider(groupId));
    final currentMember = ref.watch(currentUserMemberProvider(groupId));

    return expenseAsync.when(
      data: (expense) {
        if (expense == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Expense not found')),
          );
        }

        final group = groupAsync.valueOrNull;
        final currentMemberId = currentMember?.id;
        final isPayer = expense.paidBy == currentMemberId;
        final dateFormat = DateFormat.yMMMMd();

        // Helper to get member display name
        String getMemberName(String memberId) {
          if (group == null) return 'Member';
          try {
            final member = group.members.firstWhere(
              (m) => m.id == memberId,
            );
            return member.displayName;
          } catch (_) {
            return 'Member';
          }
        }

        final payerName = getMemberName(expense.paidBy);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Expense Details'),
            actions: [
              // Anyone in the group can edit/delete
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title:
                          Text('Delete', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      context.push(
                          '/groups/$groupId/expenses/$expenseId/edit');
                      break;
                    case 'delete':
                      _confirmDelete(context, ref, expense);
                      break;
                  }
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        '\$${expense.amount.toStringAsFixed(2)}',
                        style: context.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        expense.description,
                        style: context.textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(expense.date),
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (expense.category != null) ...[
                        const SizedBox(height: 12),
                        Chip(
                          label: Text(expense.category!),
                          avatar: Icon(
                            _getCategoryIcon(expense.category),
                            size: 18,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paid by',
                        style: context.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          child: Text(
                            payerName.substring(0, 1).toUpperCase(),
                          ),
                        ),
                        title: Text(isPayer ? 'You ($payerName)' : payerName),
                        trailing: Text(
                          '\$${expense.amount.toStringAsFixed(2)}',
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Split Details',
                            style: context.textTheme.titleMedium,
                          ),
                          Chip(
                            label: Text(_getSplitTypeLabel(expense.splitType)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...expense.splits.entries.map((entry) {
                        final memberName = getMemberName(entry.key);
                        final isCurrentUser = entry.key == currentMemberId;
                        final isMemberPayer = entry.key == expense.paidBy;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor:
                                context.colorScheme.secondaryContainer,
                            child: Text(
                              memberName.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                color:
                                    context.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                          title: Text(isCurrentUser ? 'You ($memberName)' : memberName),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${entry.value.toStringAsFixed(2)}',
                                style: context.textTheme.titleSmall,
                              ),
                              if (isMemberPayer)
                                Text(
                                  'Gets back \$${(expense.amount - entry.value).toStringAsFixed(2)}',
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: Colors.green,
                                  ),
                                )
                              else
                                Text(
                                  'Owes',
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: Colors.red,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Info',
                        style: context.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        context,
                        'Created',
                        DateFormat.yMMMd().add_jm().format(expense.createdAt),
                      ),
                    ],
                  ),
                ),
              ),
              // Edit History Section
              if (expense.editHistory.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.history,
                              size: 20,
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Edit History',
                              style: context.textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...expense.editHistory.reversed.map((edit) {
                          return _buildEditHistoryEntry(
                            context,
                            edit,
                            expense,
                            getMemberName,
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ],
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

  Widget _buildEditHistoryEntry(
    BuildContext context,
    ExpenseEdit edit,
    ExpenseModel currentExpense,
    String Function(String) getMemberName,
  ) {
    final editedByName = getMemberName(edit.editedBy);
    final dateFormat = DateFormat.yMMMd().add_jm();

    // Find what changed by comparing to next state
    // Since history stores previous values, we compare to see what was changed
    final changes = <String>[];

    // Find the index of this edit in history
    final editIndex = currentExpense.editHistory.indexOf(edit);

    // The "after" values are either the next edit's previous values, or current expense values
    String afterDescription;
    double afterAmount;
    String afterPaidBy;
    String? afterCategory;

    if (editIndex == currentExpense.editHistory.length - 1) {
      // This is the most recent edit, compare to current values
      afterDescription = currentExpense.description;
      afterAmount = currentExpense.amount;
      afterPaidBy = currentExpense.paidBy;
      afterCategory = currentExpense.category;
    } else {
      // Get the next edit's "before" values (which is what this edit changed TO)
      final nextEdit = currentExpense.editHistory[editIndex + 1];
      afterDescription = nextEdit.description;
      afterAmount = nextEdit.amount;
      afterPaidBy = nextEdit.paidBy;
      afterCategory = nextEdit.category;
    }

    if (edit.description != afterDescription) {
      changes.add('Description: "${edit.description}" → "$afterDescription"');
    }
    if (edit.amount != afterAmount) {
      changes.add('Amount: \$${edit.amount.toStringAsFixed(2)} → \$${afterAmount.toStringAsFixed(2)}');
    }
    if (edit.paidBy != afterPaidBy) {
      changes.add('Payer: ${getMemberName(edit.paidBy)} → ${getMemberName(afterPaidBy)}');
    }
    if (edit.category != afterCategory) {
      final oldCat = edit.category ?? 'None';
      final newCat = afterCategory ?? 'None';
      changes.add('Category: $oldCat → $newCat');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest.withAlpha(50),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: context.colorScheme.primary,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateFormat.format(edit.editedAt),
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Edited by $editedByName',
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          if (changes.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...changes.map((change) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: context.colorScheme.primary)),
                  Expanded(
                    child: Text(
                      change,
                      style: context.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: context.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  String _getSplitTypeLabel(SplitType type) {
    switch (type) {
      case SplitType.equal:
        return 'Equal Split';
      case SplitType.exact:
        return 'Exact Amounts';
      case SplitType.percentage:
        return 'By Percentage';
    }
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

  void _confirmDelete(
      BuildContext context, WidgetRef ref, ExpenseModel expense) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Expense?'),
          content: Text(
            'Are you sure you want to delete "${expense.description}"?',
          ),
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
                    .read(expenseNotifierProvider.notifier)
                    .deleteExpense(expense.id);
                if (context.mounted) {
                  context.pop();
                  context.showSnackBar('Expense deleted');
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
