import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:urban_cafe/features/loyalty/domain/entities/point_token.dart';
import 'package:urban_cafe/features/loyalty/domain/entities/redemption_result.dart';
import 'package:urban_cafe/features/loyalty/domain/usecases/generate_point_token.dart';
import 'package:urban_cafe/features/loyalty/domain/usecases/process_point_transaction.dart';

class LoyaltyProvider extends ChangeNotifier {
  final GeneratePointToken _generatePointToken;
  final ProcessPointTransaction _processPointTransaction;

  LoyaltyProvider({required GeneratePointToken generatePointToken, required ProcessPointTransaction processPointTransaction})
    : _generatePointToken = generatePointToken,
      _processPointTransaction = processPointTransaction;

  // ─── QR Token State (Client) ─────────────────────────────────────
  PointToken? _currentToken;
  PointToken? get currentToken => _currentToken;

  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  Timer? _countdownTimer;
  Duration _timeRemaining = Duration.zero;
  Duration get timeRemaining => _timeRemaining;

  bool get hasActiveToken => _currentToken != null && !_currentToken!.isExpired && !_currentToken!.redeemed;

  String get formattedTimeRemaining {
    final minutes = _timeRemaining.inMinutes;
    final seconds = _timeRemaining.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // ─── Redemption State (Staff/Admin) ──────────────────────────────
  RedemptionResult? _lastRedemption;
  RedemptionResult? get lastRedemption => _lastRedemption;

  bool _isRedeeming = false;
  bool get isRedeeming => _isRedeeming;

  String? _redemptionError;
  String? get redemptionError => _redemptionError;

  // ─── Settings State (Admin) ──────────────────────────────────────
  // Removed static point settings logic.

  String? _error;
  String? get error => _error;

  // ─── Client Methods ──────────────────────────────────────────────

  Future<void> generateQrToken() async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _generatePointToken();
      result.fold(
        (failure) {
          _error = _getUserFriendlyError(failure.message);
          _currentToken = null;
        },
        (token) {
          _currentToken = token;
          _startCountdown();
        },
      );
    } catch (e) {
      _error = 'Failed to generate QR code. Please try again.';
      _currentToken = null;
      debugPrint('[LoyaltyProvider] Generate QR error: $e');
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    if (_currentToken == null) return;

    _timeRemaining = _currentToken!.timeRemaining;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_currentToken == null || _currentToken!.isExpired) {
        _countdownTimer?.cancel();
        _timeRemaining = Duration.zero;
        notifyListeners();
        return;
      }
      _timeRemaining = _currentToken!.timeRemaining;
      notifyListeners();
    });
  }

  // ─── Staff/Admin Methods ─────────────────────────────────────────

  Future<bool> processScannedToken(String token, int points, bool isAward) async {
    _isRedeeming = true;
    _redemptionError = null;
    _lastRedemption = null;
    notifyListeners();

    bool success = false;

    try {
      final result = await _processPointTransaction(token, points, isAward);

      result.fold(
        (failure) {
          _redemptionError = _getUserFriendlyError(failure.message);
        },
        (redemption) {
          _lastRedemption = redemption;
          success = true;
        },
      );
    } catch (e) {
      _redemptionError = 'Failed to process points. Please try again.';
      debugPrint('[LoyaltyProvider] Process token error: $e');
    } finally {
      _isRedeeming = false;
      notifyListeners();
    }

    return success;
  }

  void clearRedemption() {
    _lastRedemption = null;
    _redemptionError = null;
    notifyListeners();
  }

  // Settings Methods removed.
  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _getUserFriendlyError(String technicalError) {
    final lowerError = technicalError.toLowerCase();

    if (lowerError.contains('network') || lowerError.contains('connection') || lowerError.contains('timeout')) {
      return 'Connection failed. Please check your internet and try again.';
    }

    if (lowerError.contains('expired') || lowerError.contains('invalid token')) {
      return 'QR code has expired. Please generate a new one.';
    }

    if (lowerError.contains('already redeemed') || lowerError.contains('already used')) {
      return 'This QR code has already been used.';
    }

    // Return original message if no mapping found
    return technicalError;
  }
}
