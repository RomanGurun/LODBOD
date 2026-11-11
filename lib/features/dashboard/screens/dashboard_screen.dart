import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../domain/rules/shipment_limit_rule.dart';
import '../../../shared/widgets/shipment_card.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/providers/auth_notifier.dart';
import '../../shipments/providers/shipment_notifier.dart';
import '../../shipments/providers/shipment_providers.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/dashboard_action_card.dart';
import '../widgets/dashboard_hero_card.dart';
import '../widgets/dashboard_next_pickup_card.dart';
import '../widgets/dashboard_skeleton.dart';
import '../widgets/dashboard_stat_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: stats.when(
          loading: () => const DashboardSkeleton(),
          error: (error, _) => ErrorState(
            message: error.toString(),
            onRetry: () =>
                ref.read(shipmentNotifierProvider.notifier).refresh(),
          ),
          data: (value) => _DashboardContent(stats: value),
        ),
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final recent = ref.watch(recentShipmentsProvider).valueOrNull ?? const [];
    final action = ref.watch(actionRequiredShipmentProvider).valueOrNull;
    final nextPickup = ref.watch(nextPickupShipmentProvider).valueOrNull;
    final name = user?.displayName ?? '';

    if (stats.total == 0) {
      return const EmptyState(
        title: AppStrings.noShipmentsFound,
        subtitle: AppStrings.noShipmentsSubtitle,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(shipmentNotifierProvider.notifier).refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSizes.screenHorizontal,
          5,
          AppSizes.screenHorizontal,
          30,
        ),
        children: <Widget>[
          _GreetingRow(
            name: name,
            onBellTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text(AppStrings.noNotifications),
              ),
            ),
          ),
          const SizedBox(height: 30),
          DashboardHeroCard(
            used: stats.active,
            limit: ShipmentLimitRule.maxActiveShipments,
            onPostLoad: () => context.go(AppRoutes.postLoad),
          ),
          const SizedBox(height: 11),
          Row(
            children: <Widget>[
              Expanded(
                child: DashboardStatCard(
                  value: stats.active,
                  label: AppStrings.activeShipments,
                  icon: Icons.local_shipping,
                  iconColor: AppColors.primary,
                  iconBackground: AppColors.statusActiveBg,
                  onTap: () =>
                      context.go(AppRoutes.shipmentsFiltered('active')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DashboardStatCard(
                  value: stats.awaitingBids,
                  label: AppStrings.pendingShipments,
                  icon: Icons.hourglass_empty,
                  iconColor: AppColors.statusOpen,
                  iconBackground: AppColors.statusOpenBg,
                  onTap: () => context
                      .go(AppRoutes.shipmentsFiltered('awaiting_bids')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DashboardStatCard(
                  value: stats.delivered,
                  label: AppStrings.deliveredShipments,
                  icon: Icons.check_circle,
                  iconColor: AppColors.statusDelivered,
                  iconBackground: AppColors.statusDeliveredBg,
                  onTap: () =>
                      context.go(AppRoutes.shipmentsFiltered('delivered')),
                ),
              ),
            ],
          ),
          if (action != null) ...<Widget>[
            const SizedBox(height: 19),
            Text(
              AppStrings.needsYourAction,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 14),
            DashboardActionCard(
              title:
                  '${action.bidCount} ${AppStrings.newBidsOn} ${action.reference}',
              subtitle: '${action.routeLabel} • ${AppStrings.biddingOpen}',
              onTap: () => context.go(AppRoutes.shipmentDetail(action.id)),
            ),
          ],
          const SizedBox(height: 17),
          Row(
            children: <Widget>[
              Text(
                AppStrings.recentShipments,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontSize: 15),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go(AppRoutes.shipments),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(64, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  AppStrings.seeAll,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          for (final shipment in recent) ...<Widget>[
            ShipmentCard(
              shipment: shipment,
              onTap: () => context.go(AppRoutes.shipmentDetail(shipment.id)),
            ),
            const SizedBox(height: 12),
          ],
          if (nextPickup != null) ...<Widget>[
            const SizedBox(height: 9),
            DashboardNextPickupCard(
              shipment: nextPickup,
              onDetails: () =>
                  context.go(AppRoutes.shipmentDetail(nextPickup.id)),
            ),
          ],
        ],
      ),
    );
  }
}

class _GreetingRow extends StatelessWidget {
  const _GreetingRow({required this.name, required this.onBellTap});

  final String name;
  final VoidCallback onBellTap;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppStrings.goodMorning;
    if (hour < 17) return AppStrings.goodAfternoon;
    return AppStrings.goodEvening;
  }

  String get _initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            _initials,
            style: textTheme.titleSmall?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textOnPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _greeting,
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        _BellButton(onTap: onBellTap),
      ],
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(
        side: BorderSide(color: AppColors.border, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Stack(
            children: <Widget>[
              Center(
                child: Icon(
                  Icons.notifications_none,
                  size: 19,
                  color: AppColors.textPrimary,
                ),
              ),
              Positioned(
                top: 17,
                right: 3,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
