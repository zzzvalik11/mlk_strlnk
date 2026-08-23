import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:telecom_dashboard/domain/entities/transaction.dart';

part 'transaction_model.freezed.dart';
part 'transaction_model.g.dart';

@freezed
class TransactionModel with _$TransactionModel {
  const TransactionModel._();

  const factory TransactionModel({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'type', unknownEnumValue: TransactionModelType.payment)
    required TransactionModelType type,
    @JsonKey(name: 'amount') required double amount,
    @JsonKey(name: 'description') required String description,
    @JsonKey(name: 'date') required DateTime date,
    @JsonKey(name: 'status', unknownEnumValue: TransactionModelStatus.success)
    required TransactionModelStatus status,
    @JsonKey(name: 'relatedServiceId') String? relatedServiceId,
  }) = _TransactionModel;

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionModelFromJson(json);

  Transaction toDomain() {
    return Transaction(
      id: id,
      type: type.toDomain(),
      amount: amount,
      description: description,
      date: date,
      status: status.toDomain(),
      relatedServiceId: relatedServiceId,
    );
  }

  factory TransactionModel.fromDomain(Transaction transaction) {
    return TransactionModel(
      id: transaction.id,
      type: TransactionModelType.fromDomain(transaction.type),
      amount: transaction.amount,
      description: transaction.description,
      date: transaction.date,
      status: TransactionModelStatus.fromDomain(transaction.status),
      relatedServiceId: transaction.relatedServiceId,
    );
  }
}

@JsonEnum(alwaysCreate: true)
enum TransactionModelType {
  @JsonValue('topUp')
  topUp,
  @JsonValue('payment')
  payment,
  @JsonValue('refund')
  refund,
  @JsonValue('bonus')
  bonus;

  TransactionType toDomain() {
    switch (this) {
      case TransactionModelType.topUp:
        return TransactionType.topUp;
      case TransactionModelType.payment:
        return TransactionType.payment;
      case TransactionModelType.refund:
        return TransactionType.refund;
      case TransactionModelType.bonus:
        return TransactionType.bonus;
    }
  }

  static TransactionModelType fromDomain(TransactionType type) {
    switch (type) {
      case TransactionType.topUp:
        return TransactionModelType.topUp;
      case TransactionType.payment:
        return TransactionModelType.payment;
      case TransactionType.refund:
        return TransactionModelType.refund;
      case TransactionType.bonus:
        return TransactionModelType.bonus;
    }
  }
}

@JsonEnum(alwaysCreate: true)
enum TransactionModelStatus {
  @JsonValue('success')
  success,
  @JsonValue('pending')
  pending,
  @JsonValue('failed')
  failed;

  TransactionStatus toDomain() {
    switch (this) {
      case TransactionModelStatus.success:
        return TransactionStatus.success;
      case TransactionModelStatus.pending:
        return TransactionStatus.pending;
      case TransactionModelStatus.failed:
        return TransactionStatus.failed;
    }
  }

  static TransactionModelStatus fromDomain(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.success:
        return TransactionModelStatus.success;
      case TransactionStatus.pending:
        return TransactionModelStatus.pending;
      case TransactionStatus.failed:
        return TransactionModelStatus.failed;
    }
  }
}
