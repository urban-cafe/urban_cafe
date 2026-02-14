import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/core/usecases/usecase.dart';
import 'package:urban_cafe/features/pos/domain/entities/pos_order.dart';
import 'package:urban_cafe/features/pos/domain/repositories/pos_repository.dart';

class GetPosOrders extends UseCase<List<PosOrder>, NoParams> {
  final PosRepository repository;
  GetPosOrders(this.repository);

  @override
  Future<Either<Failure, List<PosOrder>>> call(NoParams params) {
    return repository.getPosOrders();
  }
}
