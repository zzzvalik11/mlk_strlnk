import 'package:telecom_dashboard/domain/entities/balance.dart';

class BalanceModel {
  final double amount;
  final String currency;
  final DateTime? paidUntil;
  final bool isPaid;
  final DateTime lastUpdated;

  const BalanceModel({
    required this.amount,
    required this.currency,
    this.paidUntil,
    required this.isPaid,
    required this.lastUpdated,
  });

  factory BalanceModel.fromJson(Map<String, dynamic> json) {
    return BalanceModel(
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      paidUntil: json['paidUntil'] != null
          ? _parseDateTime(json['paidUntil'])
          : null,
      isPaid: json['isPaid'] as bool,
      lastUpdated: _parseDateTime(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency,
      'paidUntil': paidUntil?.toIso8601String(),
      'isPaid': isPaid,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

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

DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  throw ArgumentError('Cannot parse DateTime from $value');
}
