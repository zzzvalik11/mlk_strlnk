import 'package:freezed_annotation/freezed_annotation.dart';

part 'balance.freezed.dart';
part 'balance.g.dart';

@freezed
@JsonSerializable()
class Balance with _$Balance {
  const factory Balance({
    @JsonKey(name: 'amount') required double amount,
    @JsonKey(name: 'currency') required String currency,
    @JsonKey(name: 'paidUntil') DateTime? paidUntil,
    @JsonKey(name: 'isPaid') required bool isPaid,
    @JsonKey(name: 'lastUpdated') required DateTime lastUpdated,
  }) = _Balance;

  factory Balance.fromJson(Map<String, dynamic> json) => _$BalanceFromJson(json);
}
