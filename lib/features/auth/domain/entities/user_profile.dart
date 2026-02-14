import 'package:urban_cafe/features/auth/domain/entities/user_role.dart';

class UserProfile {
  final String id;
  final UserRole role;
  final int loyaltyPoints;
  final String? fullName;
  final String? phoneNumber;
  final String? address;

  const UserProfile({required this.id, required this.role, this.loyaltyPoints = 0, this.fullName, this.phoneNumber, this.address});

  /// Returns the first name from the full name, or null if no name is set
  String? get firstName => fullName?.split(' ').firstOrNull;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      role: UserRole.fromString(json['role'] as String),
      loyaltyPoints: (json['loyalty_points'] as num?)?.toInt() ?? 0,
      fullName: json['full_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'role': role.name, 'loyalty_points': loyaltyPoints, 'full_name': fullName, 'phone_number': phoneNumber, 'address': address};
  }

  UserProfile copyWith({String? id, UserRole? role, int? loyaltyPoints, String? fullName, String? phoneNumber, String? address}) {
    return UserProfile(
      id: id ?? this.id,
      role: role ?? this.role,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
    );
  }
}
