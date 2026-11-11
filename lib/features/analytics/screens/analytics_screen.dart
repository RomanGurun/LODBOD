import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/enums/shipment_status.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../shipments/providers/shipment_notifier.dart';
import '../../shipments/providers/shipment_providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final statusCounts = ref.watch(shipmentStatusCountsProvider);
    final monthly = ref.watch(monthlyShipmentCountsProvider(6));

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.analytics)),
      body: stats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.read(shipmentNotifierProvider.notifier).refresh(),
        ),
        data: (value) => statusCounts.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorState(
            message: error.toString(),
            onRetry: () => ref.read(shipmentNotifierProvider.notifier).refresh(),
          ),
          data: (counts) => ListView(
            padding: const EdgeInsets.all(AppSizes.screenHorizontal),
            children: [
              Text(
                'Shipment overview',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSizes.md),
              _AnalyticsRow(
                label: 'Total shipments',
                value: value.total,
                color: AppColors.primary,
              ),
              _AnalyticsRow(
                label: AppStrings.activeShipments,
                value: value.active,
                color: AppColors.statusInTransit,
              ),
              _AnalyticsRow(
                label: AppStrings.awaitingBids,
                value: value.awaitingBids,
                color: AppColors.statusAwaitingBids,
              ),
              _AnalyticsRow(
                label: AppStrings.completedShipments,
                value: value.completed,
                color: AppColors.statusDelivered,
              ),
              const SizedBox(height: AppSizes.lg),
              Text(
                'Loads created per month',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSizes.md),
              Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.md,
                  AppSizes.md,
                  AppSizes.md,
                  AppSizes.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: monthly.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, _) => ErrorState(message: error.toString()),
                  data: (series) => _MonthlyBarChart(series: series),
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              Text(
                'Status breakdown',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSizes.md),
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Column(
                  children: [
                    for (final status in ShipmentStatus.values)
                      if ((counts[status] ?? 0) > 0)
                        _StatusBar(
                          status: status,
                          count: counts[status] ?? 0,
                          total: value.total,
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shipments created per month, computed from real shipment `createdAt`
/// values over the last six months.
class _MonthlyBarChart extends StatelessWidget {
  const _MonthlyBarChart({required this.series});

  /// Oldest-first list of (month, count) pairs.
  final List<(DateTime, int)> series;

  static const List<String> _monthLabels = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final maxY = series.fold<int>(0, (max, e) => e.$2 > max ? e.$2 : max);

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: (maxY + 1).toDouble(),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                  BarTooltipItem(
                    '${rod.toY.toInt()}',
                    textTheme.labelMedium ?? const TextStyle(),
                  ),
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= series.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _monthLabels[series[index].$1.month - 1],
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: <BarChartGroupData>[
            for (var i = 0; i < series.length; i++)
              BarChartGroupData(
                x: i,
                barRods: <BarChartRodData>[
                  BarChartRodData(
                    toY: series[i].$2.toDouble(),
                    width: 18,
                    color: series[i].$2 == 0
                        ? AppColors.surfaceVariant
                        : AppColors.primary,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsRow extends StatelessWidget {
  const _AnalyticsRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: AppSizes.sm,
            height: AppSizes.sm,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            '$value',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.status,
    required this.count,
    required this.total,
  });

  final ShipmentStatus status;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    final fraction = total == 0 ? 0.0 : count / total;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  status.label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                '$count',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: AppSizes.xs),
              Text(
                '(${(fraction * 100).round()}%)',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: AppColors.surfaceVariant,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
