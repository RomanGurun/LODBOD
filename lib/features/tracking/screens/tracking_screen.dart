import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lodbod/core/constants/app_colors.dart';
import 'package:lodbod/core/constants/app_sizes.dart';
import 'package:lodbod/core/extensions/date_ext.dart';
import 'package:lodbod/core/extensions/num_ext.dart';
import 'package:lodbod/domain/entities/shipment.dart';
import 'package:lodbod/domain/enums/shipment_status.dart';
import 'package:lodbod/domain/enums/vehicle_type.dart';
import 'package:lodbod/shared/widgets/skeletons.dart';
import 'package:lodbod/shared/widgets/state_views.dart';
import 'package:lodbod/shared/widgets/status_badge.dart';
import 'package:lodbod/shared/widgets/status_timeline.dart';
import 'package:lodbod/features/shipments/providers/shipment_notifier.dart';
import 'package:lodbod/features/shipments/providers/shipment_providers.dart';

/// Shipment tracking screen.
///
/// ⚠️ All tracking information on this screen is **simulated** from the
/// shipment's current status — there is no live GPS feed in this prototype.
/// The ETA uses the accepted carrier bid's delivery estimate when available.
class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shipmentAsync = ref.watch(shipmentByIdProvider(shipmentId));

    return Scaffold(
      body: shipmentAsync.when(
        loading: () => const ShipmentDetailSkeleton(),
        error: (error, _) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.read(shipmentNotifierProvider.notifier).refresh(),
        ),
        data: (shipment) {
          if (shipment == null) {
            return const EmptyState(
              title: 'Shipment not found',
              subtitle: 'It may have been removed.',
              icon: Icons.search_off,
            );
          }
          return _TrackingContent(shipment: shipment);
        },
      ),
    );
  }
}

class _TrackingContent extends StatelessWidget {
  const _TrackingContent({required this.shipment});

  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final eta = _etaLabel;

    return Column(
      children: [
        // ── Simulated route overview ──
        Expanded(
          flex: 4,
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                color: AppColors.surfaceVariant,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.route_outlined,
                        size: 48,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Simulated tracking',
                        style: textTheme.titleSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Live GPS tracking is not part of this prototype. '
                          'This preview is derived from the shipment status.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Top bar
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    _CircleButton(
                      icon: Icons.arrow_back,
                      onTap: () => context.pop(),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            shipment.reference,
                            style: textTheme.titleSmall?.copyWith(
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(status: shipment.status),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 38),
                  ],
                ),
              ),
              // Simulated ETA overlay
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimated arrival (simulated)',
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        eta,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Bottom details panel ──
        Expanded(
          flex: 5,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppSizes.radiusXl),
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              children: [
                Text(
                  'Route',
                  style: textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.0,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 12),
                _RouteTimeline(
                  pickup: shipment.pickupCity,
                  pickupAddress: shipment.pickupAddress,
                  destination: shipment.destinationCity,
                  destinationAddress: shipment.destinationAddress,
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                Text(
                  'Status',
                  style: textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.0,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 12),
                StatusTimeline(shipment: shipment),
                const SizedBox(height: 16),

                Text(
                  'Carrier',
                  style: textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.0,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 12),
                _CarrierCard(
                  name: shipment.assignedCarrier ?? 'Unassigned',
                  vehicle: VehicleType.fromWire(shipment.vehicleType).label,
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                Text(
                  'Cargo',
                  style: textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.0,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${shipment.cargoDescription} · '
                        '${shipment.weight.toWeight(shipment.weightUnit)}',
                        style: textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Carrier contact is not available in this prototype',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.phone_outlined),
                  label: const Text('Contact carrier'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Simulated arrival estimate. Uses the accepted bid's carrier estimate
  /// when the shipment has one; otherwise the planned pickup window.
  String get _etaLabel {
    final accepted = shipment.acceptedBid;
    if (accepted != null) {
      return accepted.estimatedDeliveryAt.formatDisplay();
    }
    if (shipment.status == ShipmentStatus.delivered) {
      return shipment.updatedAt.formatDisplay();
    }
    return shipment.pickupAt.formatShort();
  }
}

// ─── Helper widgets ──────────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(
        side: BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _RouteTimeline extends StatelessWidget {
  const _RouteTimeline({
    required this.pickup,
    required this.pickupAddress,
    required this.destination,
    required this.destinationAddress,
  });

  final String pickup;
  final String pickupAddress;
  final String destination;
  final String destinationAddress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Container(
                  width: 1.5,
                  color: AppColors.border,
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.statusDelivered,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pickup,
                  style: textTheme.titleSmall?.copyWith(fontSize: 13),
                ),
                Text(
                  pickupAddress,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  destination,
                  style: textTheme.titleSmall?.copyWith(fontSize: 13),
                ),
                Text(
                  destinationAddress,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CarrierCard extends StatelessWidget {
  const _CarrierCard({required this.name, required this.vehicle});

  final String name;
  final String vehicle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.surfaceVariant,
          child: const Icon(
            Icons.person,
            size: 22,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: textTheme.titleSmall?.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                vehicle,
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
