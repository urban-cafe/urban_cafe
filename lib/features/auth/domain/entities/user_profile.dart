import 'package:urban_cafe/features/auth/domain/entities/user_role.dart';

class UserProfile {
  final String id;
  final UserRole role;
  final int loyaltyPoints;

  const UserProfile({
    required this.id,
    required this.role,
    this.loyaltyPoints = 0,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      role: UserRole.fromString(json['role'] as String),
      loyaltyPoints: (json['loyalty_points'] as num?)?.toInt() ?? 0,
    );
  }
}
