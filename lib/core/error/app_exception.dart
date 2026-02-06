import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urban_cafe/core/error/failures.dart';

/// Centralized exception mapper for user-friendly error messages.
///
/// Maps various exception types to appropriate [Failure] objects
/// with both developer-readable and user-friendly messages.
class AppException {
  AppException._();

  /// Maps any exception to an appropriate [Failure] with user-friendly message.
  static Failure mapToFailure(Object error, {String? context}) {
    // Network errors
    if (error is SocketException) {
      return const NetworkFailure('No internet connection. Please check your network.', code: 'network_socket_error');
    }

    if (error is TimeoutException) {
      return const NetworkFailure('Request timed out. Please try again.', code: 'network_timeout');
    }

    // Supabase Auth errors
    if (error is AuthException) {
      return _mapAuthException(error);
    }

    // Supabase Database errors
    if (error is PostgrestException) {
      return _mapPostgrestException(error);
    }

    // Supabase Storage errors
    if (error is StorageException) {
      return ServerFailure('Failed to upload file. Please try again.', code: 'storage_error', devMessage: error.message);
    }

    // Format exceptions (JSON parsing, etc.)
    if (error is FormatException) {
      return ServerFailure('Invalid data received. Please try again.', code: 'format_error', devMessage: error.message);
    }

    // Generic fallback
    return ServerFailure('Something went wrong. Please try again.', code: 'unknown_error', devMessage: error.toString());
  }

  /// Maps Supabase AuthException to user-friendly failures
  static Failure _mapAuthException(AuthException error) {
    final message = error.message.toLowerCase();

    // Invalid credentials
    if (message.contains('invalid login') || message.contains('invalid_credentials') || message.contains('incorrect')) {
      return const AuthFailure('Incorrect email or password.', code: 'auth_invalid_credentials');
    }

    // User not found
    if (message.contains('user not found') || message.contains('no user')) {
      return const AuthFailure('No account found with this email.', code: 'auth_user_not_found');
    }

    // Email already exists
    if (message.contains('already registered') || message.contains('already exists')) {
      return const AuthFailure('An account with this email already exists.', code: 'auth_email_exists');
    }

    // Email not confirmed
    if (message.contains('email not confirmed')) {
      return const AuthFailure('Please verify your email before signing in.', code: 'auth_email_not_confirmed');
    }

    // Too many requests
    if (message.contains('too many requests') || message.contains('rate limit')) {
      return const AuthFailure('Too many attempts. Please wait a moment and try again.', code: 'auth_rate_limit');
    }

    // Session expired
    if (message.contains('session') && message.contains('expired')) {
      return const AuthFailure('Your session has expired. Please sign in again.', code: 'auth_session_expired');
    }

    // Generic auth error
    return AuthFailure(error.message, code: 'auth_error');
  }

  /// Maps Supabase PostgrestException to user-friendly failures
  static Failure _mapPostgrestException(PostgrestException error) {
    final code = error.code;

    // Unique constraint violation (duplicate)
    if (code == '23505') {
      return const ServerFailure('This item already exists.', code: 'db_duplicate');
    }

    // Foreign key violation
    if (code == '23503') {
      return const ServerFailure('Cannot complete this action. Related data exists.', code: 'db_foreign_key');
    }

    // Not null violation
    if (code == '23502') {
      return const ServerFailure('Required information is missing.', code: 'db_not_null');
    }

    // Permission denied (RLS)
    if (code == '42501' || error.message.contains('permission denied')) {
      return const AuthFailure('You don\'t have permission to perform this action.', code: 'db_permission_denied');
    }

    // Connection error
    if (error.message.contains('connection') || error.message.contains('network')) {
      return const NetworkFailure('Connection error. Please check your internet.', code: 'db_connection');
    }

    // Generic database error
    return ServerFailure('Something went wrong. Please try again.', code: 'db_error', devMessage: '${error.code}: ${error.message}');
  }
}
