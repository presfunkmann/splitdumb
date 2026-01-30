import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:splitdumb/core/extensions/context_extensions.dart';
import 'package:splitdumb/features/expenses/domain/expense_model.dart';
import 'package:splitdumb/features/expenses/providers/expense_providers.dart';
import 'package:splitdumb/features/groups/providers/group_providers.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final String groupId;

  const AddExpenseScreen({super.key, required this.groupId});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  SplitType _splitType = SplitType.equal;
  String? _selectedCategory;
  String? _paidBy; // This is now member ID
  DateTime _date = DateTime.now();
  Map<String, double> _customSplits = {};
  Map<String, bool> _selectedMembers = {};

  final _categories = [
    'Food',
    'Transport',
    'Entertainment',
    'Shopping',
    'Utilities',
    'Rent',
    'Other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupByIdProvider(widget.groupId));
    final currentMember = ref.watch(currentUserMemberProvider(widget.groupId));
    final expenseState = ref.watch(expenseNotifierProvider);

    ref.listen(expenseNotifierProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          context.showSnackBar(error.toString(), isError: true);
        },
      );
    });

    return groupAsync.when(
      data: (group) {
        if (group == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Add Expense')),
            body: const Center(child: Text('Group not found')),
          );
        }

        // Initialize paidBy to current member's ID
        _paidBy ??= currentMember?.id;

        // Initialize selected members
        if (_selectedMembers.isEmpty) {
          for (final member in group.members) {
            _selectedMembers[member.id] = true;
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Add Expense'),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: '\$ ',
                    prefixIcon: const Icon(Icons.attach_money),
                    filled: true,
                    fillColor: context.colorScheme.surfaceContainerHighest,
                  ),
                  style: context.textTheme.headlineMedium,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                  onChanged: (_) => _updateSplits(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'What was this for?',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategory = value);
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Date'),
                  subtitle: Text(DateFormat.yMMMd().format(_date)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _date = picked);
                    }
                  },
                ),
                const Divider(height: 32),
                Text(
                  'Paid by',
                  style: context.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: group.members.map((member) {
                    final isSelected = _paidBy == member.id;
                    final isCurrentUser = member.id == currentMember?.id;
                    return ChoiceChip(
                      label: Text(isCurrentUser
                          ? 'You (${member.displayName})'
                          : member.displayName),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _paidBy = member.id);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Text(
                  'Split type',
                  style: context.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SegmentedButton<SplitType>(
                  segments: const [
                    ButtonSegment(
                      value: SplitType.equal,
                      label: Text('Equal'),
                      icon: Icon(Icons.balance),
                    ),
                    ButtonSegment(
                      value: SplitType.exact,
                      label: Text('Exact'),
                      icon: Icon(Icons.edit),
                    ),
                    ButtonSegment(
                      value: SplitType.percentage,
                      label: Text('%'),
                      icon: Icon(Icons.percent),
                    ),
                  ],
                  selected: {_splitType},
                  onSelectionChanged: (selected) {
                    setState(() {
                      _splitType = selected.first;
                      _updateSplits();
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildSplitUI(group.members, currentMember?.id),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: expenseState.isLoading ? null : _saveExpense,
                  child: expenseState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Expense'),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Add Expense')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Add Expense')),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildSplitUI(
      List<dynamic> members, String? currentMemberId) {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final selectedMemberIds = _selectedMembers.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    switch (_splitType) {
      case SplitType.equal:
        return _buildEqualSplitUI(
            members, currentMemberId, amount, selectedMemberIds);
      case SplitType.exact:
        return _buildExactSplitUI(members, currentMemberId, amount);
      case SplitType.percentage:
        return _buildPercentageSplitUI(members, currentMemberId, amount);
    }
  }

  Widget _buildEqualSplitUI(List<dynamic> members, String? currentMemberId,
      double amount, List<String> selectedMemberIds) {
    final perPerson =
        selectedMemberIds.isEmpty ? 0.0 : amount / selectedMemberIds.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Split equally among:',
          style: context.textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        ...members.map((member) {
          final isSelected = _selectedMembers[member.id] ?? false;
          final isCurrentUser = member.id == currentMemberId;
          return CheckboxListTile(
            title: Text(isCurrentUser
                ? 'You (${member.displayName})'
                : member.displayName),
            subtitle: isSelected
                ? Text('\$${perPerson.toStringAsFixed(2)}')
                : null,
            value: isSelected,
            onChanged: (value) {
              setState(() {
                _selectedMembers[member.id] = value ?? false;
                _updateSplits();
              });
            },
          );
        }),
      ],
    );
  }

  Widget _buildExactSplitUI(
      List<dynamic> members, String? currentMemberId, double amount) {
    final totalSplit = _customSplits.values.fold(0.0, (a, b) => a + b);
    final remaining = amount - totalSplit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Enter exact amounts:',
              style: context.textTheme.bodyMedium,
            ),
            Text(
              remaining == 0
                  ? 'Balanced'
                  : '\$${remaining.abs().toStringAsFixed(2)} ${remaining > 0 ? 'left' : 'over'}',
              style: TextStyle(
                color: remaining == 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...members.map((member) {
          final isCurrentUser = member.id == currentMemberId;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextFormField(
              initialValue: _customSplits[member.id]?.toStringAsFixed(2) ?? '',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: isCurrentUser
                    ? 'You (${member.displayName})'
                    : member.displayName,
                prefixText: '\$ ',
                isDense: true,
              ),
              onChanged: (value) {
                final parsed = double.tryParse(value) ?? 0;
                setState(() {
                  _customSplits[member.id] = parsed;
                });
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPercentageSplitUI(
      List<dynamic> members, String? currentMemberId, double amount) {
    final totalPercentage = _customSplits.values.fold(0.0, (a, b) => a + b);
    final remaining = 100 - totalPercentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Enter percentages:',
              style: context.textTheme.bodyMedium,
            ),
            Text(
              remaining == 0
                  ? 'Balanced'
                  : '${remaining.abs().toStringAsFixed(0)}% ${remaining > 0 ? 'left' : 'over'}',
              style: TextStyle(
                color: remaining == 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...members.map((member) {
          final isCurrentUser = member.id == currentMemberId;
          final percentage = _customSplits[member.id] ?? 0;
          final calculatedAmount = amount * (percentage / 100);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue:
                        percentage > 0 ? percentage.toStringAsFixed(0) : '',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      labelText: isCurrentUser
                          ? 'You (${member.displayName})'
                          : member.displayName,
                      suffixText: '%',
                      isDense: true,
                    ),
                    onChanged: (value) {
                      final parsed = double.tryParse(value) ?? 0;
                      setState(() {
                        _customSplits[member.id] = parsed;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 80,
                  child: Text(
                    '\$${calculatedAmount.toStringAsFixed(2)}',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _updateSplits() {
    final amount = double.tryParse(_amountController.text) ?? 0;

    if (_splitType == SplitType.equal) {
      final selectedMemberIds = _selectedMembers.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      if (selectedMemberIds.isNotEmpty) {
        _customSplits = SplitCalculator.calculateEqualSplit(
          amount,
          selectedMemberIds,
        );
      }
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);
    Map<String, double> splits;

    switch (_splitType) {
      case SplitType.equal:
        final selectedMemberIds = _selectedMembers.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList();
        splits = SplitCalculator.calculateEqualSplit(amount, selectedMemberIds);
        break;
      case SplitType.exact:
        splits = Map.from(_customSplits);
        break;
      case SplitType.percentage:
        splits = SplitCalculator.calculatePercentageSplit(amount, _customSplits);
        break;
    }

    if (!SplitCalculator.validateSplits(amount, splits, _splitType)) {
      context.showSnackBar('Splits do not add up correctly', isError: true);
      return;
    }

    final expense =
        await ref.read(expenseNotifierProvider.notifier).createExpenseWithPayer(
              groupId: widget.groupId,
              description: _descriptionController.text.trim(),
              amount: amount,
              paidBy: _paidBy!,
              splitType: _splitType,
              splits: splits,
              category: _selectedCategory,
              date: _date,
            );

    if (expense != null && mounted) {
      context.showSnackBar('Expense added!');
      context.pop();
    }
  }
}
