import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/features/loyalty/domain/entities/loyalty_transaction.dart';
import 'package:urban_cafe/features/loyalty/domain/repositories/loyalty_repository.dart';

class GetLoyaltyHistoryUseCase {
  final LoyaltyRepository repository;

  const GetLoyaltyHistoryUseCase(this.repository);

  Future<Either<Failure, List<LoyaltyTransaction>>> call({String? userId}) {
    return repository.getTransactionHistory(userId: userId);
  }
}
