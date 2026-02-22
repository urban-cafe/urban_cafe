import 'package:urban_cafe/features/auth/domain/entities/user_profile.dart';

class LoyaltyTransaction {
  final String id;
  final String userId;
  final String? staffId;
  final int points;
  final String type; // 'earned' or 'redeemed'
  final String? description;
  final DateTime createdAt;

  // Optional profile info (for admin/staff global ledger — the customer)
  final UserProfile? profile;

  // Optional staff profile info (who processed the transaction)
  final UserProfile? staffProfile;

  const LoyaltyTransaction({
    required this.id,
    required this.userId,
    this.staffId,
    required this.points,
    required this.type,
    this.description,
    required this.createdAt,
    this.profile,
    this.staffProfile,
  });

  bool get isEarned => type == 'earned';
  bool get isRedeemed => type == 'redeemed';

  /// Display name for the staff who processed this transaction
  String get staffName => staffProfile?.fullName ?? 'Unknown Staff';

  /// Display name for the customer
  String get customerName => profile?.fullName ?? 'Unknown Customer';

  factory LoyaltyTransaction.fromJson(Map<String, dynamic> json) {
    return LoyaltyTransaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      staffId: json['staff_id'] as String?,
      points: (json['points'] as num).toInt(),
      type: json['type'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      profile: json['profiles'] != null ? UserProfile.fromJson(json['profiles'] as Map<String, dynamic>) : null,
      staffProfile: json['staff'] != null ? UserProfile.fromJson(json['staff'] as Map<String, dynamic>) : null,
    );
  }
}
