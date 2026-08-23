import 'package:freezed_annotation/freezed_annotation.dart';

part 'support_ticket.freezed.dart';
part 'support_ticket.g.dart';

enum TicketStatus {
  @JsonValue('open')
  open,
  @JsonValue('inProgress')
  inProgress,
  @JsonValue('resolved')
  resolved,
  @JsonValue('closed')
  closed,
}

@freezed
@JsonSerializable()
class SupportTicket with _$SupportTicket {
  const factory SupportTicket({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'subject') required String subject,
    @JsonKey(name: 'description') required String description,
    @JsonKey(name: 'status', unknownEnumValue: TicketStatus.open)
    required TicketStatus status,
    @JsonKey(name: 'createdAt') required DateTime createdAt,
    @JsonKey(name: 'replyCount') @Default(0) int replyCount,
  }) = _SupportTicket;

  factory SupportTicket.fromJson(Map<String, dynamic> json) =>
      _$SupportTicketFromJson(json);
}
