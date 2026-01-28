import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitdumb/core/extensions/context_extensions.dart';
import 'package:splitdumb/features/auth/providers/auth_providers.dart';
import 'package:splitdumb/features/balances/providers/balance_providers.dart';
import 'package:splitdumb/features/groups/providers/group_providers.dart';

class GroupBalancesScreen extends ConsumerWidget {
  final String groupId;

  const GroupBalancesScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupByIdProvider(groupId));
    final debtsAsync = ref.watch(groupDebtsProvider(groupId));
    final currentUser = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Balances'),
      ),
      body: groupAsync.when(
        data: (group) {
          if (group == null) {
            return const Center(child: Text('Group not found'));
          }

          return debtsAsync.when(
            data: (debts) {
              if (debts.isEmpty) {
                return _buildSettledState(context);
              }

              // Separate into you owe and you are owed
              final youOwe = debts
                  .where((d) => d.fromUserId == currentUser?.uid)
                  .toList();
              final youAreOwed = debts
                  .where((d) => d.toUserId == currentUser?.uid)
                  .toList();
              final otherDebts = debts
                  .where((d) =>
                      d.fromUserId != currentUser?.uid &&
                      d.toUserId != currentUser?.uid)
                  .toList();

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (youOwe.isNotEmpty) ...[
                    _buildSectionHeader(context, 'You Owe', Colors.red),
                    ...youOwe.map((debt) => _buildDebtCard(
                          context,
                          ref,
                          debt,
                          isYouOwe: true,
                        )),
                    const SizedBox(height: 24),
                  ],
                  if (youAreOwed.isNotEmpty) ...[
                    _buildSectionHeader(context, 'You Are Owed', Colors.green),
                    ...youAreOwed.map((debt) => _buildDebtCard(
                          context,
                          ref,
                          debt,
                          isYouOwe: false,
                        )),
                    const SizedBox(height: 24),
                  ],
                  if (otherDebts.isNotEmpty) ...[
                    _buildSectionHeader(
                        context, 'Other Balances', Colors.grey),
                    ...otherDebts.map((debt) => _buildOtherDebtCard(
                          context,
                          debt,
                        )),
                  ],
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildSettledState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'All settled up!',
              style: context.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'No outstanding balances in this group',
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

  Widget _buildSectionHeader(
      BuildContext context, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtCard(
    BuildContext context,
    WidgetRef ref,
    DebtInfo debt, {
    required bool isYouOwe,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isYouOwe
                  ? Colors.red.withAlpha(30)
                  : Colors.green.withAlpha(30),
              child: Icon(
                isYouOwe ? Icons.arrow_upward : Icons.arrow_downward,
                color: isYouOwe ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isYouOwe ? 'You owe' : 'Owes you',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Member',
                    style: context.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${debt.amount.toStringAsFixed(2)}',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isYouOwe ? Colors.red : Colors.green,
                  ),
                ),
                if (isYouOwe)
                  TextButton(
                    onPressed: () => _showSettleDialog(
                      context,
                      ref,
                      debt,
                    ),
                    child: const Text('Settle'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherDebtCard(BuildContext context, DebtInfo debt) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: context.colorScheme.surfaceContainerHighest.withAlpha(50),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: context.colorScheme.surfaceContainerHighest,
              child: Text(
                debt.fromUserId.substring(0, 1).toUpperCase(),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 16),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: context.colorScheme.surfaceContainerHighest,
              child: Text(
                debt.toUserId.substring(0, 1).toUpperCase(),
              ),
            ),
            const Spacer(),
            Text(
              '\$${debt.amount.toStringAsFixed(2)}',
              style: context.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  void _showSettleDialog(
    BuildContext context,
    WidgetRef ref,
    DebtInfo debt,
  ) {
    final amountController =
        TextEditingController(text: debt.amount.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Record Settlement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('How much are you paying?'),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '\$ ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  context.showSnackBar('Please enter a valid amount',
                      isError: true);
                  return;
                }

                Navigator.pop(context);
                await ref
                    .read(settlementNotifierProvider.notifier)
                    .createSettlement(
                      groupId: groupId,
                      fromUser: debt.fromUserId,
                      toUser: debt.toUserId,
                      amount: amount,
                    );

                if (context.mounted) {
                  context.showSnackBar('Settlement recorded!');
                }
              },
              child: const Text('Record'),
            ),
          ],
        );
      },
    );
  }
}
