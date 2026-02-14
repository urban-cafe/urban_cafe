import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/features/loyalty/domain/entities/point_settings.dart';
import 'package:urban_cafe/features/loyalty/domain/entities/point_token.dart';
import 'package:urban_cafe/features/loyalty/domain/entities/redemption_result.dart';

abstract class LoyaltyRepository {
  /// Client generates a QR token that expires in 5 minutes.
  Future<Either<Failure, PointToken>> generateToken();

  /// Staff/Admin redeems a scanned QR token with the purchase amount.
  Future<Either<Failure, RedemptionResult>> redeemToken(String token, double purchaseAmount);

  /// Get current point conversion settings.
  Future<Either<Failure, PointSettings>> getPointSettings();

  /// Admin updates point conversion settings.
  Future<Either<Failure, PointSettings>> updatePointSettings(PointSettings settings);
}
