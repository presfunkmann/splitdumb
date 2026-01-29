import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:splitdumb/core/extensions/context_extensions.dart';
import 'package:splitdumb/features/auth/providers/auth_providers.dart';
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
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invite Code',
                        style: context.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: context.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                group.inviteCode,
                                style:
                                    context.textTheme.headlineSmall?.copyWith(
                                  letterSpacing: 4,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: group.inviteCode));
                              context.showSnackBar('Invite code copied!');
                            },
                          ),
                        ],
                      ),
                    ],
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
                      child: Text(
                        'Members (${group.memberIds.length})',
                        style: context.textTheme.titleMedium,
                      ),
                    ),
                    ...group.memberIds.map((memberId) {
                      final isCurrent = memberId == currentUser?.uid;
                      final isGroupCreator = memberId == group.createdBy;
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(memberId.substring(0, 1).toUpperCase()),
                        ),
                        title: Text(isCurrent ? 'You' : 'Member'),
                        trailing: isGroupCreator
                            ? Chip(
                                label: const Text('Admin'),
                                backgroundColor:
                                    context.colorScheme.primaryContainer,
                              )
                            : null,
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
