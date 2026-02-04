import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:splitdumb/features/auth/domain/user_model.dart';

part 'expense_model.freezed.dart';
part 'expense_model.g.dart';

enum SplitType {
  equal,
  exact,
  percentage,
}

@freezed
abstract class ExpenseEdit with _$ExpenseEdit {
  const ExpenseEdit._();

  const factory ExpenseEdit({
    required String editedBy,
    @TimestampConverter() required DateTime editedAt,
    required String description,
    required double amount,
    required Map<String, double> paidBy,
    required SplitType splitType,
    required Map<String, double> splits,
    String? category,
  }) = _ExpenseEdit;

  factory ExpenseEdit.fromJson(Map<String, dynamic> json) =>
      _$ExpenseEditFromJson(json);
}

@freezed
abstract class ExpenseModel with _$ExpenseModel {
  const ExpenseModel._();

  const factory ExpenseModel({
    required String id,
    required String groupId,
    required String description,
    required double amount,
    required Map<String, double> paidBy,
    required SplitType splitType,
    required Map<String, double> splits,
    String? category,
    @TimestampConverter() required DateTime date,
    @TimestampConverter() required DateTime createdAt,
    @Default([]) List<ExpenseEdit> editHistory,
  }) = _ExpenseModel;

  factory ExpenseModel.fromJson(Map<String, dynamic> json) =>
      _$ExpenseModelFromJson(json);

  /// Total amount paid by all payers (should equal `amount`)
  double get totalPaid => paidBy.values.fold(0.0, (sum, v) => sum + v);

  /// Primary payer (the one who paid the most) - for display purposes
  String get primaryPayer =>
      paidBy.entries.reduce((a, b) => a.value > b.value ? a : b).key;

  /// Check if this expense has multiple payers
  bool get hasMultiplePayers => paidBy.length > 1;
}

/// Helper function to migrate legacy expense JSON (String paidBy) to new format (Map paidBy)
Map<String, dynamic> migrateExpenseJson(Map<String, dynamic> json) {
  if (json['paidBy'] is String) {
    final singlePayer = json['paidBy'] as String;
    final amount = (json['amount'] as num).toDouble();
    json = {...json, 'paidBy': {singlePayer: amount}};
  }
  // Also migrate editHistory if present
  if (json['editHistory'] is List) {
    json = {
      ...json,
      'editHistory': (json['editHistory'] as List).map((edit) {
        if (edit is Map<String, dynamic> && edit['paidBy'] is String) {
          final singlePayer = edit['paidBy'] as String;
          final amount = (edit['amount'] as num).toDouble();
          return {...edit, 'paidBy': {singlePayer: amount}};
        }
        return edit;
      }).toList(),
    };
  }
  return json;
}
