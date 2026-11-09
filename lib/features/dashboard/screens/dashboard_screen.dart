import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../domain/entities/shipment.dart';
import '../../../shared/widgets/skeletons.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/providers/auth_notifier.dart';
import '../../shipments/providers/shipment_notifier.dart';
import '../../shipments/providers/shipment_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final stats = ref.watch(dashboardStatsProvider);
    final recent = ref.watch(recentShipmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.dashboard),
        actions: [
          IconButton(
            tooltip: AppStrings.postLoad,
            onPressed: () => context.go(AppRoutes.postLoad),
            icon: const Icon(Icons.add_box_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(shipmentNotifierProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.screenHorizontal),
          children: [
            Text(
              _greeting(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              user?.displayName ?? 'Shipper',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSizes.lg),
            stats.when(
              loading: () => const _StatsLoading(),
              error: (error, _) => ErrorState(
                message: error.toString(),
                onRetry: () =>
                    ref.read(shipmentNotifierProvider.notifier).refresh(),
              ),
              data: (value) => Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: AppStrings.activeShipments,
                      value: value.active,
                      icon: Icons.local_shipping_outlined,
                      color: AppColors.statusInTransit,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: _StatCard(
                      label: AppStrings.awaitingBids,
                      value: value.awaitingBids,
                      icon: Icons.gavel_outlined,
                      color: AppColors.statusAwaitingBids,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: _StatCard(
                      label: AppStrings.completedShipments,
                      value: value.completed,
                      icon: Icons.check_circle_outline,
                      color: AppColors.statusDelivered,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.recentShipments,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                TextButton(
                  onPressed: () => context.go(AppRoutes.shipments),
                  child: const Text(AppStrings.seeAll),
                ),
              ],
            ),
            recent.when(
              loading: () => const Column(
                children: [
                  ShimmerBox(
                    width: double.infinity,
                    height: 64,
                    radius: AppSizes.radiusMd,
                  ),
                  SizedBox(height: AppSizes.sm),
                  ShimmerBox(
                    width: double.infinity,
                    height: 64,
                    radius: AppSizes.radiusMd,
                  ),
                ],
              ),
              error: (error, _) => ErrorState(message: error.toString()),
              data: (shipments) => shipments.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSizes.lg),
                      child: EmptyState(
                        title: AppStrings.noShipmentsFound,
                        subtitle: AppStrings.noShipmentsSubtitle,
                      ),
                    )
                  : Column(
                      children: shipments
                          .map((shipment) => _RecentTile(shipment: shipment))
                          .toList(),
                    ),
            ),
            const SizedBox(height: AppSizes.lg),
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.postLoad),
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.postLoad),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppStrings.goodMorning;
    if (hour < 17) return AppStrings.goodAfternoon;
    return AppStrings.goodEvening;
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: AppSizes.iconMd),
          const SizedBox(height: AppSizes.sm),
          Text(
            '$value',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatsLoading extends StatelessWidget {
  const _StatsLoading();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List<Widget>.generate(3, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 2 ? 0 : AppSizes.sm),
            child: const ShimmerBox(
              height: 108,
              radius: AppSizes.radiusMd,
            ),
          ),
        );
      }),
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.shipment});

  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          onTap: () => context.go(AppRoutes.shipmentDetail(shipment.id)),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Row(
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  color: AppColors.primary,
                  size: AppSizes.iconMd,
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shipment.reference,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSizes.xs),
                      Text(
                        shipment.routeLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                StatusBadge(status: shipment.status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
