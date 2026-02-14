import 'package:urban_cafe/features/auth/domain/entities/user_role.dart';

class UserProfile {
  final String id;
  final UserRole role;
  final int loyaltyPoints;
  final String? fullName;

  const UserProfile({required this.id, required this.role, this.loyaltyPoints = 0, this.fullName});

  /// Returns the first name from the full name, or null if no name is set
  String? get firstName => fullName?.split(' ').firstOrNull;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      role: UserRole.fromString(json['role'] as String),
      loyaltyPoints: (json['loyalty_points'] as num?)?.toInt() ?? 0,
      fullName: json['full_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'role': role.name, 'loyalty_points': loyaltyPoints, 'full_name': fullName};
  }

  UserProfile copyWith({String? id, UserRole? role, int? loyaltyPoints, String? fullName}) {
    return UserProfile(id: id ?? this.id, role: role ?? this.role, loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints, fullName: fullName ?? this.fullName);
  }
}
