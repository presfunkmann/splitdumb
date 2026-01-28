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
abstract class ExpenseModel with _$ExpenseModel {
  const factory ExpenseModel({
    required String id,
    required String groupId,
    required String description,
    required double amount,
    required String paidBy,
    required SplitType splitType,
    required Map<String, double> splits,
    String? category,
    @TimestampConverter() required DateTime date,
    @TimestampConverter() required DateTime createdAt,
  }) = _ExpenseModel;

  factory ExpenseModel.fromJson(Map<String, dynamic> json) =>
      _$ExpenseModelFromJson(json);
}
