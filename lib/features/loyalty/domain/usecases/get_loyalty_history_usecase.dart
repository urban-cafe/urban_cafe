import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/features/loyalty/domain/entities/loyalty_transaction.dart';
import 'package:urban_cafe/features/loyalty/domain/repositories/loyalty_repository.dart';

class GetLoyaltyHistoryUseCase {
  final LoyaltyRepository repository;

  const GetLoyaltyHistoryUseCase(this.repository);

  Future<Either<Failure, List<LoyaltyTransaction>>> call({String? userId, int page = 0, int pageSize = 20, DateTime? startDate, DateTime? endDate}) {
    return repository.getTransactionHistory(userId: userId, page: page, pageSize: pageSize, startDate: startDate, endDate: endDate);
  }
}
