import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:splitdumb/core/extensions/context_extensions.dart';
import 'package:splitdumb/features/auth/providers/auth_providers.dart';
import 'package:splitdumb/features/expenses/domain/expense_model.dart';
import 'package:splitdumb/features/expenses/providers/expense_providers.dart';

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
    final currentUser = ref.watch(authStateProvider).valueOrNull;

    return expenseAsync.when(
      data: (expense) {
        if (expense == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Expense not found')),
          );
        }

        final isCreator = expense.paidBy == currentUser?.uid;
        final dateFormat = DateFormat.yMMMMd();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Expense Details'),
            actions: [
              if (isCreator)
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
                            expense.paidBy.substring(0, 1).toUpperCase(),
                          ),
                        ),
                        title: Text(isCreator ? 'You' : 'Member'),
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
                        final isCurrentUser = entry.key == currentUser?.uid;
                        final isPayer = entry.key == expense.paidBy;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor:
                                context.colorScheme.secondaryContainer,
                            child: Text(
                              entry.key.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                color:
                                    context.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                          title: Text(isCurrentUser ? 'You' : 'Member'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${entry.value.toStringAsFixed(2)}',
                                style: context.textTheme.titleSmall,
                              ),
                              if (isPayer)
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
