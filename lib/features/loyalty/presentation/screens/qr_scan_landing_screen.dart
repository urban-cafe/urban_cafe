import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:urban_cafe/features/loyalty/presentation/screens/qr_scanner_screen.dart';

/// Landing screen shown when staff/admin taps the QR Scan nav item.
/// The camera is NOT opened until the user explicitly taps "Start Scanning".
class QrScanLandingScreen extends StatelessWidget {
  const QrScanLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text('qr_scan'.tr(), style: theme.textTheme.titleMedium),
        centerTitle: true,
        backgroundColor: cs.surface,
        scrolledUnderElevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: cs.primaryContainer, shape: BoxShape.circle),
                child: Icon(Icons.qr_code_scanner_rounded, size: 72, color: cs.onPrimaryContainer),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'scan_customer_qr'.tr(),
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                'scan_qr_description'.tr(),
                style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Start button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QrScannerScreen()));
                  },
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: Text('start_scanning'.tr()),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
