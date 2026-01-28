import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:splitdumb/features/auth/domain/user_model.dart';

part 'settlement_model.freezed.dart';
part 'settlement_model.g.dart';

@freezed
abstract class SettlementModel with _$SettlementModel {
  const factory SettlementModel({
    required String id,
    required String groupId,
    required String fromUser,
    required String toUser,
    required double amount,
    @TimestampConverter() required DateTime createdAt,
  }) = _SettlementModel;

  factory SettlementModel.fromJson(Map<String, dynamic> json) =>
      _$SettlementModelFromJson(json);
}
