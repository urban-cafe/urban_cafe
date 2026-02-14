import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/core/usecases/usecase.dart';
import 'package:urban_cafe/features/auth/domain/entities/user_role.dart';
import 'package:urban_cafe/features/auth/domain/repositories/auth_repository.dart';

class SignInAnonymouslyUseCase implements UseCase<UserRole, NoParams> {
  final AuthRepository repository;

  SignInAnonymouslyUseCase(this.repository);

  @override
  Future<Either<Failure, UserRole>> call(NoParams params) async {
    return await repository.signInAnonymously();
  }
}
