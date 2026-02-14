import 'dart:math';

import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/features/loyalty/domain/entities/point_settings.dart';
import 'package:urban_cafe/features/loyalty/domain/entities/point_token.dart';
import 'package:urban_cafe/features/loyalty/domain/entities/redemption_result.dart';
import 'package:urban_cafe/features/loyalty/domain/repositories/loyalty_repository.dart';

class LoyaltyRepositoryImpl implements LoyaltyRepository {
  final SupabaseClient _client;

  LoyaltyRepositoryImpl(this._client);

  /// Generates a cryptographically random token string.
  String _generateTokenString() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(32, (_) => chars[random.nextInt(chars.length)]).join();
  }

  @override
  Future<Either<Failure, PointToken>> generateToken() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Left(AuthFailure('You must be logged in to generate a QR code'));
      }

      final token = _generateTokenString();
      final expiresAt = DateTime.now().toUtc().add(const Duration(minutes: 5));

      final response = await _client.from('point_tokens').insert({'user_id': userId, 'token': token, 'expires_at': expiresAt.toIso8601String()}).select().single();

      return Right(PointToken.fromJson(response));
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Failed to generate QR code', devMessage: e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to generate QR code', devMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, RedemptionResult>> redeemToken(String token, double purchaseAmount) async {
    try {
      final response = await _client.rpc('redeem_point_token', params: {'p_token': token, 'p_purchase_amount': purchaseAmount});

      final result = RedemptionResult.fromJson(response as Map<String, dynamic>);
      if (!result.success) {
        return Left(ServerFailure(result.message ?? 'Failed to redeem QR code'));
      }
      return Right(result);
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Failed to redeem QR code', devMessage: e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to redeem QR code', devMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PointSettings>> getPointSettings() async {
    try {
      final response = await _client.from('point_settings').select().limit(1).single();
      return Right(PointSettings.fromJson(response));
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Failed to load point settings', devMessage: e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to load point settings', devMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PointSettings>> updatePointSettings(PointSettings settings) async {
    try {
      final response = await _client.from('point_settings').update(settings.toJson()).eq('id', settings.id).select().single();
      return Right(PointSettings.fromJson(response));
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Failed to update point settings', devMessage: e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to update point settings', devMessage: e.toString()));
    }
  }
}
