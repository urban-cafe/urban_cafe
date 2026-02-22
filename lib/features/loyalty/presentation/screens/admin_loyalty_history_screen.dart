import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/features/loyalty/domain/entities/loyalty_transaction.dart';
import 'package:urban_cafe/features/loyalty/presentation/providers/loyalty_provider.dart';

class AdminLoyaltyHistoryScreen extends StatefulWidget {
  const AdminLoyaltyHistoryScreen({super.key});

  @override
  State<AdminLoyaltyHistoryScreen> createState() => _AdminLoyaltyHistoryScreenState();
}

class _AdminLoyaltyHistoryScreenState extends State<AdminLoyaltyHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LoyaltyProvider>().fetchHistory(); // null userId fetches global ledger
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final loyalty = context.watch<LoyaltyProvider>();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text('Global Transaction Ledger', style: theme.textTheme.titleMedium),
        centerTitle: true,
        backgroundColor: cs.surface,
        scrolledUnderElevation: 0,
      ),
      body: loyalty.isLoadingHistory
          ? const Center(child: CircularProgressIndicator())
          : loyalty.historyError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 60, color: cs.error),
                    const SizedBox(height: 16),
                    Text(
                      loyalty.historyError!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(color: cs.error),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        context.read<LoyaltyProvider>().fetchHistory();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : loyalty.history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 80, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('No transactions yet.', style: theme.textTheme.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await context.read<LoyaltyProvider>().fetchHistory();
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                itemCount: loyalty.history.length,
                separatorBuilder: (context, _) => const Divider(height: 32),
                itemBuilder: (context, index) {
                  final tx = loyalty.history[index];
                  return _TransactionTile(tx: tx, cs: cs, theme: theme);
                },
              ),
            ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.tx, required this.cs, required this.theme});

  final LoyaltyTransaction tx;
  final ColorScheme cs;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final isEarned = tx.isEarned;
    final color = isEarned ? Colors.green.shade600 : cs.error;
    final icon = isEarned ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded;
    final sign = isEarned ? '+' : '-';

    // Admin view shows customer name
    final customerName = tx.profile?.fullName ?? 'Unknown Customer';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(customerName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('${tx.description} • ${dateFormat.format(tx.createdAt.toLocal())}', style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Text(
          '$sign${tx.points}',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
