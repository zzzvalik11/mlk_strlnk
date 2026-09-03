import 'package:telecom_dashboard/domain/entities/user.dart';

/// Модель пользователя. Парсит JSON от /v1/subscriber.
class UserModel {
  final String id;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['subscriber_id'] ?? json['id'] ?? '') as String,
      fullName: (json['full_name'] ?? json['fullName'] ?? '') as String,
      phone: (json['phone'] ?? json['mobile']) as String?,
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: _parseDateTime(
        json['created_at'] ?? json['createdAt'] ?? DateTime.now(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subscriber_id': id,
      'full_name': fullName,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  User toDomain() {
    return User(
      id: id,
      fullName: fullName,
      phone: phone,
      avatarUrl: avatarUrl,
      createdAt: createdAt,
    );
  }
}

extension UserModelFromDomain on User {
  UserModel toModel() {
    return UserModel(
      id: id,
      fullName: fullName,
      phone: phone,
      avatarUrl: avatarUrl,
      createdAt: createdAt,
    );
  }
}

DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  throw ArgumentError('Cannot parse DateTime from $value');
}
