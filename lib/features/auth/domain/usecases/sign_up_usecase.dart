import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/core/usecases/usecase.dart';
import 'package:urban_cafe/features/auth/domain/entities/user_role.dart';
import 'package:urban_cafe/features/auth/domain/repositories/auth_repository.dart';

class SignUpUseCase implements UseCase<UserRole, SignUpParams> {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  @override
  Future<Either<Failure, UserRole>> call(SignUpParams params) async {
    return await repository.signUp(params.email, params.password);
  }
}

class SignUpParams extends Equatable {
  final String email;
  final String password;

  const SignUpParams({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}
