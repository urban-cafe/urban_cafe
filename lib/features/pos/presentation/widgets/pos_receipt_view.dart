import 'package:flutter/material.dart';
import 'package:urban_cafe/core/theme.dart';
import 'package:urban_cafe/features/pos/domain/entities/pos_order.dart';

class PosReceiptView extends StatelessWidget {
  final PosOrder? order;
  final double total;
  final PosPaymentMethod paymentMethod;
  final double cashTendered;
  final double change;

  const PosReceiptView({super.key, this.order, required this.total, required this.paymentMethod, this.cashTendered = 0, this.change = 0});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final successColor = isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
    final successBg = isDark ? const Color(0xFF1B3A1E) : const Color(0xFFE8F5E9);

    return AlertDialog(
      title: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: successBg, shape: BoxShape.circle),
            child: Icon(Icons.check, color: successColor, size: 32),
          ),
          const SizedBox(height: 12),
          const Text('Sale Complete!', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        ],
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(),
            _receiptRow(cs, 'Order', order?.isSynced == true ? '#${order!.id!.substring(0, 8)}' : 'Offline (pending sync)'),
            _receiptRow(cs, 'Time', _formatTime(order?.createdAt ?? DateTime.now())),
            _receiptRow(cs, 'Payment', paymentMethod.label),
            const Divider(),
            _receiptRow(cs, 'Total', '${total.toStringAsFixed(0)} Ks', isBold: true),
            if (paymentMethod == PosPaymentMethod.cash) ...[
              _receiptRow(cs, 'Cash Tendered', '${cashTendered.toStringAsFixed(0)} Ks'),
              _receiptRow(cs, 'Change', '${change.toStringAsFixed(0)} Ks', valueColor: successColor),
            ],
            const Divider(),
            if (order?.isSynced == false)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(color: isDark ? Colors.amber.withValues(alpha: 0.1) : Colors.amber.withValues(alpha: 0.15), borderRadius: AppRadius.smAll),
                child: Row(
                  children: [
                    Icon(Icons.cloud_off, size: 16, color: isDark ? Colors.amber[300] : Colors.amber),
                    const SizedBox(width: 6),
                    const Expanded(child: Text('Saved offline. Will sync when connected.', style: TextStyle(fontSize: 12))),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('New Sale')),
        ),
      ],
    );
  }

  Widget _receiptRow(ColorScheme cs, String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, fontWeight: isBold ? FontWeight.w700 : FontWeight.w400),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.w800 : FontWeight.w600, color: valueColor ?? cs.onSurface),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${h == 0 ? 12 : h}:${dt.minute.toString().padLeft(2, '0')} $amPm';
  }
}
