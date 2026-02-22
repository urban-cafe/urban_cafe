import 'dart:math';

import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urban_cafe/core/error/failures.dart';
import 'package:urban_cafe/features/loyalty/domain/entities/loyalty_transaction.dart';
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
  Future<Either<Failure, RedemptionResult>> processPointTransaction(String token, int points, bool isAward) async {
    try {
      final response = await _client.rpc('process_point_transaction', params: {'p_token': token, 'p_points': points, 'p_is_award': isAward});

      final result = RedemptionResult.fromJson(response as Map<String, dynamic>);
      if (!result.success) {
        return Left(ServerFailure(result.message ?? 'Failed to process point transaction'));
      }
      return Right(result);
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Failed to process point transaction', devMessage: e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to process point transaction', devMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LoyaltyTransaction>>> getTransactionHistory({String? userId, int page = 0, int pageSize = 20, DateTime? startDate, DateTime? endDate}) async {
    try {
      // Join customer profile (profiles) and staff profile (staff:profiles!staff_id)
      var query = _client
          .from('loyalty_transactions')
          .select(
            '*, profiles!loyalty_transactions_user_id_fkey(id, role, loyalty_points, full_name, phone_number, address), staff:profiles!loyalty_transactions_staff_id_fkey(id, role, loyalty_points, full_name, phone_number, address)',
          );

      // Filter by user if provided (Personal History)
      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      // Date range filtering
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        // Add 1 day to include the entire end date
        final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        query = query.lte('created_at', endOfDay.toIso8601String());
      }

      // Pagination
      final from = page * pageSize;
      final to = from + pageSize - 1;

      final response = await query.order('created_at', ascending: false).range(from, to);

      final List<LoyaltyTransaction> transactions = response.map((json) => LoyaltyTransaction.fromJson(json)).toList();

      return Right(transactions);
    } on PostgrestException catch (e) {
      return Left(ServerFailure('Failed to fetch transaction history', devMessage: e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to fetch transaction history', devMessage: e.toString()));
    }
  }
}
