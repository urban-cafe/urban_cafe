import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/core/usecases/usecase.dart';
import 'package:urban_cafe/domain/entities/user_role.dart';
import 'package:urban_cafe/domain/repositories/auth_repository.dart';

class SignInUseCase implements UseCase<UserRole, SignInParams> {
  final AuthRepository repository;

  SignInUseCase(this.repository);

  @override
  Future<Either<Failure, UserRole>> call(SignInParams params) async {
    return await repository.signIn(params.email, params.password);
  }
}

class SignInParams extends Equatable {
  final String email;
  final String password;

  const SignInParams({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}
