class RedemptionResult {
  final bool success;
  final int? pointsProcessed;
  final int? newBalance;
  final String? clientName;
  final bool? isAward;
  final String? error;
  final String? message;

  const RedemptionResult({required this.success, this.pointsProcessed, this.newBalance, this.clientName, this.isAward, this.error, this.message});

  factory RedemptionResult.fromJson(Map<String, dynamic> json) {
    return RedemptionResult(
      success: json['success'] as bool? ?? false,
      pointsProcessed: json['pointsProcessed'] as int?,
      newBalance: json['newBalance'] as int?,
      clientName: json['clientName'] as String?,
      isAward: json['isAward'] as bool?,
      error: json['error'] as String?,
      message: json['message'] as String?,
    );
  }
}
