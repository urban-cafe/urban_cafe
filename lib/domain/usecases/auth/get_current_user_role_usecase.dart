import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/core/usecases/usecase.dart';
import 'package:urban_cafe/domain/entities/user_role.dart';
import 'package:urban_cafe/domain/repositories/auth_repository.dart';

class GetCurrentUserRoleUseCase implements UseCase<UserRole, NoParams> {
  final AuthRepository repository;

  GetCurrentUserRoleUseCase(this.repository);

  @override
  Future<Either<Failure, UserRole>> call(NoParams params) async {
    return await repository.getCurrentUserRole();
  }
}
