import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:telecom_dashboard/domain/entities/balance.dart';

part 'balance_model.freezed.dart';
part 'balance_model.g.dart';

@freezed
sealed class BalanceModel with _$BalanceModel {
  const factory BalanceModel({
    @JsonKey(name: 'amount') required double amount,
    @JsonKey(name: 'currency') required String currency,
    @JsonKey(name: 'paidUntil') DateTime? paidUntil,
    @JsonKey(name: 'isPaid') required bool isPaid,
    @JsonKey(name: 'lastUpdated') required DateTime lastUpdated,
  }) = _BalanceModel;

  factory BalanceModel.fromJson(Map<String, dynamic> json) =>
      _$BalanceModelFromJson(json);
}

extension BalanceModelX on BalanceModel {
  Balance toDomain() {
    return Balance(
      amount: amount,
      currency: currency,
      paidUntil: paidUntil,
      isPaid: isPaid,
      lastUpdated: lastUpdated,
    );
  }
}

extension BalanceModelFromDomain on Balance {
  BalanceModel toModel() {
    return BalanceModel(
      amount: amount,
      currency: currency,
      paidUntil: paidUntil,
      isPaid: isPaid,
      lastUpdated: lastUpdated,
    );
  }
}
