import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:splitdumb/core/extensions/context_extensions.dart';
import 'package:splitdumb/features/groups/providers/group_providers.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    final group = await ref.read(groupNotifierProvider.notifier).createGroup(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );

    if (group != null && mounted) {
      context.showSnackBar('Group created!');
      context.go('/groups/${group.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupState = ref.watch(groupNotifierProvider);

    ref.listen(groupNotifierProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          context.showSnackBar(error.toString(), isError: true);
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Group Name',
                    hintText: 'e.g., Roommates, Trip to Paris',
                    prefixIcon: Icon(Icons.group_outlined),
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
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Add a note about this group',
                    prefixIcon: Icon(Icons.description_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: groupState.isLoading ? null : _createGroup,
                  child: groupState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Group'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
