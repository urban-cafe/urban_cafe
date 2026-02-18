import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:urban_cafe/features/auth/presentation/providers/auth_provider.dart';
import 'package:urban_cafe/features/loyalty/presentation/providers/loyalty_provider.dart';

/// Client screen: displays a QR code for staff/admin to scan and award points.
class QrDisplayScreen extends StatefulWidget {
  const QrDisplayScreen({super.key});

  @override
  State<QrDisplayScreen> createState() => _QrDisplayScreenState();
}

class _QrDisplayScreenState extends State<QrDisplayScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-generate token on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<LoyaltyProvider>();
      if (!provider.hasActiveToken) {
        provider.generateQrToken();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final loyalty = context.watch<LoyaltyProvider>();
    final auth = context.watch<AuthProvider>();
    final points = auth.profile?.loyaltyPoints ?? 0;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(title: Text('qr_code'.tr(), style: Theme.of(context).textTheme.titleMedium), centerTitle: true, backgroundColor: cs.surface, scrolledUnderElevation: 0),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Points balance card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [cs.primaryContainer, cs.secondaryContainer], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('your_points'.tr(), style: theme.textTheme.titleMedium?.copyWith(color: cs.onPrimaryContainer)),
                          const SizedBox(width: 8),
                          if (auth.loading)
                            SizedBox(height: 14, width: 14, child: CircularProgressIndicator(color: cs.onPrimaryContainer, strokeWidth: 2))
                          else
                            InkWell(
                              onTap: () => auth.refreshUser(),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                                child: Icon(Icons.refresh_rounded, size: 14, color: cs.onPrimaryContainer),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$points',
                        style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.onPrimaryContainer),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // QR Code section
                if (loyalty.isGenerating) const Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()) else if (loyalty.error != null) _buildErrorState(cs, theme, loyalty) else if (loyalty.hasActiveToken) _buildQrCode(cs, theme, loyalty) else _buildExpiredState(cs, theme, loyalty),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQrCode(ColorScheme cs, ThemeData theme, LoyaltyProvider loyalty) {
    final isExpiring = loyalty.timeRemaining.inSeconds <= 60;

    return Column(
      children: [
        // QR Code Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: cs.shadow.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: QrImageView(
            data: loyalty.currentToken!.token,
            version: QrVersions.auto,
            size: 220,
            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
          ),
        ),
        const SizedBox(height: 24),

        // Countdown timer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(color: isExpiring ? cs.errorContainer : cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_outlined, color: isExpiring ? cs.error : cs.onSurfaceVariant, size: 20),
              const SizedBox(width: 8),
              Text(
                '${'expires_in'.tr()} ${loyalty.formattedTimeRemaining}',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: isExpiring ? cs.error : cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Text(
          'show_qr_to_staff'.tr(),
          style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Refresh button
        OutlinedButton.icon(
          onPressed: loyalty.isGenerating ? null : () => loyalty.generateQrToken(),
          icon: const Icon(Icons.refresh_rounded),
          label: Text('generate_new_qr'.tr()),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  Widget _buildExpiredState(ColorScheme cs, ThemeData theme, LoyaltyProvider loyalty) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(24)),
          child: Column(
            children: [
              Icon(Icons.qr_code_2_rounded, size: 80, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text('qr_expired'.tr(), style: theme.textTheme.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 8),
              Text('tap_to_generate_new'.tr(), style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.7))),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => loyalty.generateQrToken(),
          icon: const Icon(Icons.qr_code_rounded),
          label: Text('generate_qr'.tr()),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(ColorScheme cs, ThemeData theme, LoyaltyProvider loyalty) {
    return Column(
      children: [
        Icon(Icons.error_outline_rounded, size: 64, color: cs.error),
        const SizedBox(height: 16),
        Text(
          loyalty.error!,
          style: theme.textTheme.bodyLarge?.copyWith(color: cs.error),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => loyalty.generateQrToken(),
          icon: const Icon(Icons.refresh_rounded),
          label: Text('try_again'.tr()),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }
}
