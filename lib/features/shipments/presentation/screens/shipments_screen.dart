import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lodbod/core/constants/app_strings.dart';
import 'package:lodbod/shared/extensions/date_ext.dart';
import 'package:lodbod/shared/extensions/num_ext.dart';
import 'package:lodbod/core/routing/app_router.dart';
import 'package:lodbod/core/theme/tokens.dart';
import 'package:lodbod/features/shipments/domain/entities/shipment.dart';
import 'package:lodbod/features/shipments/domain/enums/cargo_category.dart';
import 'package:lodbod/features/shipments/domain/enums/shipment_status.dart';
import 'package:lodbod/features/shipments/domain/enums/vehicle_type.dart';
import 'package:lodbod/shared/widgets/skeletons.dart';
import 'package:lodbod/shared/widgets/state_views.dart';
import 'package:lodbod/features/shipments/presentation/widgets/status_badge.dart';
import 'package:lodbod/features/shipments/presentation/providers/shipment_notifier.dart';
import 'package:lodbod/features/shipments/presentation/providers/shipment_providers.dart';

class ShipmentsScreen extends ConsumerStatefulWidget {
  const ShipmentsScreen({super.key, this.initialFilter});

  /// Route deep-link filter: `active` or a [ShipmentStatus] wire value.
  final String? initialFilter;

  @override
  ConsumerState<ShipmentsScreen> createState() => _ShipmentsScreenState();
}

class _ShipmentsScreenState extends ConsumerState<ShipmentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  ShipmentStatus? _status;
  bool _activeOnly = false;

  /// Debounces filtering so typing a word rebuilds the list once instead of
  /// once per keystroke.
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    final filter = widget.initialFilter;
    if (filter == null || filter.isEmpty) return;
    if (filter == 'active') {
      _activeOnly = true;
    } else {
      _status = ShipmentStatus.fromWire(filter);
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filtering runs inside the provider layer so it stays unit-testable
    // and the screen only rebuilds what it watches.
    final filter = ShipmentFilter(
      query: _query,
      status: _status,
      activeOnly: _activeOnly,
    );
    final shipments = ref.watch(filteredShipmentsProvider(filter));

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
                      onChanged: _onSearchChanged,
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
                _statusChip(AppStrings.activeShipments, null, activeOnly: true),
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
                if (list.isEmpty) {
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
                    itemCount: list.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _ShipmentTile(shipment: list[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(
    String label,
    ShipmentStatus? status, {
    bool activeOnly = false,
  }) {
    final selected =
        activeOnly ? _activeOnly : !_activeOnly && _status == status;
    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (chosen) {
          if (!chosen) return;
          setState(() {
            _activeOnly = activeOnly;
            _status = status;
          });
        },
      ),
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted || value == _query) return;
      setState(() => _query = value);
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
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
                  _filterChip(ctx, AppStrings.activeShipments, null,
                      activeOnly: true),
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

  Widget _filterChip(
    BuildContext ctx,
    String label,
    ShipmentStatus? status, {
    bool activeOnly = false,
  }) {
    final selected =
        activeOnly ? _activeOnly : !_activeOnly && _status == status;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (chosen) {
        if (chosen) {
          setState(() {
            _activeOnly = activeOnly;
            _status = status;
          });
          Navigator.of(ctx).pop();
        }
      },
    );
  }
}

// ─── Shipment tile ───────────────────────────────────────────────────────────

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
              // Row 1: Reference + Status badge + fare
              Row(
                children: [
                  Text(
                    shipment.reference,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (shipment.hasExpectedFare) ...<Widget>[
                    Text(
                      shipment.expectedFare.toNPR(),
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                  ],
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
              const SizedBox(height: AppSizes.xs),

              // Row 4: Vehicle and pickup schedule
              Row(
                children: [
                  const Icon(
                    Icons.local_shipping_outlined,
                    size: AppSizes.iconSm,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSizes.xs),
                  Flexible(
                    child: Text(
                      VehicleType.fromWire(shipment.vehicleType).label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: AppSizes.iconSm,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSizes.xs),
                  Text(
                    '${CargoCategory.fromWire(shipment.cargoCategory).label} · '
                    'pickup ${shipment.pickupAt.formatShort()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
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
