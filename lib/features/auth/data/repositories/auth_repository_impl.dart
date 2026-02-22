import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urban_cafe/core/env.dart';
import 'package:urban_cafe/core/error/app_exception.dart';
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
        return const Left(AuthFailure('Please sign in to continue.', code: 'auth_not_logged_in'));
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
        return const Left(AuthFailure('Please sign in to continue.', code: 'auth_not_logged_in'));
      }

      final userId = supabaseClient.auth.currentUser!.id;
      final response = await supabaseClient.from('profiles').select().eq('id', userId).single();
      final profile = UserProfile.fromJson(response);
      return Right(profile);
    } catch (e) {
      return Left(AppException.mapToFailure(e));
    }
  }

  @override
  Future<Either<Failure, bool>> isSignedIn() async {
    return Right(supabaseClient.auth.currentUser != null);
  }

  @override
  Future<Either<Failure, UserRole>> signIn(String email, String password) async {
    if (!Env.isConfigured) {
      return const Left(AuthFailure('App not configured. Please contact support.', code: 'env_not_configured'));
    }

    try {
      await supabaseClient.auth.signInWithPassword(email: email, password: password);
      return getCurrentUserRole();
    } catch (e) {
      return Left(AppException.mapToFailure(e));
    }
  }

  @override
  Future<Either<Failure, bool>> signInWithGoogle() async {
    if (!Env.isConfigured) {
      return const Left(AuthFailure('App not configured. Please contact support.', code: 'env_not_configured'));
    }

    try {
      if (kIsWeb) {
        // [WEB] Standard Supabase Browser OAuth flow
        final String redirectTo = '${Env.webUrl}/#/auth/callback';
        final bool result = await supabaseClient.auth.signInWithOAuth(OAuthProvider.google, redirectTo: redirectTo, authScreenLaunchMode: LaunchMode.platformDefault);
        return Right(result);
      } else {
        // [MOBILE / NATIVE] Triggers the beautiful native Google bottom sheet
        final GoogleSignIn googleSignIn = GoogleSignIn(serverClientId: Env.googleWebClientId);

        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) return const Left(AuthFailure('Sign in canceled by user.'));

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final String? idToken = googleAuth.idToken;
        final String? accessToken = googleAuth.accessToken;

        if (idToken == null || accessToken == null) {
          return const Left(AuthFailure('Missing Google Authentication Tokens.'));
        }

        // Send tokens from the native Google plugin directly into the Supabase database
        await supabaseClient.auth.signInWithIdToken(provider: OAuthProvider.google, idToken: idToken, accessToken: accessToken);

        return const Right(true);
      }
    } catch (e) {
      return Left(AppException.mapToFailure(e));
    }
  }

  @override
  Future<Either<Failure, UserRole>> signUp(String email, String password) async {
    if (!Env.isConfigured) {
      return const Left(AuthFailure('App not configured. Please contact support.', code: 'env_not_configured'));
    }

    try {
      final response = await supabaseClient.auth.signUp(email: email, password: password);

      // Check if email confirmation is required
      if (response.session == null) {
        // User created but needs to confirm email
        return const Left(AuthFailure('Account created! Please check your email to verify your account.', code: 'email_confirmation_required'));
      }

      // User is signed in immediately (email confirmation disabled)
      return getCurrentUserRole();
    } catch (e) {
      return Left(AppException.mapToFailure(e));
    }
  }

  @override
  Future<Either<Failure, UserRole>> signInAnonymously() async {
    if (!Env.isConfigured) {
      return const Left(AuthFailure('App not configured. Please contact support.', code: 'env_not_configured'));
    }

    try {
      await supabaseClient.auth.signInAnonymously();
      // Anonymous users don't have a profile — default to client role
      return const Right(UserRole.client);
    } catch (e) {
      return Left(AppException.mapToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    if (!Env.isConfigured) {
      return const Left(AuthFailure('App not configured. Please contact support.', code: 'env_not_configured'));
    }

    try {
      // Clear cached Google credential so the account picker shows next time
      if (!kIsWeb) {
        try {
          await GoogleSignIn().signOut();
        } catch (_) {
          // Ignore — user may not have signed in with Google
        }
      }
      await supabaseClient.auth.signOut();
      return const Right(null);
    } catch (e) {
      return Left(AppException.mapToFailure(e));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> updateProfile(UserProfile profile) async {
    if (!Env.isConfigured) {
      return const Left(AuthFailure('App not configured. Please contact support.', code: 'env_not_configured'));
    }

    try {
      final userId = supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        return const Left(AuthFailure('Please sign in to continue.', code: 'auth_not_logged_in'));
      }

      await supabaseClient
          .from('profiles')
          .update({'full_name': profile.fullName, 'phone_number': profile.phoneNumber, 'address': profile.address, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', userId);

      return Right(profile);
    } catch (e) {
      return Left(AppException.mapToFailure(e));
    }
  }
}
