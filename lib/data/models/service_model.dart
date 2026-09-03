import 'package:telecom_dashboard/domain/entities/service.dart';

class ServiceModel {
  final String id;
  final String name;
  final String category;
  final double cost;
  final ServiceModelStatus status;
  final String? iconUrl;
  final String? warningMessage;
  final String? billingCycle;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.cost,
    required this.status,
    this.iconUrl,
    this.warningMessage,
    this.billingCycle,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      cost: (json['cost'] as num).toDouble(),
      status: ServiceModelStatus.fromString(json['status'] as String? ?? 'active'),
      iconUrl: json['iconUrl'] as String?,
      warningMessage: json['warningMessage'] as String?,
      billingCycle: json['billingCycle'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'cost': cost,
      'status': status.value,
      'iconUrl': iconUrl,
      'warningMessage': warningMessage,
      'billingCycle': billingCycle,
    };
  }

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
enum ServiceModelStatus {
  active('active'),
  expired('expired'),
  paused('paused'),
  error('error');

  const ServiceModelStatus(this.value);
  final String value;

  static ServiceModelStatus fromString(String value) {
    return ServiceModelStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ServiceModelStatus.active,
    );
  }

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
