import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:urban_cafe/features/auth/presentation/providers/auth_provider.dart';
import 'package:urban_cafe/features/loyalty/domain/entities/loyalty_transaction.dart';
import 'package:urban_cafe/features/loyalty/presentation/providers/loyalty_provider.dart';

class ClientLoyaltyHistoryScreen extends StatefulWidget {
  const ClientLoyaltyHistoryScreen({super.key});

  @override
  State<ClientLoyaltyHistoryScreen> createState() => _ClientLoyaltyHistoryScreenState();
}

class _ClientLoyaltyHistoryScreenState extends State<ClientLoyaltyHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  String? get _userId => context.read<AuthProvider>().currentUser?.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_userId != null) {
        context.read<LoyaltyProvider>().fetchHistory(userId: _userId);
      }
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (_userId != null) {
        context.read<LoyaltyProvider>().loadMoreHistory(userId: _userId);
      }
    }
  }

  Future<void> _pickDateRange() async {
    final loyalty = context.read<LoyaltyProvider>();
    final now = DateTime.now();
    DateTime tempStart = loyalty.filterStartDate ?? now.subtract(const Duration(days: 30));
    DateTime tempEnd = loyalty.filterEndDate ?? now;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final theme = Theme.of(ctx);
            final cs = theme.colorScheme;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 16),
                    Text('Filter by Date', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    _DatePickerRow(label: 'From', date: tempStart, maximumDate: tempEnd, onChanged: (d) => setSheetState(() => tempStart = d)),
                    const SizedBox(height: 12),
                    _DatePickerRow(label: 'To', date: tempEnd, minimumDate: tempStart, maximumDate: now, onChanged: (d) => setSheetState(() => tempEnd = d)),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          loyalty.setDateFilter(start: tempStart, end: tempEnd);
                          if (_userId != null) loyalty.fetchHistory(userId: _userId);
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Apply Filter'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final loyalty = context.watch<LoyaltyProvider>();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text('points_history'.tr(), style: theme.textTheme.titleMedium),
        centerTitle: true,
        backgroundColor: cs.surface,
        scrolledUnderElevation: 0,
        actions: [
          if (loyalty.filterStartDate != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off_rounded),
              tooltip: 'Clear Filter',
              onPressed: () {
                loyalty.clearDateFilter();
                if (_userId != null) {
                  loyalty.fetchHistory(userId: _userId);
                }
              },
            ),
          IconButton(icon: const Icon(Icons.date_range_rounded), tooltip: 'Filter by Date', onPressed: _pickDateRange),
        ],
      ),
      body: _buildBody(loyalty, cs, theme),
    );
  }

  Widget _buildBody(LoyaltyProvider loyalty, ColorScheme cs, ThemeData theme) {
    if (loyalty.isLoadingHistory && loyalty.history.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (loyalty.historyError != null && loyalty.history.isEmpty) {
      return Center(
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
                  if (_userId != null) {
                    context.read<LoyaltyProvider>().fetchHistory(userId: _userId);
                  }
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (loyalty.history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 80, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No transactions yet.', style: theme.textTheme.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    final hasFilter = loyalty.filterStartDate != null;
    final dateFormat = DateFormat('MMM dd');

    return Column(
      children: [
        if (hasFilter)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Chip(
              avatar: const Icon(Icons.calendar_today_rounded, size: 16),
              label: Text('${dateFormat.format(loyalty.filterStartDate!)} – ${dateFormat.format(loyalty.filterEndDate!)}'),
              onDeleted: () {
                loyalty.clearDateFilter();
                if (_userId != null) {
                  loyalty.fetchHistory(userId: _userId);
                }
              },
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              if (_userId != null) {
                await context.read<LoyaltyProvider>().fetchHistory(userId: _userId);
              }
            },
            child: ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: loyalty.history.length + (loyalty.hasMoreHistory ? 1 : 0),
              separatorBuilder: (context, _) => const Divider(height: 24),
              itemBuilder: (context, index) {
                if (index >= loyalty.history.length) {
                  return const Center(
                    child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
                  );
                }
                final tx = loyalty.history[index];
                return _TransactionTile(tx: tx, cs: cs, theme: theme);
              },
            ),
          ),
        ),
      ],
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

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEarned ? 'Points Earned' : 'Points Redeemed', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(dateFormat.format(tx.createdAt.toLocal()), style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 2),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Text(
          '$sign${tx.points.abs()} Points',
          style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

/// A tappable row that shows a label + date, and opens a CupertinoDatePicker.
class _DatePickerRow extends StatefulWidget {
  const _DatePickerRow({required this.label, required this.date, required this.onChanged, this.minimumDate, this.maximumDate});

  final String label;
  final DateTime date;
  final DateTime? minimumDate;
  final DateTime? maximumDate;
  final ValueChanged<DateTime> onChanged;

  @override
  State<_DatePickerRow> createState() => _DatePickerRowState();
}

class _DatePickerRowState extends State<_DatePickerRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.label, style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                Text(dateFormat.format(widget.date), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: _expanded
              ? SizedBox(
                  height: 180,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: widget.date,
                    minimumDate: widget.minimumDate,
                    maximumDate: widget.maximumDate,
                    onDateTimeChanged: widget.onChanged,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
