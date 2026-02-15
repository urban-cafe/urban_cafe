import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/features/loyalty/presentation/providers/loyalty_provider.dart';

/// Staff/Admin screen: scan client QR codes and award loyalty points.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _amountController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _scannedToken;
  bool _showAmountInput = false;

  @override
  void dispose() {
    _scannerController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_showAmountInput) return; // Already processing

    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue != null && barcode!.rawValue!.isNotEmpty) {
      setState(() {
        _scannedToken = barcode.rawValue!;
        _showAmountInput = true;
      });
      _scannerController.stop();
    }
  }

  Future<void> _awardPoints() async {
    if (!_formKey.currentState!.validate() || _scannedToken == null) return;

    final amount = double.parse(_amountController.text);
    final loyalty = context.read<LoyaltyProvider>();

    final success = await loyalty.redeemScannedToken(_scannedToken!, amount);

    if (!mounted) return;

    if (success) {
      _showSuccessDialog(loyalty);
    } else {
      _showErrorSnackBar(loyalty.redemptionError ?? 'unknown_error'.tr());
    }
  }

  void _showSuccessDialog(LoyaltyProvider loyalty) {
    final result = loyalty.lastRedemption;
    if (result == null) return;

    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
              child: Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 56),
            ),
            const SizedBox(height: 20),
            Text('points_awarded_title'.tr(), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _infoRow(theme, 'customer'.tr(), result.clientName ?? 'Customer'),
            _infoRow(theme, 'purchase_amount_label'.tr(), '${result.purchaseAmount?.toStringAsFixed(0)} MMK'),
            _infoRow(theme, 'points_given'.tr(), '+${result.pointsAwarded}'),
            _infoRow(theme, 'new_balance_label'.tr(), '${result.newBalance} ${'pts'.tr()}'),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetScanner();
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('scan_next'.tr()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    _resetScanner();
  }

  void _resetScanner() {
    setState(() {
      _scannedToken = null;
      _showAmountInput = false;
      _amountController.clear();
    });
    context.read<LoyaltyProvider>().clearRedemption();
    _scannerController.start();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final loyalty = context.watch<LoyaltyProvider>();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(title: Text('qr_scanner'.tr()), centerTitle: true, backgroundColor: cs.surface, scrolledUnderElevation: 0),
      body: _showAmountInput ? _buildAmountInput(theme, cs, loyalty) : _buildScanner(theme, cs),
    );
  }

  Widget _buildScanner(ThemeData theme, ColorScheme cs) {
    return Stack(
      children: [
        // Camera
        MobileScanner(controller: _scannerController, onDetect: _onDetect),

        // Overlay with scan area
        Container(
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: cs.primary, width: 3),
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(16)),
                  child: Text(
                    'scan_customer_qr'.tr(),
                    style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountInput(ThemeData theme, ColorScheme cs, LoyaltyProvider loyalty) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success scan indicator
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                child: Icon(Icons.qr_code_scanner_rounded, color: Colors.green.shade600, size: 48),
              ),
              const SizedBox(height: 16),
              Text('qr_scanned_successfully'.tr(), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('enter_purchase_amount'.tr(), style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 32),

              // Amount input
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '0',
                  suffixText: 'MMK',
                  suffixStyle: theme.textTheme.titleLarge?.copyWith(color: cs.onSurfaceVariant),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: cs.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: cs.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'amount_required'.tr();
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) return 'invalid_amount'.tr();
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: loyalty.isRedeeming ? null : _resetScanner,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('cancel'.tr()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: loyalty.isRedeeming ? null : _awardPoints,
                      icon: loyalty.isRedeeming
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.card_giftcard_rounded),
                      label: Text('award_points'.tr()),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
