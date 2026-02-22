import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:urban_cafe/features/loyalty/domain/entities/loyalty_transaction.dart';
import 'package:urban_cafe/features/loyalty/domain/entities/point_token.dart';
import 'package:urban_cafe/features/loyalty/domain/entities/redemption_result.dart';
import 'package:urban_cafe/features/loyalty/domain/usecases/generate_point_token.dart';
import 'package:urban_cafe/features/loyalty/domain/usecases/get_loyalty_history_usecase.dart';
import 'package:urban_cafe/features/loyalty/domain/usecases/process_point_transaction.dart';

class LoyaltyProvider extends ChangeNotifier {
  final GeneratePointToken _generatePointToken;
  final ProcessPointTransaction _processPointTransaction;
  final GetLoyaltyHistoryUseCase _getLoyaltyHistoryUseCase;

  LoyaltyProvider({required GeneratePointToken generatePointToken, required ProcessPointTransaction processPointTransaction, required GetLoyaltyHistoryUseCase getLoyaltyHistoryUseCase})
    : _generatePointToken = generatePointToken,
      _processPointTransaction = processPointTransaction,
      _getLoyaltyHistoryUseCase = getLoyaltyHistoryUseCase;

  // ─── QR Token State (Client) ─────────────────────────────────────
  PointToken? _currentToken;
  PointToken? get currentToken => _currentToken;

  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  Timer? _countdownTimer;

  bool get hasActiveToken => _currentToken != null && !_currentToken!.isExpired && !_currentToken!.redeemed;

  // ─── Redemption State (Staff/Admin) ──────────────────────────────
  RedemptionResult? _lastRedemption;
  RedemptionResult? get lastRedemption => _lastRedemption;

  bool _isRedeeming = false;
  bool get isRedeeming => _isRedeeming;

  String? _redemptionError;
  String? get redemptionError => _redemptionError;

  // ─── History State ───────────────────────────────────────────────
  List<LoyaltyTransaction> _history = [];
  List<LoyaltyTransaction> get history => _history;

  bool _isLoadingHistory = false;
  bool get isLoadingHistory => _isLoadingHistory;

  String? _historyError;
  String? get historyError => _historyError;

  int _currentPage = 0;
  static const int _pageSize = 20;
  bool _hasMoreHistory = true;
  bool get hasMoreHistory => _hasMoreHistory;

  DateTime? _filterStartDate;
  DateTime? get filterStartDate => _filterStartDate;
  DateTime? _filterEndDate;
  DateTime? get filterEndDate => _filterEndDate;

  String? _error;
  String? get error => _error;

  // ─── QR Token Fetching ───────────────────────────────────────────

  Future<void> generateQrToken() async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _generatePointToken();

      result.fold(
        (failure) {
          _error = _getUserFriendlyError(failure.message);
        },
        (token) {
          _currentToken = token;
          _startCountdown();
        },
      );
    } catch (e) {
      _error = 'Failed to generate QR code. Please try again.';
      debugPrint('[LoyaltyProvider] Generate token error: $e');
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_currentToken == null || _currentToken!.isExpired) {
        _countdownTimer?.cancel();
        _currentToken = null;
      }
      notifyListeners();
    });
  }

  Duration get timeRemaining => _currentToken?.timeRemaining ?? Duration.zero;

  String get formattedTimeRemaining {
    final remaining = timeRemaining;
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // ─── Transaction Processing ──────────────────────────────────────

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

  // ─── History Fetching ────────────────────────────────────────────

  /// Fetches the first page of history, resetting any existing data.
  Future<void> fetchHistory({String? userId}) async {
    _currentPage = 0;
    _hasMoreHistory = true;
    _history = [];
    _isLoadingHistory = true;
    _historyError = null;
    notifyListeners();

    await _loadHistoryPage(userId: userId);
  }

  /// Loads the next page of history, appending to existing data.
  Future<void> loadMoreHistory({String? userId}) async {
    if (!_hasMoreHistory || _isLoadingHistory) return;
    _currentPage++;
    _isLoadingHistory = true;
    notifyListeners();

    await _loadHistoryPage(userId: userId);
  }

  /// Sets a date filter and re-fetches history.
  void setDateFilter({DateTime? start, DateTime? end}) {
    _filterStartDate = start;
    _filterEndDate = end;
    fetchHistory(); // Re-fetch history with new filters
  }

  void clearDateFilter() {
    _filterStartDate = null;
    _filterEndDate = null;
    fetchHistory(); // Re-fetch history without filters
  }

  Future<void> _loadHistoryPage({String? userId}) async {
    try {
      final result = await _getLoyaltyHistoryUseCase(userId: userId, page: _currentPage, pageSize: _pageSize, startDate: _filterStartDate, endDate: _filterEndDate);

      result.fold(
        (failure) {
          _historyError = _getUserFriendlyError(failure.message);
        },
        (historyData) {
          _history.addAll(historyData);
          _hasMoreHistory = historyData.length >= _pageSize;
        },
      );
    } catch (e) {
      _historyError = 'Failed to load transaction history.';
      debugPrint('[LoyaltyProvider] Fetch history error: $e');
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
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
