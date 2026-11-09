import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/enums/shipment_status.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../shipments/providers/shipment_providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final statusCounts = ref.watch(shipmentStatusCountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.analytics)),
      body: stats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(message: error.toString()),
        data: (value) => statusCounts.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorState(message: error.toString()),
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
