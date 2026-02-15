import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:urban_cafe/core/theme.dart';
import 'package:urban_cafe/features/pos/domain/entities/pos_order.dart';
import 'package:urban_cafe/features/pos/presentation/providers/pos_provider.dart';
import 'package:urban_cafe/features/pos/presentation/widgets/pos_receipt_view.dart';

class PosPaymentDialog extends StatefulWidget {
  final double total;
  final PosProvider posProvider;
  const PosPaymentDialog({super.key, required this.total, required this.posProvider});

  @override
  State<PosPaymentDialog> createState() => _PosPaymentDialogState();
}

class _PosPaymentDialogState extends State<PosPaymentDialog> {
  PosPaymentMethod _method = PosPaymentMethod.cash;
  final _cashController = TextEditingController();
  double _change = 0;
  bool _isProcessing = false;

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  void _calculateChange() {
    final tendered = double.tryParse(_cashController.text) ?? 0;
    setState(() => _change = (tendered - widget.total).clamp(0.0, double.infinity));
  }

  Future<void> _completePayment() async {
    setState(() => _isProcessing = true);

    final cashTendered = _method == PosPaymentMethod.cash ? (double.tryParse(_cashController.text) ?? widget.total) : 0.0;

    if (_method == PosPaymentMethod.cash && cashTendered < widget.total) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient amount')));
      return;
    }

    final success = await widget.posProvider.completeOrder(paymentMethod: _method, cashTendered: cashTendered);

    if (success && mounted) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (_) => PosReceiptView(
          order: widget.posProvider.lastCompletedOrder,
          total: widget.total,
          paymentMethod: _method,
          cashTendered: cashTendered,
          change: _method == PosPaymentMethod.cash ? cashTendered - widget.total : 0,
        ),
      );
    } else if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.posProvider.error ?? 'Failed to process order')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final successColor = isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
    final successBg = isDark ? const Color(0xFF1B3A1E) : const Color(0xFFE8F5E9);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.payment, color: cs.primary),
          const SizedBox(width: 8),
          const Text('Payment', style: TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Total display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.5), borderRadius: AppRadius.mdAll),
              child: Column(
                children: [
                  Text('Total Amount', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.total.toStringAsFixed(0)} Ks',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: cs.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Payment method selection
            Row(
              children: [
                Expanded(
                  child: _PaymentMethodButton(
                    method: PosPaymentMethod.cash,
                    icon: Icons.money,
                    isSelected: _method == PosPaymentMethod.cash,
                    onTap: () => setState(() => _method = PosPaymentMethod.cash),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PaymentMethodButton(
                    method: PosPaymentMethod.card,
                    icon: Icons.credit_card,
                    isSelected: _method == PosPaymentMethod.card,
                    onTap: () => setState(() => _method = PosPaymentMethod.card),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Cash tendered input (only for cash)
            if (_method == PosPaymentMethod.cash) ...[
              TextField(
                controller: _cashController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                onChanged: (_) => _calculateChange(),
                decoration: InputDecoration(
                  labelText: 'Cash Tendered',
                  suffixText: 'Ks',
                  border: OutlineInputBorder(borderRadius: AppRadius.smAll),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(height: 12),
              // Quick amount buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickAmounts
                    .map(
                      (amt) => ActionChip(
                        label: Text(amt.toStringAsFixed(0)),
                        onPressed: () {
                          _cashController.text = amt.toStringAsFixed(0);
                          _calculateChange();
                        },
                        backgroundColor: cs.surfaceContainerHighest,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              // Change display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: _change > 0 ? successBg : cs.surfaceContainerHighest.withValues(alpha: 0.3), borderRadius: AppRadius.smAll),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Change:', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      '${_change.toStringAsFixed(0)} Ks',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _change > 0 ? successColor : cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _isProcessing ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _isProcessing ? null : _completePayment,
          style: FilledButton.styleFrom(backgroundColor: successColor),
          child: _isProcessing ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Complete Sale'),
        ),
      ],
    );
  }

  List<double> get _quickAmounts {
    final total = widget.total;
    final rounded = (total / 500).ceil() * 500;
    return {total, rounded.toDouble(), (rounded + 500).toDouble(), (rounded + 1000).toDouble()}.take(4).toList();
  }
}

class _PaymentMethodButton extends StatelessWidget {
  final PosPaymentMethod method;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _PaymentMethodButton({required this.method, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: isSelected ? cs.primaryContainer : cs.surface,
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: isSelected ? cs.primary : cs.outlineVariant, width: isSelected ? 2 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? cs.primary : cs.onSurfaceVariant, size: 28),
              const SizedBox(height: 4),
              Text(
                method.label,
                style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? cs.primary : cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
