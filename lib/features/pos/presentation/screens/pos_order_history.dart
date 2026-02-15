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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text("Today's Sales", style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          // Summary Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [cs.primary, cs.primary.withValues(alpha: 0.85)]),
              borderRadius: AppRadius.lgAll,
              boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Today's Total", style: TextStyle(color: cs.onPrimary.withValues(alpha: 0.7), fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        '${posProvider.todayTotal.toStringAsFixed(0)} Ks',
                        style: TextStyle(color: cs.onPrimary, fontSize: 28, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: cs.onPrimary.withValues(alpha: 0.2), borderRadius: AppRadius.xlAll),
                  child: Text(
                    '${posProvider.todayOrders.length} sales',
                    style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // Orders List
          Expanded(
            child: posProvider.isLoadingHistory
                ? Center(child: CircularProgressIndicator(color: cs.primary))
                : posProvider.todayOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: cs.outline.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text('No sales today yet', style: TextStyle(color: cs.outline, fontSize: 16)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: posProvider.loadTodayOrders,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: posProvider.todayOrders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cashColor = isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
    final cashBg = isDark ? const Color(0xFF1B3A1E) : const Color(0xFFE8F5E9);
    final cardColor = isDark ? const Color(0xFF42A5F5) : const Color(0xFF1565C0);
    final cardBg = isDark ? const Color(0xFF0D2A4A) : const Color(0xFFE3F2FD);

    final isCash = order.paymentMethod == PosPaymentMethod.cash;

    return Card(
      elevation: 0.5,
      color: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: isCash ? cashBg : cardBg, borderRadius: AppRadius.smAll),
              child: Icon(isCash ? Icons.money : Icons.credit_card, color: isCash ? cashColor : cardColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.id != null ? '#${order.id!.substring(0, 8)}' : 'Pending',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: cs.onSurface),
                  ),
                  Text(_formatTime(order.createdAt), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${order.totalAmount.toStringAsFixed(0)} Ks',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: cs.onSurface),
                ),
                Text(order.paymentMethod.label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
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
