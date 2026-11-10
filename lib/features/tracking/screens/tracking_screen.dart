import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../domain/entities/shipment.dart';
import '../../../shared/widgets/status_badge.dart';

/// Live-tracking screen (Tier 2) — map placeholder, ETA, carrier info.
class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({super.key, required this.shipment});

  final Shipment shipment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Column(
        children: [
          // ── Map placeholder ──
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  color: AppColors.surfaceVariant,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 48,
                          color: AppColors.textTertiary,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Live map coming soon',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: AppTypography.caption,
                            color: AppColors.textTertiary,
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
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusPill),
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
                      _CircleButton(
                        icon: Icons.my_location,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                // ETA overlay
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
                          'Estimated arrival',
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '2h 30m',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '42 km remaining',
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: AppColors.textSecondary,
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
                  // Route info
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

                  // Carrier info
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
                    vehicle: shipment.vehicleType,
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Cargo info
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
                          '${shipment.weight} ${shipment.weightUnit}',
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Contact carrier button
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Carrier contact not available in demo'),
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
      ),
    );
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
          // Dots and line
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
                vehicle.replaceAll('_', ' ').toUpperCase(),
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.statusDeliveredBg,
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified, size: 14, color: AppColors.success),
              const SizedBox(width: 4),
              Text(
                'Verified',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
