import 'package:urban_cafe/domain/entities/user_role.dart';

class UserProfile {
  final String id;
  final UserRole role;

  const UserProfile({
    required this.id,
    required this.role,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      role: UserRole.fromString(json['role'] as String),
    );
  }
}
