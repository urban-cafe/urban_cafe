import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urban_cafe/core/env.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/features/auth/domain/entities/user_profile.dart';
import 'package:urban_cafe/features/auth/domain/entities/user_role.dart';
import 'package:urban_cafe/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient supabaseClient;

  AuthRepositoryImpl({required this.supabaseClient});

  @override
  Future<Either<Failure, UserRole>> getCurrentUserRole() async {
    try {
      if (supabaseClient.auth.currentUser == null) {
        return const Left(AuthFailure('User not logged in'));
      }

      final userId = supabaseClient.auth.currentUser!.id;
      final response = await supabaseClient.from('profiles').select().eq('id', userId).single();
      final profile = UserProfile.fromJson(response);
      return Right(profile.role);
    } catch (e) {
      // Default to client if profile not found or error
      return const Right(UserRole.client);
    }
  }

  @override
  Future<Either<Failure, UserProfile>> getUserProfile() async {
    try {
      if (supabaseClient.auth.currentUser == null) {
        return const Left(AuthFailure('User not logged in'));
      }

      final userId = supabaseClient.auth.currentUser!.id;
      final response = await supabaseClient.from('profiles').select().eq('id', userId).single();
      final profile = UserProfile.fromJson(response);
      return Right(profile);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isSignedIn() async {
    return Right(supabaseClient.auth.currentUser != null);
  }

  @override
  Future<Either<Failure, UserRole>> signIn(String email, String password) async {
    if (!Env.isConfigured) return const Left(AuthFailure('Supabase not configured'));

    try {
      await supabaseClient.auth.signInWithPassword(email: email, password: password);
      return getCurrentUserRole();
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> signInWithGoogle() async {
    if (!Env.isConfigured) return const Left(AuthFailure('Supabase not configured'));

    try {
      final bool result = await supabaseClient.auth.signInWithOAuth(OAuthProvider.google, redirectTo: kIsWeb ? null : 'io.supabase.urbancafe://login-callback/');
      return Right(result);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    if (!Env.isConfigured) return const Left(AuthFailure('Supabase not configured'));

    try {
      await supabaseClient.auth.signOut();
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}
