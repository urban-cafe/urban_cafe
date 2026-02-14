class PointSettings {
  final String id;
  final int pointsPerUnit;
  final double amountPerPoint;

  const PointSettings({required this.id, required this.pointsPerUnit, required this.amountPerPoint});

  /// Calculate how many points a given purchase amount earns.
  int calculatePoints(double purchaseAmount) {
    if (amountPerPoint <= 0) return 0;
    return ((purchaseAmount / amountPerPoint) * pointsPerUnit).floor();
  }

  factory PointSettings.fromJson(Map<String, dynamic> json) {
    return PointSettings(id: json['id'] as String, pointsPerUnit: json['points_per_unit'] as int? ?? 1, amountPerPoint: (json['amount_per_point'] as num?)?.toDouble() ?? 1000);
  }

  Map<String, dynamic> toJson() {
    return {'points_per_unit': pointsPerUnit, 'amount_per_point': amountPerPoint};
  }
}
