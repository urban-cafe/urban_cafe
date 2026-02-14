import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/features/loyalty/presentation/providers/loyalty_provider.dart';

/// Admin screen: configure points-per-purchase-amount conversion rate.
class PointSettingsScreen extends StatefulWidget {
  const PointSettingsScreen({super.key});

  @override
  State<PointSettingsScreen> createState() => _PointSettingsScreenState();
}

class _PointSettingsScreenState extends State<PointSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pointsPerUnitCtrl = TextEditingController();
  final _amountPerPointCtrl = TextEditingController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LoyaltyProvider>().loadSettings();
    });
  }

  @override
  void dispose() {
    _pointsPerUnitCtrl.dispose();
    _amountPerPointCtrl.dispose();
    super.dispose();
  }

  void _initFields(LoyaltyProvider loyalty) {
    if (!_initialized && loyalty.settings != null) {
      _pointsPerUnitCtrl.text = loyalty.settings!.pointsPerUnit.toString();
      _amountPerPointCtrl.text = loyalty.settings!.amountPerPoint.toStringAsFixed(0);
      _initialized = true;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final loyalty = context.read<LoyaltyProvider>();
    final success = await loyalty.saveSettings(pointsPerUnit: int.parse(_pointsPerUnitCtrl.text), amountPerPoint: double.parse(_amountPerPointCtrl.text));

    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'settings_saved'.tr() : (loyalty.error ?? 'error_occurred'.tr())),
        backgroundColor: success ? Colors.green : cs.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final loyalty = context.watch<LoyaltyProvider>();

    _initFields(loyalty);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(title: Text('point_settings'.tr()), centerTitle: true),
      body: loyalty.isLoadingSettings
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cs.primaryContainer),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: cs.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('point_settings_info'.tr(), style: theme.textTheme.bodyMedium?.copyWith(color: cs.onPrimaryContainer)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Points per unit
                    Text('points_per_unit'.tr(), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('points_per_unit_hint'.tr(), style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _pointsPerUnitCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '1',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'field_required'.tr();
                        final n = int.tryParse(v);
                        if (n == null || n <= 0) return 'must_be_positive'.tr();
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Amount per point
                    Text('amount_per_point'.tr(), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('amount_per_point_hint'.tr(), style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountPerPointCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '1000',
                        suffixText: 'MMK',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'field_required'.tr();
                        final n = double.tryParse(v);
                        if (n == null || n <= 0) return 'must_be_positive'.tr();
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Preview
                    if (_pointsPerUnitCtrl.text.isNotEmpty && _amountPerPointCtrl.text.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('preview'.tr(), style: theme.textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
                            const SizedBox(height: 8),
                            Text(
                              'point_conversion_preview'.tr(args: [_amountPerPointCtrl.text, _pointsPerUnitCtrl.text]),
                              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 32),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: loyalty.isSavingSettings ? null : _save,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: loyalty.isSavingSettings ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('save_settings'.tr()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
