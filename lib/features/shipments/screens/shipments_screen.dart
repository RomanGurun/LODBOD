import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/extensions/num_ext.dart';
import '../../../core/theme/tokens.dart';
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
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      style: const TextStyle(fontSize: AppTypography.body),
                      decoration: InputDecoration(
                        hintText: AppStrings.searchShipments,
                        prefixIcon: const Icon(Icons.search, size: 20),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                tooltip: 'Clear search',
                                onPressed: _clearSearch,
                              ),
                      ),
                      onChanged: (value) => setState(() => _query = value),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: IconButton(
                    onPressed: () => _showFilterSheet(context),
                    icon: const Icon(
                      Icons.tune,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
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
                        const SizedBox(height: 12),
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

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.screenHorizontal),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter shipments',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _filterChip(ctx, AppStrings.allStatus, null),
                  for (final s in ShipmentStatus.values)
                    _filterChip(ctx, s.label, s),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(BuildContext ctx, String label, ShipmentStatus? status) {
    return ChoiceChip(
      label: Text(label),
      selected: _status == status,
      onSelected: (selected) {
        if (selected) {
          setState(() => _status = status);
          Navigator.of(ctx).pop();
        }
      },
    );
  }
}

// ─── Reworked Shipment Tile ──────────────────────────────────────────────────

class _ShipmentTile extends StatelessWidget {
  const _ShipmentTile({required this.shipment});

  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        onTap: () => context.go(AppRoutes.shipmentDetail(shipment.id)),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Reference + Status badge
              Row(
                children: [
                  Text(
                    shipment.reference,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  StatusBadge(status: shipment.status),
                ],
              ),
              const SizedBox(height: AppSizes.sm),

              // Row 2: Bold route
              Text(
                shipment.routeLabel,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSizes.xs),

              // Row 3: Cargo info
              Row(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: AppSizes.iconSm,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSizes.xs),
                  Flexible(
                    child: Text(
                      '${shipment.cargoDescription} · '
                      '${shipment.weight.toWeight(shipment.weightUnit)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (shipment.hasBids)
                    Text(
                      '${shipment.bidCount} bid${shipment.bidCount == 1 ? '' : 's'}',
                      style: textTheme.labelSmall?.copyWith(
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
