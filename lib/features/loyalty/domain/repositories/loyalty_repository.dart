import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/features/loyalty/domain/entities/point_token.dart';
import 'package:urban_cafe/features/loyalty/domain/entities/redemption_result.dart';

abstract class LoyaltyRepository {
  /// Client generates a QR token that expires in 5 minutes.
  Future<Either<Failure, PointToken>> generateToken();

  /// Staff/Admin processes a point transaction from a scanned QR token.
  Future<Either<Failure, RedemptionResult>> processPointTransaction(String token, int points, bool isAward);
}
