import 'package:freezed_annotation/freezed_annotation.dart';

part 'service.freezed.dart';
part 'service.g.dart';

enum ServiceStatus {
  @JsonValue('active')
  active,
  @JsonValue('expired')
  expired,
  @JsonValue('paused')
  paused,
  @JsonValue('error')
  error,
}

@freezed
sealed class Service with _$Service {
  const factory Service({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'category') required String category,
    @JsonKey(name: 'cost') required double cost,
    @JsonKey(name: 'status', unknownEnumValue: ServiceStatus.active)
    required ServiceStatus status,
    @JsonKey(name: 'iconUrl') String? iconUrl,
    @JsonKey(name: 'warningMessage') String? warningMessage,
    @JsonKey(name: 'billingCycle') String? billingCycle,
  }) = _Service;

  factory Service.fromJson(Map<String, dynamic> json) =>
      _$ServiceFromJson(json);
}
