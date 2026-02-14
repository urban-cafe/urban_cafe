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
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Color(0xFF2E7D32), size: 32),
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
            _receiptRow('Order', order?.isSynced == true ? '#${order!.id!.substring(0, 8)}' : 'Offline (pending sync)'),
            _receiptRow('Time', _formatTime(order?.createdAt ?? DateTime.now())),
            _receiptRow('Payment', paymentMethod.label),
            const Divider(),
            _receiptRow('Total', '${total.toStringAsFixed(0)} Ks', isBold: true),
            if (paymentMethod == PosPaymentMethod.cash) ...[
              _receiptRow('Cash Tendered', '${cashTendered.toStringAsFixed(0)} Ks'),
              _receiptRow('Change', '${change.toStringAsFixed(0)} Ks', valueColor: const Color(0xFF2E7D32)),
            ],
            const Divider(),
            if (order?.isSynced == false)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: AppRadius.smAll),
                child: const Row(
                  children: [
                    Icon(Icons.cloud_off, size: 16, color: Colors.amber),
                    SizedBox(width: 6),
                    Expanded(child: Text('Saved offline. Will sync when connected.', style: TextStyle(fontSize: 12))),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('New Sale'),
          ),
        ),
      ],
    );
  }

  Widget _receiptRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant, fontWeight: isBold ? FontWeight.w700 : FontWeight.w400),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.w800 : FontWeight.w600, color: valueColor),
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
