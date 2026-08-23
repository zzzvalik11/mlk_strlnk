import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:telecom_dashboard/domain/entities/support_ticket.dart';

part 'support_ticket_model.freezed.dart';
part 'support_ticket_model.g.dart';

@freezed
@JsonSerializable()
class SupportTicketModel with _$SupportTicketModel {
  const SupportTicketModel._();

  const factory SupportTicketModel({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'subject') required String subject,
    @JsonKey(name: 'description') required String description,
    @JsonKey(name: 'status', unknownEnumValue: TicketModelStatus.open)
    required TicketModelStatus status,
    @JsonKey(name: 'createdAt') required DateTime createdAt,
    @JsonKey(name: 'replyCount') @Default(0) int replyCount,
  }) = _SupportTicketModel;

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) =>
      _$SupportTicketModelFromJson(json);

  /// Maps this DTO to the pure domain [SupportTicket] entity.
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

  /// Creates a DTO from a pure domain [SupportTicket] entity.
  factory SupportTicketModel.fromDomain(SupportTicket ticket) {
    return SupportTicketModel(
      id: ticket.id,
      subject: ticket.subject,
      description: ticket.description,
      status: TicketModelStatus.fromDomain(ticket.status),
      createdAt: ticket.createdAt,
      replyCount: ticket.replyCount,
    );
  }
}

/// DTO-specific enum for [TicketStatus] serialization.
/// JSON values match the API contract (camelCase/lowercase strings).
@JsonEnum(alwaysCreate: true)
enum TicketModelStatus {
  @JsonValue('open')
  open,
  @JsonValue('inProgress')
  inProgress,
  @JsonValue('resolved')
  resolved,
  @JsonValue('closed')
  closed;

  /// Maps DTO enum to the domain [TicketStatus] enum.
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

  /// Maps a domain [TicketStatus] enum to this DTO enum.
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
