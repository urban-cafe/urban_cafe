class RedemptionResult {
  final bool success;
  final int? pointsAwarded;
  final int? newBalance;
  final String? clientName;
  final double? purchaseAmount;
  final String? error;
  final String? message;

  const RedemptionResult({required this.success, this.pointsAwarded, this.newBalance, this.clientName, this.purchaseAmount, this.error, this.message});

  factory RedemptionResult.fromJson(Map<String, dynamic> json) {
    return RedemptionResult(
      success: json['success'] as bool? ?? false,
      pointsAwarded: json['points_awarded'] as int?,
      newBalance: json['new_balance'] as int?,
      clientName: json['client_name'] as String?,
      purchaseAmount: (json['purchase_amount'] as num?)?.toDouble(),
      error: json['error'] as String?,
      message: json['message'] as String?,
    );
  }
}
