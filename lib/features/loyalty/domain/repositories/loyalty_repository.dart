import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/features/loyalty/domain/entities/loyalty_transaction.dart';
import 'package:urban_cafe/features/loyalty/domain/entities/point_token.dart';
import 'package:urban_cafe/features/loyalty/domain/entities/redemption_result.dart';

abstract class LoyaltyRepository {
  /// Fetches transaction history with pagination and optional date-range filtering.
  /// If [userId] is null, fetches a global ledger of all transactions (for Admin/Staff).
  /// If [userId] is provided, fetches the specific user's history (for Client).
  Future<Either<Failure, List<LoyaltyTransaction>>> getTransactionHistory({String? userId, int page = 0, int pageSize = 20, DateTime? startDate, DateTime? endDate});

  /// Client generates a QR token that expires in 5 minutes.
  Future<Either<Failure, PointToken>> generateToken();

  /// Staff/Admin processes a point transaction from a scanned QR token.
  Future<Either<Failure, RedemptionResult>> processPointTransaction(String token, int points, bool isAward);
}
