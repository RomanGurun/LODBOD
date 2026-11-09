import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/extensions/num_ext.dart';
import '../../../domain/entities/shipment.dart';
import '../../../domain/enums/shipment_status.dart';
import '../../../shared/widgets/skeletons.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/status_badge.dart';
import '../providers/shipment_notifier.dart';
import '../providers/shipment_providers.dart';

class ShipmentsScreen extends ConsumerStatefulWidget {
  const ShipmentsScreen({super.key});

  @override
  ConsumerState<ShipmentsScreen> createState() => _ShipmentsScreenState();
}

class _ShipmentsScreenState extends ConsumerState<ShipmentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  ShipmentStatus? _status;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shipments = ref.watch(shipmentNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.shipments)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.screenHorizontal,
              AppSizes.sm,
              AppSizes.screenHorizontal,
              0,
            ),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: AppStrings.searchShipments,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Clear search',
                        onPressed: _clearSearch,
                      ),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          SizedBox(
            height: AppSizes.minTouchTarget,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenHorizontal,
              ),
              children: <Widget>[
                _statusChip(AppStrings.allStatus, null),
                for (final status in ShipmentStatus.values)
                  _statusChip(status.label, status),
              ],
            ),
          ),
          Expanded(
            child: shipments.when(
              loading: () => const ShipmentListSkeleton(),
              error: (error, _) => ErrorState(
                message: error.toString(),
                onRetry: () =>
                    ref.read(shipmentNotifierProvider.notifier).refresh(),
              ),
              data: (list) {
                final filtered =
                    ShipmentFilter(query: _query, status: _status).apply(list);
                if (filtered.isEmpty) {
                  return const EmptyState(
                    title: AppStrings.noShipmentsFound,
                    subtitle: AppStrings.noShipmentsSubtitle,
                    icon: Icons.local_shipping_outlined,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(shipmentNotifierProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSizes.screenHorizontal),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSizes.sm),
                    itemBuilder: (context, index) =>
                        _ShipmentTile(shipment: filtered[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, ShipmentStatus? status) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: _status == status,
        onSelected: (selected) {
          if (selected) setState(() => _status = status);
        },
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }
}

class _ShipmentTile extends StatelessWidget {
  const _ShipmentTile({required this.shipment});

  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        onTap: () => context.go(AppRoutes.shipmentDetail(shipment.id)),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      shipment.reference,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  StatusBadge(status: shipment.status),
                ],
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                shipment.routeLabel,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSizes.xs),
              Row(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: AppSizes.iconSm,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSizes.xs),
                  Text(
                    '${shipment.cargoDescription} \u00b7 '
                    '${shipment.weight.toWeight(shipment.weightUnit)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const Spacer(),
                  if (shipment.hasBids)
                    Text(
                      '${shipment.bidCount} bid${shipment.bidCount == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
