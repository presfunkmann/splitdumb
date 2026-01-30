import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:splitdumb/core/constants/app_constants.dart';
import 'package:splitdumb/core/extensions/context_extensions.dart';
import 'package:splitdumb/features/auth/providers/auth_providers.dart';
import 'package:splitdumb/features/balances/providers/balance_providers.dart';
import 'package:splitdumb/features/groups/domain/group_model.dart';
import 'package:splitdumb/features/groups/providers/group_providers.dart';

class GroupsListScreen extends ConsumerWidget {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(userGroupsProvider);
    final overallBalance = ref.watch(overallBalanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outlined),
            onPressed: () => _showProfileMenu(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildBalanceSummary(context, overallBalance),
          Expanded(
            child: groupsAsync.when(
              data: (groups) {
                if (groups.isEmpty) {
                  return _buildEmptyState(context);
                }
                return _buildGroupsList(context, groups);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'join',
            onPressed: () => _showJoinGroupDialog(context, ref),
            child: const Icon(Icons.group_add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'create',
            onPressed: () => context.push('/groups/create'),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSummary(
      BuildContext context, AsyncValue<double> balanceAsync) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: balanceAsync.when(
          data: (balance) {
            final isPositive = balance >= 0;
            return Column(
              children: [
                Text(
                  'Overall Balance',
                  style: context.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${isPositive ? '+' : ''}\$${balance.abs().toStringAsFixed(2)}',
                  style: context.textTheme.headlineMedium?.copyWith(
                    color: isPositive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isPositive ? 'You are owed' : 'You owe',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Unable to load balance'),
        ),
      ),
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
              Icons.group_outlined,
              size: 80,
              color: context.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No groups yet',
              style: context.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a group or join one with an invite code',
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

  Widget _buildGroupsList(BuildContext context, List<GroupModel> groups) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return _GroupCard(group: group);
      },
    );
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign Out'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(authNotifierProvider.notifier).signOut();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showJoinGroupDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Claim Invite'),
          content: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Invite Code',
              hintText: 'Enter 6-character code',
            ),
            maxLength: 6,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final code = controller.text.trim();
                if (code.isEmpty) return;

                Navigator.pop(context);
                final group = await ref
                    .read(groupNotifierProvider.notifier)
                    .claimMemberByInviteCode(code);

                if (group != null && context.mounted) {
                  context.showSnackBar('Joined ${group.name}!');
                } else if (context.mounted) {
                  context.showSnackBar('Invalid invite code', isError: true);
                }
              },
              child: const Text('Join'),
            ),
          ],
        );
      },
    );
  }
}

class _GroupCard extends ConsumerWidget {
  final GroupModel group;

  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupBalance = ref.watch(groupBalanceProvider(group.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/groups/${group.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: context.colorScheme.primaryContainer,
                child: Text(
                  group.name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: context.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${group.members.length} members',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              groupBalance.when(
                data: (balance) {
                  if (balance == 0) {
                    return Text(
                      'Settled',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    );
                  }
                  final isPositive = balance > 0;
                  return Text(
                    '${isPositive ? '+' : ''}\$${balance.abs().toStringAsFixed(2)}',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: isPositive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
                loading: () => const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
