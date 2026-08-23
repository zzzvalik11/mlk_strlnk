import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:telecom_dashboard/domain/entities/service.dart';

part 'service_model.freezed.dart';
part 'service_model.g.dart';

@freezed
sealed class ServiceModel with _$ServiceModel {
  const factory ServiceModel({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'category') required String category,
    @JsonKey(name: 'cost') required double cost,
    @JsonKey(name: 'status', unknownEnumValue: ServiceModelStatus.active)
    required ServiceModelStatus status,
    @JsonKey(name: 'iconUrl') String? iconUrl,
    @JsonKey(name: 'warningMessage') String? warningMessage,
    @JsonKey(name: 'billingCycle') String? billingCycle,
  }) = _ServiceModel;

  factory ServiceModel.fromJson(Map<String, dynamic> json) =>
      _$ServiceModelFromJson(json);
}

extension ServiceModelX on ServiceModel {
  Service toDomain() {
    return Service(
      id: id,
      name: name,
      category: category,
      cost: cost,
      status: status.toDomain(),
      iconUrl: iconUrl,
      warningMessage: warningMessage,
      billingCycle: billingCycle,
    );
  }
}

extension ServiceModelFromDomain on Service {
  ServiceModel toModel() {
    return ServiceModel(
      id: id,
      name: name,
      category: category,
      cost: cost,
      status: ServiceModelStatus.fromDomain(status),
      iconUrl: iconUrl,
      warningMessage: warningMessage,
      billingCycle: billingCycle,
    );
  }
}

/// DTO-specific enum for [ServiceStatus] serialization.
@JsonEnum(valueField: 'value', alwaysCreate: true)
enum ServiceModelStatus {
  @JsonValue('active')
  active('active'),
  @JsonValue('expired')
  expired('expired'),
  @JsonValue('paused')
  paused('paused'),
  @JsonValue('error')
  error('error');

  const ServiceModelStatus(this.value);
  final String value;

  ServiceStatus toDomain() {
    switch (this) {
      case ServiceModelStatus.active:
        return ServiceStatus.active;
      case ServiceModelStatus.expired:
        return ServiceStatus.expired;
      case ServiceModelStatus.paused:
        return ServiceStatus.paused;
      case ServiceModelStatus.error:
        return ServiceStatus.error;
    }
  }

  static ServiceModelStatus fromDomain(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.active:
        return ServiceModelStatus.active;
      case ServiceStatus.expired:
        return ServiceModelStatus.expired;
      case ServiceStatus.paused:
        return ServiceModelStatus.paused;
      case ServiceStatus.error:
        return ServiceModelStatus.error;
    }
  }
}
