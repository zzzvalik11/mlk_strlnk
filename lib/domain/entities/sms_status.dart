import 'package:freezed_annotation/freezed_annotation.dart';

part 'sms_status.freezed.dart';
part 'sms_status.g.dart';

/// Результат отправки SMS через Devino Telecom.
@freezed
class SmsSendResult with _$SmsSendResult {
  const factory SmsSendResult({
    @JsonKey(name: 'success')
    required bool success,
    @JsonKey(name: 'sms_id')
    required String smsId,
    @JsonKey(name: 'status')
    String? status,
    @JsonKey(name: 'error')
    String? error,
  }) = _SmsSendResult;

  factory SmsSendResult.fromJson(Map<String, dynamic> json) =>
      _$SmsSendResultFromJson(json);
}

/// Статус доставки SMS.
@freezed
class SmsDeliveryStatus with _$SmsDeliveryStatus {
  const factory SmsDeliveryStatus({
    @JsonKey(name: 'success')
    required bool success,
    @JsonKey(name: 'sms_id')
    required String smsId,
    @JsonKey(name: 'state')
    required String state,
    @JsonKey(name: 'state_description')
    String? stateDescription,
  }) = _SmsDeliveryStatus;

  factory SmsDeliveryStatus.fromJson(Map<String, dynamic> json) =>
      _$SmsDeliveryStatusFromJson(json);
}
