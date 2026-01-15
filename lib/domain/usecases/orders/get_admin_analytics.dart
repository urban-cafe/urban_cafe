import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/core/usecases/usecase.dart';
import 'package:urban_cafe/domain/repositories/order_repository.dart';

class GetAdminAnalytics implements UseCase<Map<String, dynamic>, NoParams> {
  final OrderRepository repository;

  GetAdminAnalytics(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(NoParams params) async {
    return await repository.getAdminAnalytics();
  }
}
