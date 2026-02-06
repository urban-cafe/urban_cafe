import 'package:equatable/equatable.dart';

/// Base failure class with user-friendly and developer messages.
abstract class Failure extends Equatable {
  /// User-friendly message to display in UI
  final String message;

  /// Error code for tracking/analytics
  final String? code;

  /// Developer-only message (not shown to users)
  final String? devMessage;

  const Failure(this.message, {this.code, this.devMessage});

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() => devMessage ?? message;
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code, super.devMessage});

  /// Default server failure
  static const defaultFailure = ServerFailure('Something went wrong. Please try again.');
}

class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code, super.devMessage});

  /// Default cache failure
  static const defaultFailure = CacheFailure('Failed to load cached data.');
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code, super.devMessage});

  /// Default auth failure
  static const defaultFailure = AuthFailure('Authentication failed.');
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code, super.devMessage});

  /// Default network failure
  static const defaultFailure = NetworkFailure('No internet connection.');
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code, super.devMessage});

  /// Default validation failure
  static const defaultFailure = ValidationFailure('Please check your input.');
}
