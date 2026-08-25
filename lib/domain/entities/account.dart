import 'package:freezed_annotation/freezed_annotation.dart';

part 'account.freezed.dart';
part 'account.g.dart';

/// Статус лицевого счёта.
enum AccountStatus {
  @JsonValue('active')
  active,

  @JsonValue('blocked')
  blocked,

  @JsonValue('suspended')
  suspended,
}

/// Лицевой счёт абонента из биллинговой системы.
@freezed
sealed class Account with _$Account {
  const factory Account({
    @JsonKey(name: 'id')
    required int id,
    @JsonKey(name: 'account_number')
    String? accountNumber,
    @JsonKey(name: 'balance')
    required double balance,
    @JsonKey(name: 'status')
    @Default(AccountStatus.active)
    AccountStatus status,
    @JsonKey(name: 'block_reason')
    String? blockReason,
    @JsonKey(name: 'has_auto_payment')
    @Default(false)
    bool hasAutoPayment,
    @JsonKey(name: 'auto_payment_amount')
    double? autoPaymentAmount,
  }) = _Account;

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);
}
