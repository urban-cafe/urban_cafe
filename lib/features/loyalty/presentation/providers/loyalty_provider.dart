import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:urban_cafe/features/loyalty/domain/entities/point_settings.dart';
import 'package:urban_cafe/features/loyalty/domain/entities/point_token.dart';
import 'package:urban_cafe/features/loyalty/domain/entities/redemption_result.dart';
import 'package:urban_cafe/features/loyalty/domain/usecases/generate_point_token.dart';
import 'package:urban_cafe/features/loyalty/domain/usecases/get_point_settings.dart';
import 'package:urban_cafe/features/loyalty/domain/usecases/redeem_point_token.dart';
import 'package:urban_cafe/features/loyalty/domain/usecases/update_point_settings.dart';

class LoyaltyProvider extends ChangeNotifier {
  final GeneratePointToken _generatePointToken;
  final RedeemPointToken _redeemPointToken;
  final GetPointSettings _getPointSettings;
  final UpdatePointSettings _updatePointSettings;

  LoyaltyProvider({
    required GeneratePointToken generatePointToken,
    required RedeemPointToken redeemPointToken,
    required GetPointSettings getPointSettings,
    required UpdatePointSettings updatePointSettings,
  }) : _generatePointToken = generatePointToken,
       _redeemPointToken = redeemPointToken,
       _getPointSettings = getPointSettings,
       _updatePointSettings = updatePointSettings;

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
  PointSettings? _settings;
  PointSettings? get settings => _settings;

  bool _isLoadingSettings = false;
  bool get isLoadingSettings => _isLoadingSettings;

  bool _isSavingSettings = false;
  bool get isSavingSettings => _isSavingSettings;

  String? _error;
  String? get error => _error;

  // ─── Client Methods ──────────────────────────────────────────────

  Future<void> generateQrToken() async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

    final result = await _generatePointToken();
    result.fold(
      (failure) {
        _error = failure.message;
        _currentToken = null;
      },
      (token) {
        _currentToken = token;
        _startCountdown();
      },
    );

    _isGenerating = false;
    notifyListeners();
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

  Future<bool> redeemScannedToken(String token, double purchaseAmount) async {
    _isRedeeming = true;
    _redemptionError = null;
    _lastRedemption = null;
    notifyListeners();

    final result = await _redeemPointToken(token, purchaseAmount);
    bool success = false;

    result.fold(
      (failure) {
        _redemptionError = failure.message;
      },
      (redemption) {
        _lastRedemption = redemption;
        success = true;
      },
    );

    _isRedeeming = false;
    notifyListeners();
    return success;
  }

  void clearRedemption() {
    _lastRedemption = null;
    _redemptionError = null;
    notifyListeners();
  }

  // ─── Settings Methods (Admin) ────────────────────────────────────

  Future<void> loadSettings() async {
    _isLoadingSettings = true;
    notifyListeners();

    final result = await _getPointSettings();
    result.fold((failure) => _error = failure.message, (settings) => _settings = settings);

    _isLoadingSettings = false;
    notifyListeners();
  }

  Future<bool> saveSettings({required int pointsPerUnit, required double amountPerPoint}) async {
    if (_settings == null) return false;

    _isSavingSettings = true;
    notifyListeners();

    final updated = PointSettings(id: _settings!.id, pointsPerUnit: pointsPerUnit, amountPerPoint: amountPerPoint);

    final result = await _updatePointSettings(updated);
    bool success = false;

    result.fold((failure) => _error = failure.message, (settings) {
      _settings = settings;
      success = true;
    });

    _isSavingSettings = false;
    notifyListeners();
    return success;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
