import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/features/loyalty/domain/entities/redemption_result.dart';
import 'package:urban_cafe/features/loyalty/domain/repositories/loyalty_repository.dart';

class ProcessPointTransaction {
  final LoyaltyRepository repository;
  const ProcessPointTransaction(this.repository);

  Future<Either<Failure, RedemptionResult>> call(String token, int points, bool isAward) => repository.processPointTransaction(token, points, isAward);
}
