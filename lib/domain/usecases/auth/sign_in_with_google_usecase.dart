import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/core/usecases/usecase.dart';
import 'package:urban_cafe/domain/repositories/auth_repository.dart';

class SignInWithGoogleUseCase implements UseCase<bool, NoParams> {
  final AuthRepository repository;

  SignInWithGoogleUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    return await repository.signInWithGoogle();
  }
}
