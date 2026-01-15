import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:urban_cafe/presentation/providers/admin_provider.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final priceFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final provider = context.watch<AdminProvider>();
    final analytics = provider.analytics;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: Builder(
        builder: (context) {
          if (provider.loading || analytics == null) {
            return Skeletonizer(
              enabled: true,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryCards(cs, priceFormat, 0, 0),
                  const SizedBox(height: 24),
                  const Card(child: SizedBox(height: 300)),
                  const SizedBox(height: 24),
                  const Card(child: SizedBox(height: 300)),
                ],
              ),
            );
          }

          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          final totalSales = (analytics['total_sales_today'] as num?)?.toDouble() ?? 0.0;
          final totalOrders = (analytics['total_orders_today'] as num?)?.toInt() ?? 0;
          final topItems = (analytics['top_items'] as List<dynamic>? ?? []);
          final hourlySales = (analytics['hourly_sales'] as List<dynamic>? ?? []);

          return RefreshIndicator(
            onRefresh: () async => await provider.loadAnalytics(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Summary Cards
                _buildSummaryCards(cs, priceFormat, totalSales, totalOrders),
                const SizedBox(height: 24),

                // 2. Top Selling Items (Bar Chart)
                Text('Top Selling Items (30 Days)', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Container(
                  height: 300,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
                  child: topItems.isEmpty
                      ? const Center(child: Text("No sales data yet"))
                      : BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: (topItems.first['total_sold'] as num).toDouble() * 1.2,
                            barTouchData: const BarTouchData(enabled: true),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index >= 0 && index < topItems.length) {
                                      // Truncate long names
                                      String name = topItems[index]['name'];
                                      if (name.length > 10) name = '${name.substring(0, 8)}..';
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(name, style: const TextStyle(fontSize: 10)),
                                      );
                                    }
                                    return const Text('');
                                  },
                                  reservedSize: 40,
                                ),
                              ),
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: const FlGridData(show: false),
                            barGroups: topItems.asMap().entries.map((entry) {
                              return BarChartGroupData(
                                x: entry.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: (entry.value['total_sold'] as num).toDouble(),
                                    color: cs.primary,
                                    width: 20,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                ),

                const SizedBox(height: 24),

                // 3. Peak Hours (Line Chart)
                Text('Peak Hours (Today)', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Container(
                  height: 300,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
                  child: hourlySales.isEmpty
                      ? const Center(child: Text("No orders today"))
                      : LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 1,
                              getDrawingHorizontalLine: (value) => FlLine(color: cs.outlineVariant.withValues(alpha: 0.5), strokeWidth: 1),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  interval: 3, // Show every 3 hours
                                  getTitlesWidget: (value, meta) {
                                    return Text('${value.toInt()}:00', style: const TextStyle(fontSize: 10));
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  reservedSize: 30,
                                  getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 10)),
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            minX: 0,
                            maxX: 23,
                            minY: 0,
                            lineBarsData: [
                              LineChartBarData(
                                spots: hourlySales.map((e) {
                                  return FlSpot((e['hour'] as num).toDouble(), (e['count'] as num).toDouble());
                                }).toList(),
                                isCurved: true,
                                color: cs.secondary,
                                barWidth: 4,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(show: true, color: cs.secondary.withValues(alpha: 0.2)),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(ColorScheme cs, NumberFormat priceFormat, double sales, int orders) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Today\'s Sales',
            value: priceFormat.format(sales),
            icon: Icons.attach_money,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            title: 'Orders Today',
            value: orders.toString(),
            icon: Icons.receipt_long,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
