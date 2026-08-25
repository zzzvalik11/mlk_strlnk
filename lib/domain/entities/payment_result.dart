import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_result.freezed.dart';
part 'payment_result.g.dart';

/// Статус платёжной транзакции.
enum PaymentStatus {
  @JsonValue('OK')
  ok,

  @JsonValue('ERROR')
  error,

  @JsonValue('REJECTED')
  rejected,

  @JsonValue('PENDING')
  pending,
}

/// Статус процесса в платёжной системе.
enum PaymentProcessStatus {
  @JsonValue('FINISHED')
  finished,

  @JsonValue('ACTIVE')
  active,

  @JsonValue('REVERSED')
  reversed,
}

/// Результат проверки платежа (РСБ или СБП).
@freezed
sealed class PaymentResult with _$PaymentResult {
  const factory PaymentResult({
    @JsonKey(name: 'success')
    required bool success,
    @JsonKey(name: 'result')
    PaymentStatus? result,
    @JsonKey(name: 'result_code')
    String? resultCode,
    @JsonKey(name: 'rrn')
    String? rrn,
    @JsonKey(name: 'approval_code')
    String? approvalCode,
    @JsonKey(name: 'card_number')
    String? cardNumber,
    @JsonKey(name: 'message')
    String? message,
  }) = _PaymentResult;

  factory PaymentResult.fromJson(Map<String, dynamic> json) =>
      _$PaymentResultFromJson(json);
}
