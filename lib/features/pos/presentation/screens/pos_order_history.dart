import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/core/theme.dart';
import 'package:urban_cafe/features/pos/domain/entities/pos_order.dart';
import 'package:urban_cafe/features/pos/presentation/providers/pos_provider.dart';

class PosOrderHistory extends StatefulWidget {
  const PosOrderHistory({super.key});

  @override
  State<PosOrderHistory> createState() => _PosOrderHistoryState();
}

class _PosOrderHistoryState extends State<PosOrderHistory> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PosProvider>().loadTodayOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final posProvider = context.watch<PosProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Today's Sales", style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.onPrimary,
      ),
      body: Column(
        children: [
          // Summary Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.85)]),
              borderRadius: AppRadius.lgAll,
              boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Today's Total", style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        '${posProvider.todayTotal.toStringAsFixed(0)} Ks',
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: AppRadius.xlAll),
                  child: Text(
                    '${posProvider.todayOrders.length} sales',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // Orders List
          Expanded(
            child: posProvider.isLoadingHistory
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : posProvider.todayOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: AppTheme.outline.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text('No sales today yet', style: TextStyle(color: AppTheme.outline, fontSize: 16)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: posProvider.loadTodayOrders,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: posProvider.todayOrders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) => _OrderCard(order: posProvider.todayOrders[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final PosOrder order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: order.paymentMethod == PosPaymentMethod.cash ? const Color(0xFFE8F5E9) : const Color(0xFFE3F2FD), borderRadius: AppRadius.smAll),
              child: Icon(
                order.paymentMethod == PosPaymentMethod.cash ? Icons.money : Icons.credit_card,
                color: order.paymentMethod == PosPaymentMethod.cash ? const Color(0xFF2E7D32) : const Color(0xFF1565C0),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.id != null ? '#${order.id!.substring(0, 8)}' : 'Pending', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(_formatTime(order.createdAt), style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${order.totalAmount.toStringAsFixed(0)} Ks', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text(order.paymentMethod.label, style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${h == 0 ? 12 : h}:${dt.minute.toString().padLeft(2, '0')} $amPm';
  }
}
