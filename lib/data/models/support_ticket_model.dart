import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:telecom_dashboard/domain/entities/support_ticket.dart';

part 'support_ticket_model.freezed.dart';
part 'support_ticket_model.g.dart';

@freezed
sealed class SupportTicketModel with _$SupportTicketModel {
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
