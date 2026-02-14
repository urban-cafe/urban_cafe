import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/core/usecases/usecase.dart';
import 'package:urban_cafe/features/pos/domain/repositories/pos_repository.dart';

class SyncPosOrders extends UseCase<int, NoParams> {
  final PosRepository repository;
  SyncPosOrders(this.repository);

  @override
  Future<Either<Failure, int>> call(NoParams params) {
    return repository.syncOfflineOrders();
  }
}
