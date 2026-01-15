import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/core/usecases/usecase.dart';
import 'package:urban_cafe/domain/repositories/auth_repository.dart';

class SignOutUseCase implements UseCase<void, NoParams> {
  final AuthRepository repository;

  SignOutUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.signOut();
  }
}
