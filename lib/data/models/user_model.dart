import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:telecom_dashboard/domain/entities/user.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
sealed class UserModel with _$UserModel {
  const factory UserModel({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'fullName') required String fullName,
    @JsonKey(name: 'phone') String? phone,
    @JsonKey(name: 'avatarUrl') String? avatarUrl,
    @JsonKey(name: 'createdAt') required DateTime createdAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

extension UserModelX on UserModel {
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
