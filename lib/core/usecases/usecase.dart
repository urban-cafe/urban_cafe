import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';

abstract class UseCase<ResultType, Params> {
  Future<Either<Failure, ResultType>> call(Params params);
}

class NoParams {}
