import 'package:fpdart/fpdart.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/features/auth/domain/entities/user_profile.dart';
import 'package:urban_cafe/features/auth/domain/entities/user_role.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserRole>> signIn(String email, String password);
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, UserRole>> getCurrentUserRole();
  Future<Either<Failure, UserProfile>> getUserProfile();
  Future<Either<Failure, bool>> signInWithGoogle();
  Future<Either<Failure, bool>> isSignedIn();
}
