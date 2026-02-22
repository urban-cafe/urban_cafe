import 'package:urban_cafe/features/auth/domain/entities/user_profile.dart';

class LoyaltyTransaction {
  final String id;
  final String userId;
  final int points;
  final String type; // 'earned' or 'redeemed'
  final String? description;
  final DateTime createdAt;

  // Optional profile info (for admin/staff global ledger)
  final UserProfile? profile;

  const LoyaltyTransaction({required this.id, required this.userId, required this.points, required this.type, this.description, required this.createdAt, this.profile});

  bool get isEarned => type == 'earned';
  bool get isRedeemed => type == 'redeemed';

  factory LoyaltyTransaction.fromJson(Map<String, dynamic> json) {
    return LoyaltyTransaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      points: (json['points'] as num).toInt(),
      type: json['type'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      profile: json['profiles'] != null ? UserProfile.fromJson(json['profiles'] as Map<String, dynamic>) : null,
    );
  }
}
