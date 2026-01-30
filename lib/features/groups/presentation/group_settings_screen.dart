import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:splitdumb/core/extensions/context_extensions.dart';
import 'package:splitdumb/features/auth/providers/auth_providers.dart';
import 'package:splitdumb/features/groups/domain/group_member.dart';
import 'package:splitdumb/features/groups/providers/group_providers.dart';

class GroupSettingsScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupSettingsScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupSettingsScreen> createState() =>
      _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends ConsumerState<GroupSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isEditing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupByIdProvider(widget.groupId));
    final currentUser = ref.watch(authStateProvider).valueOrNull;

    return groupAsync.when(
      data: (group) {
        if (group == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Settings')),
            body: const Center(child: Text('Group not found')),
          );
        }

        if (_nameController.text.isEmpty) {
          _nameController.text = group.name;
          _descriptionController.text = group.description ?? '';
        }

        final isCreator = group.createdBy == currentUser?.uid;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Group Settings'),
            actions: [
              if (_isEditing)
                TextButton(
                  onPressed: _saveChanges,
                  child: const Text('Save'),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Group Info',
                              style: context.textTheme.titleMedium,
                            ),
                            if (isCreator && !_isEditing)
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  setState(() => _isEditing = true);
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          enabled: _isEditing,
                          decoration: const InputDecoration(
                            labelText: 'Group Name',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a group name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          enabled: _isEditing,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Members (${group.members.length})',
                            style: context.textTheme.titleMedium,
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.person_add),
                            label: const Text('Add'),
                            onPressed: () => _showAddMemberDialog(context),
                          ),
                        ],
                      ),
                    ),
                    ...group.members.map((member) {
                      final isCurrentUser =
                          member.linkedUserId == currentUser?.uid;
                      final isGroupCreator =
                          member.linkedUserId == group.createdBy;
                      final isLinked = member.linkedUserId != null;
                      return _MemberTile(
                        member: member,
                        isCurrentUser: isCurrentUser,
                        isGroupCreator: isGroupCreator,
                        isLinked: isLinked,
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              if (isCreator)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colorScheme.error,
                  ),
                  onPressed: () => _confirmDeleteGroup(context),
                  child: const Text('Delete Group'),
                ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(groupNotifierProvider.notifier).updateGroup(
            groupId: widget.groupId,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
          );

      setState(() => _isEditing = false);
      ref.invalidate(groupByIdProvider(widget.groupId));
      if (mounted) {
        context.showSnackBar('Group updated!');
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to update: $e');
      }
    }
  }

  void _showAddMemberDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Member'),
          content: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Display Name',
              hintText: 'e.g., John',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;

                Navigator.pop(context);
                final member = await ref
                    .read(groupNotifierProvider.notifier)
                    .addPlaceholderMember(
                      groupId: widget.groupId,
                      displayName: name,
                    );

                if (member != null && mounted) {
                  context.showSnackBar(
                      'Added $name with invite code: ${member.inviteCode}');
                } else if (mounted) {
                  context.showSnackBar('Failed to add member', isError: true);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteGroup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Group?'),
          content: const Text(
            'This will permanently delete the group and all its expenses. This action cannot be undone.',
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
                try {
                  await ref
                      .read(groupNotifierProvider.notifier)
                      .deleteGroup(widget.groupId);
                  if (context.mounted) {
                    context.go('/');
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete: $e')),
                    );
                  }
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

class _MemberTile extends StatelessWidget {
  final GroupMember member;
  final bool isCurrentUser;
  final bool isGroupCreator;
  final bool isLinked;

  const _MemberTile({
    required this.member,
    required this.isCurrentUser,
    required this.isGroupCreator,
    required this.isLinked,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isLinked
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Text(
          member.displayName.substring(0, 1).toUpperCase(),
          style: TextStyle(
            color: isLinked
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              isCurrentUser ? '${member.displayName} (You)' : member.displayName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isLinked
                  ? Colors.green.withAlpha(30)
                  : Colors.orange.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isLinked ? 'Joined' : 'Pending',
              style: TextStyle(
                fontSize: 12,
                color: isLinked ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Text(
            member.inviteCode,
            style: TextStyle(
              fontFamily: 'monospace',
              letterSpacing: 2,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: member.inviteCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invite code copied!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Icon(
              Icons.copy,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
      trailing: isGroupCreator
          ? Chip(
              label: const Text('Admin'),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            )
          : null,
    );
  }
}
