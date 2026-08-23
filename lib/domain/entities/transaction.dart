import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

enum TransactionType {
  @JsonValue('topUp')
  topUp,
  @JsonValue('payment')
  payment,
  @JsonValue('refund')
  refund,
  @JsonValue('bonus')
  bonus,
}

enum TransactionStatus {
  @JsonValue('success')
  success,
  @JsonValue('pending')
  pending,
  @JsonValue('failed')
  failed,
}

@freezed
sealed class Transaction with _$Transaction {
  const factory Transaction({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'type', unknownEnumValue: TransactionType.payment)
    required TransactionType type,
    @JsonKey(name: 'amount') required double amount,
    @JsonKey(name: 'description') required String description,
    @JsonKey(name: 'date') required DateTime date,
    @JsonKey(name: 'status', unknownEnumValue: TransactionStatus.success)
    required TransactionStatus status,
    @JsonKey(name: 'relatedServiceId') String? relatedServiceId,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}
