import 'package:telecom_dashboard/domain/entities/support_ticket.dart';

class SupportTicketModel {
  final String id;
  final String subject;
  final String description;
  final TicketModelStatus status;
  final DateTime createdAt;
  final int replyCount;

  const SupportTicketModel({
    required this.id,
    required this.subject,
    required this.description,
    required this.status,
    required this.createdAt,
    this.replyCount = 0,
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketModel(
      id: json['id'] as String,
      subject: json['subject'] as String,
      description: json['description'] as String,
      status: TicketModelStatus.fromString(json['status'] as String? ?? 'open'),
      createdAt: _parseDateTime(json['createdAt']),
      replyCount: json['replyCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'description': description,
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'replyCount': replyCount,
    };
  }
}

extension SupportTicketModelX on SupportTicketModel {
  SupportTicket toDomain() {
    return SupportTicket(
      id: id,
      subject: subject,
      description: description,
      status: status.toDomain(),
      createdAt: createdAt,
      replyCount: replyCount,
    );
  }
}

extension SupportTicketModelFromDomain on SupportTicket {
  SupportTicketModel toModel() {
    return SupportTicketModel(
      id: id,
      subject: subject,
      description: description,
      status: TicketModelStatus.fromDomain(status),
      createdAt: createdAt,
      replyCount: replyCount,
    );
  }
}

enum TicketModelStatus {
  open('open'),
  inProgress('inProgress'),
  resolved('resolved'),
  closed('closed');

  const TicketModelStatus(this.value);
  final String value;

  static TicketModelStatus fromString(String value) {
    return TicketModelStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TicketModelStatus.open,
    );
  }

  TicketStatus toDomain() {
    switch (this) {
      case TicketModelStatus.open:
        return TicketStatus.open;
      case TicketModelStatus.inProgress:
        return TicketStatus.inProgress;
      case TicketModelStatus.resolved:
        return TicketStatus.resolved;
      case TicketModelStatus.closed:
        return TicketStatus.closed;
    }
  }

  static TicketModelStatus fromDomain(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return TicketModelStatus.open;
      case TicketStatus.inProgress:
        return TicketModelStatus.inProgress;
      case TicketStatus.resolved:
        return TicketModelStatus.resolved;
      case TicketStatus.closed:
        return TicketModelStatus.closed;
    }
  }
}

DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  throw ArgumentError('Cannot parse DateTime from $value');
}
