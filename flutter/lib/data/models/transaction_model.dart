import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:telecom_dashboard/domain/entities/transaction.dart';

part 'transaction_model.freezed.dart';
part 'transaction_model.g.dart';

@freezed
@JsonSerializable()
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

  /// Maps this DTO to the pure domain [Transaction] entity.
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

  /// Creates a DTO from a pure domain [Transaction] entity.
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

/// DTO-specific enum for [TransactionType] serialization.
/// JSON values match the API contract (camelCase, matching domain @JsonValue).
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

  /// Maps DTO enum to the domain [TransactionType] enum.
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

  /// Maps a domain [TransactionType] enum to this DTO enum.
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

/// DTO-specific enum for [TransactionStatus] serialization.
/// JSON values match the API contract (lowercase strings).
@JsonEnum(alwaysCreate: true)
enum TransactionModelStatus {
  @JsonValue('success')
  success,
  @JsonValue('pending')
  pending,
  @JsonValue('failed')
  failed;

  /// Maps DTO enum to the domain [TransactionStatus] enum.
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

  /// Maps a domain [TransactionStatus] enum to this DTO enum.
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
