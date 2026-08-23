import 'package:telecom_dashboard/domain/entities/transaction.dart';

class TransactionModel {
  final String id;
  final TransactionModelType type;
  final double amount;
  final String description;
  final DateTime date;
  final TransactionModelStatus status;
  final String? relatedServiceId;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    required this.status,
    this.relatedServiceId,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      type: TransactionModelType.fromString(json['type'] as String? ?? 'payment'),
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      date: _parseDateTime(json['date']),
      status: TransactionModelStatus.fromString(json['status'] as String? ?? 'success'),
      relatedServiceId: json['relatedServiceId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'status': status.value,
      'relatedServiceId': relatedServiceId,
    };
  }
}

extension TransactionModelX on TransactionModel {
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
}

extension TransactionModelFromDomain on Transaction {
  TransactionModel toModel() {
    return TransactionModel(
      id: id,
      type: TransactionModelType.fromDomain(type),
      amount: amount,
      description: description,
      date: date,
      status: TransactionModelStatus.fromDomain(status),
      relatedServiceId: relatedServiceId,
    );
  }
}

enum TransactionModelType {
  topUp('topUp'),
  payment('payment'),
  refund('refund'),
  bonus('bonus');

  const TransactionModelType(this.value);
  final String value;

  static TransactionModelType fromString(String value) {
    return TransactionModelType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TransactionModelType.payment,
    );
  }

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

enum TransactionModelStatus {
  success('success'),
  pending('pending'),
  failed('failed');

  const TransactionModelStatus(this.value);
  final String value;

  static TransactionModelStatus fromString(String value) {
    return TransactionModelStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TransactionModelStatus.success,
    );
  }

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

DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  throw ArgumentError('Cannot parse DateTime from $value');
}