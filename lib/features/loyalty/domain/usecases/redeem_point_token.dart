import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/features/loyalty/domain/entities/redemption_result.dart';
import 'package:urban_cafe/features/loyalty/domain/repositories/loyalty_repository.dart';

class RedeemPointToken {
  final LoyaltyRepository repository;
  const RedeemPointToken(this.repository);

  Future<Either<Failure, RedemptionResult>> call(String token, double purchaseAmount) => repository.redeemToken(token, purchaseAmount);
}
