import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:telecom_dashboard/domain/entities/balance.dart';

part 'balance_model.freezed.dart';
part 'balance_model.g.dart';

@freezed
@JsonSerializable()
class BalanceModel with _$BalanceModel {
  const BalanceModel._();

  const factory BalanceModel({
    @JsonKey(name: 'amount') required double amount,
    @JsonKey(name: 'currency') required String currency,
    @JsonKey(name: 'paidUntil') DateTime? paidUntil,
    @JsonKey(name: 'isPaid') required bool isPaid,
    @JsonKey(name: 'lastUpdated') required DateTime lastUpdated,
  }) = _BalanceModel;

  factory BalanceModel.fromJson(Map<String, dynamic> json) =>
      _$BalanceModelFromJson(json);

  /// Maps this DTO to the pure domain [Balance] entity.
  Balance toDomain() {
    return Balance(
      amount: amount,
      currency: currency,
      paidUntil: paidUntil,
      isPaid: isPaid,
      lastUpdated: lastUpdated,
    );
  }

  /// Creates a DTO from a pure domain [Balance] entity.
  factory BalanceModel.fromDomain(Balance balance) {
    return BalanceModel(
      amount: balance.amount,
      currency: balance.currency,
      paidUntil: balance.paidUntil,
      isPaid: balance.isPaid,
      lastUpdated: balance.lastUpdated,
    );
  }
}
