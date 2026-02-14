class PointToken {
  final String id;
  final String userId;
  final String token;
  final DateTime expiresAt;
  final bool redeemed;
  final int? pointsAwarded;
  final double? purchaseAmount;

  const PointToken({required this.id, required this.userId, required this.token, required this.expiresAt, this.redeemed = false, this.pointsAwarded, this.purchaseAmount});

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);

  Duration get timeRemaining {
    final remaining = expiresAt.difference(DateTime.now().toUtc());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  factory PointToken.fromJson(Map<String, dynamic> json) {
    return PointToken(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      redeemed: json['redeemed'] as bool? ?? false,
      pointsAwarded: json['points_awarded'] as int?,
      purchaseAmount: (json['purchase_amount'] as num?)?.toDouble(),
    );
  }
}
